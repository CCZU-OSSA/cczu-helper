package io.github.cczuossa.cczu_helper.vpn

import io.github.cczuossa.cczu_helper.utils.Utils.Companion.async
import java.io.ByteArrayOutputStream
import java.io.FileDescriptor
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.LinkedList

class EnlineVpnForwarder(
    val fileDescriptor: FileDescriptor,
    val forwarder: (proxyOut: ByteArray) -> Unit// 从代理出去的
) {

    private val vpnIn = FileInputStream(fileDescriptor)
    private val vpnOut = FileOutputStream(fileDescriptor)
    private val queue = LinkedList<ByteArray>()

    fun write(data: ByteArray) {

        queue.offer(data)
    }

    fun writer() {
        async {
            // 从代理到vpn
            while (fileDescriptor.valid()) {
                runCatching {
                    val data = queue.poll()
                    if (data != null) {
                        vpnOut.write(data)
                    }
                }
            }
        }
    }

    fun reader() {
        async {
            // 从vpn到代理
            var temp = ByteArray(1024)
            var read = 0
            while (fileDescriptor.valid()) {
                runCatching {
                    read = vpnIn.read(temp)
                    if (read > 0) {
                        forwarder.invoke(ByteArrayOutputStream()
                            .apply {
                                this.write(temp, 0, read)
                            }
                            .toByteArray())
                    }
                }
            }
        }
    }


}