package io.github.cczuossa.cczu_helper.vpn

import android.util.Log
import io.github.cczuossa.cczu_helper.utils.Utils.Companion.async
import io.github.cczuossa.cczu_helper.vpn.data.EnlinkTunData

object EnlinkAdapter {

    private var forwarder: EnlinkForwarder? = null
    private var watchdog = false// 守护程序状态

    /**
     * 配置服务并开启转发
     */
    fun proxy(service: EnlinkVpnService, data: EnlinkTunData, vpn: EnlinkVPN): Boolean {
        val tun = service.setup(data.address, data.mask, data.dns, data.apps)
            ?: return false// 尝试配置tun,失败返回
        // 开始配置转发
        // 添加白名单
        data.routes.forEach {
            EnlinkVPN.whitelist.add(it.address)
        }

        // 保护socket
        service.protect(vpn.socket)
        forwarder =
            forwarder ?: EnlinkForwarder(tun.fileDescriptor, vpn.inputStream(), vpn.outputStream())
        // 更新转发配置
        forwarder?.update(tun.fileDescriptor)
        forwarder?.start()

        if (watchdog) return true
        watchdog = true
        // 启动线程
        async {
            watchdog = true
            while (watchdog) {
                runCatching {
                    if (vpn.socket.isClosed || !tun.fileDescriptor.valid()) {
                        Log.i(
                            "cczu-helper",
                            "WATCHDOG: !!!!!! The socket is closed or the service has been killed, try reconnect and auth."
                        )
                        vpn.connect()
                    }

                }.onFailure {
                    it.printStackTrace()
                }
                Thread.sleep(3000L)
            }
            watchdog = false
            vpn.socket.close()
        }
        return true
    }

    fun stop() {
        watchdog = false
        forwarder?.stop()
    }
}