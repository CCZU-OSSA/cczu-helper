package io.github.cczuossa.cczu_helper.vpn

import io.github.cczuossa.cczu_helper.utils.Utils.Companion.async
import io.github.cczuossa.cczu_helper.vpn.protocol.packet.Packet
import li.mo.testvpn.EnlinkDataInputStream
import li.mo.testvpn.EnlinkDataOutputStream
import java.io.FileDescriptor
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer

class EnlineVpnForwarder(
    val fileDescriptor: FileDescriptor,
    val proxyIn: EnlinkDataInputStream,
    val proxyOut: EnlinkDataOutputStream
) {

    private val vpnIn = FileInputStream(fileDescriptor)
    private val vpnOut = FileOutputStream(fileDescriptor)
    var status = true

    fun start() {
        status = true
        reader()
        writer()
    }

    private fun writer() {
        async {
            // 从代理到vpn
            while (fileDescriptor.valid() && status) {
                try {
                    val data = proxyIn.readData()
                    if (data.isNotEmpty()) {
                        val packet = Packet(ByteBuffer.wrap(data))
                        println("read packet: $packet")
                        vpnOut.write(data)
                    }
                    Thread.sleep(1)
                } catch (e: Throwable) {
                    e.printStackTrace()
                    proxyIn.close()
                    proxyOut.close()
                    vpnOut.close()
                    vpnIn.close()
                    break
                }
            }
        }
    }

    private fun reader() {
        async {
            // 从vpn到代理
            var temp = ByteArray(1024)
            var read = 0
            while (fileDescriptor.valid() && status) {
                try {
                    read = vpnIn.read(temp)
                    if (read > 0) {
                        val packet = Packet(ByteBuffer.wrap(temp))
                        println("write packet: $packet")
                        proxyOut.writeData(temp, read)
                    }
                    Thread.sleep(1)
                } catch (e: Throwable) {
                    e.printStackTrace()
                    proxyIn.close()
                    proxyOut.close()
                    vpnOut.close()
                    vpnIn.close()
                    break
                }
            }
        }
    }

    fun stop() {
        status = false
    }


}