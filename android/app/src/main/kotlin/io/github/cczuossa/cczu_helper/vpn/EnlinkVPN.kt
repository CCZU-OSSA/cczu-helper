package io.github.cczuossa.cczu_helper.vpn


import android.os.ParcelFileDescriptor
import io.github.cczuossa.cczu_helper.utils.Utils.Companion.async
import io.github.cczuossa.cczu_helper.vpn.trust.EasyTrustManager
import li.mo.testvpn.EnlinkDataInputStream
import li.mo.testvpn.EnlinkDataOutputStream
import java.net.InetSocketAddress
import java.net.Socket
import javax.net.ssl.SSLContext


class EnlinkVPN(
    val user: String,
    val token: String,
    val host: String = "zmvpn.cczu.edu.cn",
    val port: Int = 443,
    var callback: (status: Boolean, vpn: EnlinkVPN) -> Unit
) {

    private var fileDescriptor: ParcelFileDescriptor? = null
    private var forwarder: EnlineVpnForwarder? = null
    val socket: Socket
    var ip = "0.0.0.0"
    var mask = 32
    val dnsList = arrayListOf<String>()
    var gate = "0.0.0.0"
    var watchdog = false
    var totalTry = 20
    var tryReconnect = 0


    init {
        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(null, arrayOf(EasyTrustManager), null)
        this.socket = sslContext.socketFactory.createSocket()
        connect()
    }

    fun connect() {
        this.socket.connect(InetSocketAddress(host, port))
    }


    fun auth() {
        val out = EnlinkDataOutputStream(this.socket.getOutputStream())
        out.writeAuth(user, token)
        val ins = EnlinkDataInputStream(this.socket.getInputStream())
        if (ins.authStatus()) {
            this.ip = ins.virtualAddress()
            this.mask = ins.virtualMask()
            ins.others()
            ins.drop()
            if (ins.gate.size > 0)
                this.gate = ins.gate[0]
            this.dnsList.addAll(ins.dnsList)
            callback.invoke(true, this)
        } else callback.invoke(false, this)
    }

    private fun outputStream(): EnlinkDataOutputStream {
        return EnlinkDataOutputStream(this.socket.getOutputStream())
    }

    private fun inputStream(): EnlinkDataInputStream {
        return EnlinkDataInputStream(this.socket.getInputStream())
    }

    fun watchdog() {
        if (watchdog) return
        watchdog = true
        async {
            while (watchdog) {
                if (tryReconnect >= totalTry) break
                if (socket.isClosed) {
                    connect()
                    tryReconnect++
                    Thread.sleep(3000L)
                } else {
                    if (tryReconnect > 0) {
                        callback = { status, _ ->
                            if (status) {
                                tryReconnect = 0
                                forward()
                            }
                        }
                        auth()
                    }
                }
            }
            watchdog = false
        }
    }

    fun init(service: EnlinkVpnService, dns: String?, apps: String?) {
        this.fileDescriptor = service.setup(ip, mask, dnsList.apply {
            if (dns.isNullOrBlank()) {
                addAll(dns?.split(",")!!)
            }
        }, arrayListOf<String>().apply {
            if (apps.isNullOrBlank()) {
                addAll(apps?.split(",")!!)
            }
        })
        forward()
        watchdog()
    }

    private fun forward() {
        this.forwarder =
            EnlineVpnForwarder(fileDescriptor?.fileDescriptor!!, inputStream(), outputStream())
        this.forwarder?.start()
    }

}
