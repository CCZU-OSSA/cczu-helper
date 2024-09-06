package io.github.cczuossa.cczu_helper.flutter

import android.Manifest
import android.app.Activity.BIND_AUTO_CREATE
import android.app.Activity.RESULT_OK
import android.content.ComponentName
import android.content.ServiceConnection
import android.net.VpnService
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import io.github.cczuossa.cczu_helper.utils.Utils.Companion.async
import io.github.cczuossa.cczu_helper.utils.Utils.Companion.sync
import io.github.cczuossa.cczu_helper.vpn.EnlinkVpnService
import io.github.cczuossa.cczu_helper.utils.bindService
import io.github.cczuossa.cczu_helper.utils.stopService
import io.github.cczuossa.cczu_helper.vpn.EnlinkAdapter
import io.github.cczuossa.cczu_helper.vpn.EnlinkVPN
import io.github.cczuossa.cczu_helper.vpn.data.EnlinkTunRouteData

class EnlinkVpnPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var binding: FlutterPluginBinding
    private var service: EnlinkVpnService? = null
    private var connector: (service: EnlinkVpnService) -> Unit = {}
    private lateinit var activityBinding: ActivityPluginBinding

    private val channel by lazy {
        MethodChannel(binding.binaryMessenger, "helper_enlink_vpn")
    }

    private val connection by lazy {
        object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
                if (binder is EnlinkVpnService.EnlinkVpnServiceBinder) {
                    // 获取服务
                    service = binder.service()
                    sync {
                        connector.invoke(service!!)
                    }
                } else {
                    Log.i("cczu-helper", "Unknown binder: $binder")
                }
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                // 服务断开时
                service = null
            }

        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.binding = binding
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activityBinding = binding
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activityBinding = binding
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                if (call.hasArgument("user") && call.hasArgument("token")) {
                    // 取参数
                    val user = call.argument<String>("user")
                    val token = call.argument<String>("token")
                    val dns = call.argument<String>("dns")
                    val apps = call.argument<String>("apps")
                    val routes = call.argument<String>("routes")
                    Log.i("cczu-helper", "call kotlin method,routes: $routes")
                    async {
                        EnlinkVPN.init(user!!, token!!) { status, data, vpn ->
                            if (status) {
                                // 认证完毕
                                // 处理dns和apps
                                if (!dns.isNullOrBlank()) {
                                    dns.trim().split(",").forEach {
                                        if (it.isNotBlank()) {
                                            data.dns.add(it.trim())
                                            data.routes.add(EnlinkTunRouteData(it.trim()))
                                        }
                                    }
                                } else data.dns.add("211.65.64.65")

                                if (!apps.isNullOrBlank()) {
                                    apps.trim().split(",").forEach {
                                        if (it.isNotBlank()) data.apps.add(it.trim())
                                    }
                                }

                                // 处理 routes
                                if (!routes.isNullOrBlank()) {
                                    routes.trim().split("#").forEach {
                                        if (it.isNotBlank()) {
                                            val route = it
                                                .replace("ANY://", "")
                                                .replace("TCP://", "")
                                                .replace("UDP://", "")
                                                .replace("ANY;", "")
                                                .replace("TCP;", "")
                                                .replace("UDP;", "")
                                                .split("/")[0]
                                            data.routes.add(EnlinkTunRouteData(route))
                                        }
                                    }
                                }

                                // 准备vpn服务
                                prepare {
                                    if (it == RESULT_OK) {
                                        // 当同意创建vpn连接时绑定并启动服务
                                        connector = { service ->
                                            // 当服务启动成功
                                            // 配置服务并代理
                                            result.success(EnlinkAdapter.proxy(service, data, vpn))
                                        }
                                        // 尝试绑定服务
                                        Log.i("cczu-helper", "try bind service")
                                        this.activityBinding.activity.bindService(
                                            EnlinkVpnService::class.java,
                                            connection,
                                            BIND_AUTO_CREATE
                                        )
                                    }
                                }
                            } else {
                                result.success(false)
                            }
                        }

                    }

                } else {
                    result.success(false)
                }
            }

            "stop" -> {
                connector = {}
                EnlinkAdapter.stop()
                this.activityBinding.activity.stopService(
                    EnlinkVpnService::class.java
                )
                result.success(true)

            }
        }
    }


    private fun prepare(callback: (result: Int) -> Unit) {
        // 弹出创建VPN连接请求
        sync {
            VpnService.prepare(this.activityBinding.activity.application)
                ?.let { intent ->
                    // 定义请求code
                    val reqCode = 0x5c
                    var resultListener: ActivityResultListener? = null
                    // 初始化回调
                    resultListener = ActivityResultListener { requestCode, resultCode, data ->
                        // 返回结果
                        if (requestCode == reqCode) callback.invoke(resultCode)
                        resultListener?.let {
                            this.activityBinding.removeActivityResultListener(
                                it
                            )
                        }
                        true
                    }
                    // 注册回调
                    this.activityBinding.addActivityResultListener(resultListener)
                    ActivityCompat.requestPermissions(
                        this.activityBinding.activity,
                        arrayListOf<String>().apply {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                add(Manifest.permission.POST_NOTIFICATIONS)
                                add(Manifest.permission.FOREGROUND_SERVICE)
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                add(Manifest.permission.FOREGROUND_SERVICE_SPECIAL_USE)
                            }
                        }.toTypedArray(),
                        0x3c
                    )
                    // 弹出连接请求
                    this.activityBinding.activity.startActivityForResult(intent, reqCode)

                } ?: callback.invoke(RESULT_OK)
        }
    }

    override fun onDetachedFromActivity() {}

    override fun onDetachedFromActivityForConfigChanges() {}
}