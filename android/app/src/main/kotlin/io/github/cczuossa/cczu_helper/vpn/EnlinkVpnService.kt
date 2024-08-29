package io.github.cczuossa.cczu_helper.vpn

import android.content.Intent
import android.net.VpnService
import android.os.Binder
import android.os.IBinder
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationManagerCompat

class EnlinkVpnService : VpnService() {

    override fun onBind(intent: Intent?): IBinder {
        return super.onBind(intent) ?: EnlinkVpnServiceBinder(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 如果有通知权限就转向前台
        if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            // 转向前台

        }
        return START_STICKY
    }

    fun setup(
        virtualAddress: String,
        virtualMask: Int,
        dnsList: List<String>,
        allowedApplications: List<String>,
    ): ParcelFileDescriptor? {

        return Builder()
            .addRoute("0.0.0.0", 0)
            .addAddress(virtualAddress, virtualMask)
            .apply {
                dnsList.forEach { addDnsServer(it) }
                allowedApplications.forEach { addAllowedApplication(it) }
            }
            .establish()
    }


    open class EnlinkVpnServiceBinder(
        val service: EnlinkVpnService

    ) : Binder() {
        fun service(): EnlinkVpnService {
            return this.service
        }
    }
}