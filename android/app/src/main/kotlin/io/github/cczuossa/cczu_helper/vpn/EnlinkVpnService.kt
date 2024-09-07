package io.github.cczuossa.cczu_helper.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.os.ParcelFileDescriptor
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationManagerCompat
import io.github.cczuossa.cczu_helper.MainActivity
import io.github.cczuossa.cczu_helper.R

class EnlinkVpnService : VpnService() {

    private val intent: PendingIntent by lazy {
        PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT + PendingIntent.FLAG_MUTABLE
        )
    }
    private val remoteView: RemoteViews by lazy {
        RemoteViews(packageName, R.layout.helper_notification_vpn)
    }

    override fun onBind(intent: Intent?): IBinder {
        return EnlinkVpnServiceBinder(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 如果有通知权限就转向前台
        Log.i("cczu-helper", " Service start.")
        val notificationManager = NotificationManagerCompat.from(this)
        if (notificationManager.areNotificationsEnabled()) {
            Log.i("cczu-helper", "Build Foreground Service.")
            // 转向前台
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val notificationChannel = NotificationChannel(
                    "EnlinkVPN",
                    "校园网VPN服务",
                    NotificationManager.IMPORTANCE_DEFAULT
                )
                notificationManager.createNotificationChannel(notificationChannel)
                Notification.Builder(applicationContext, notificationChannel.id)
            } else {
                Notification.Builder(applicationContext)
            }

            val notification = builder
                .setContent(remoteView)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .setContentIntent(this.intent)
                .setWhen(System.currentTimeMillis())
                .build()
            Log.i("cczu-helper", "Start Foreground Service.")
            startForeground(0x34, notification)
        } else {
            Log.i("cczu-helper", "Service waiting....")
            // 后台服务
        }
        return START_NOT_STICKY
    }

    fun setup(
        virtualAddress: String,
        virtualMask: Int,
        dnsList: List<String>,
        allowedApplications: List<String>,
    ): ParcelFileDescriptor? {

        return Builder()
            .addAddress(virtualAddress, virtualMask)
            .addRoute("202.195.100.36", 32)
            // TODO Add Route here
            .setSession("EnlinkVPN")
            .setConfigureIntent(intent)
            //.addDisallowedApplication("io.github.cczuossa.cczu_helper")
            .apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    setMetered(false)
                }
                dnsList.forEach {
                    Log.i(
                        "ccze-helper",
                        "setup vpn dns: $it"
                    )
                    if (it.isNotBlank() && it != "127.0.0.1") addDnsServer(it.trim())
                }
                allowedApplications.forEach { if (it.isNotBlank()) addAllowedApplication(it.trim()) }
                //addAllowedApplication("com.mmbox.xbrowser")
                //addAllowedApplication("com.tencent.wework")
            }
            .establish()
    }

    override fun onDestroy() {
        super.onDestroy()
        EnlinkVPN.socket.close()
    }

    open class EnlinkVpnServiceBinder(
        val service: EnlinkVpnService

    ) : Binder() {
        fun service(): EnlinkVpnService {
            return this.service
        }
    }

}