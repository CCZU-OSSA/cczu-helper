package io.github.cczuossa.cczu_helper.vpn

import android.util.Log
import io.github.cczuossa.cczu_helper.utils.Utils.Companion.async
import io.github.cczuossa.cczu_helper.vpn.protocol.packet.Packet
import li.mo.testvpn.EnlinkDataInputStream
import li.mo.testvpn.EnlinkDataOutputStream
import java.io.FileDescriptor
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer

class EnlinkForwarder(
    fileDescriptor: FileDescriptor,
    val proxyIn: EnlinkDataInputStream,// vpn入口
    val proxyOut: EnlinkDataOutputStream// vpn出口
) {

    private var vpnOut = FileOutputStream(fileDescriptor)// tun出口
    private var vpnIn = FileInputStream(fileDescriptor)// tun入口
    private var desc = fileDescriptor// tun接口
    private var writer = false// proxy => tun
    private var reader = false// tun => proxy
    var status = false// 全局状态

    fun start() {
        status = true
        reader()
        writer()
    }

    private fun writer() {
        if (writer) return
        async {
            // 从代理到vpn
            runCatching {
                while (status && desc.valid()) {
                    runCatching {
                        val data = proxyIn.readData()
                        if (data.isNotEmpty()) {
                            val packet = Packet(ByteBuffer.wrap(data))

                            //println("read packet: $packet")
                            Log.i(
                                "cczu-helper",
                                "Forwarder:  proxy => tun@$packet"
                            )
                            vpnOut.write(data, 0, data.size)
                        }
                    }.onFailure {
                        EnlinkVPN.socket.close()
                        //it.printStackTrace()
                    }
                }
                writer = false
            }.onFailure {
                it.printStackTrace()
                writer = false
            }

        }
        writer = true
    }



    private fun reader() {
        if (reader) return
        async {
            runCatching {
                // 从vpn到代理
                // 一次读取2048字节
                var temp = ByteArray(2048)
                var read = 0
                while (status && desc.valid()) {
                    runCatching {
                        read = vpnIn.read(temp)
                        if (read > 0) {// 有读取到有效字节
                            val packet = Packet(ByteBuffer.wrap(temp))

                            if (EnlinkVPN.whitelist.contains(
                                    packet.ip4Header.destinationAddress.toString().replace("/", "")
                                )
                            ) {
                                Log.i(
                                    "cczu-helper",
                                    "Forwarder:  tun => proxy@$packet"
                                )
                                // 转发到vpn
                                proxyOut.writeData(temp, read)
                            } else {
                                Log.i(
                                    "cczu-helper",
                                    "Forwarder:  tun => proxy@ filter ${packet.ip4Header.destinationAddress}"
                                )
                                //TODO: 丢弃
                            }
                            //println("read packet: $packet")
                        }
                    }.onFailure {
                        EnlinkVPN.socket.close()
                        //it.printStackTrace()
                    }
                }
            }.onFailure {
                it.printStackTrace()
                reader = false
            }
        }
        reader = true
    }

    fun stop() {
        status = false
    }

    fun update(fileDescriptor: FileDescriptor) {
        desc = fileDescriptor
        vpnIn = FileInputStream(fileDescriptor)
        vpnOut = FileOutputStream(fileDescriptor)
    }


}