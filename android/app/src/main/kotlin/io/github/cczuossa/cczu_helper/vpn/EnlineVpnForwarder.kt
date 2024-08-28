package io.github.cczuossa.cczu_helper.vpn

import io.github.cczuossa.cczu_helper.utils.Utils.Companion.async
import li.mo.testvpn.EnlinkDataInputStream
import li.mo.testvpn.EnlinkDataOutputStream
import java.io.FileDescriptor
import java.io.FileInputStream
import java.io.FileOutputStream

class EnlineVpnForwarder(
    val fileDescriptor: FileDescriptor,
    val proxyIn: EnlinkDataInputStream,
    val proxyOut: EnlinkDataOutputStream
) {

    private val vpnIn = FileInputStream(fileDescriptor)
    private val vpnOut = FileOutputStream(fileDescriptor)

    fun start() {
        reader()
        writer()
    }

    private fun writer() {
        async {
            // 从代理到vpn
            while (fileDescriptor.valid()) {
                try {
                    val data = proxyIn.readData()
                    if (data.isNotEmpty()) {
                        vpnOut.write(data)
                    }
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
            while (fileDescriptor.valid()) {
                try {
                    read = vpnIn.read(temp)
                    if (read > 0) {
                        proxyOut.writeData(temp, read)
                    }
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


}