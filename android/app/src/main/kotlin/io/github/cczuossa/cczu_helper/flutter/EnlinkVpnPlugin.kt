package io.github.cczuossa.cczu_helper.flutter

import android.app.Activity.BIND_AUTO_CREATE
import android.app.Activity.RESULT_OK
import android.content.ComponentName
import android.content.ServiceConnection
import android.net.VpnService
import android.os.IBinder
import android.util.Log
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
import io.github.cczuossa.cczu_helper.vpn.EnlinkVPN

class EnlinkVpnPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private var vpn: EnlinkVPN? = null
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
                    connector.invoke(service!!)
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
        Log.i("cczu-helper", "dart call: ${call.method}")
        when (call.method) {
            "start" -> {
                if (call.hasArgument("user") && call.hasArgument("token")) {
                    val user = call.argument<String>("user")
                    val token = call.argument<String>("token")
                    val dns = call.argument<String>("dns")
                    val apps = call.argument<String>("apps")
                    async {
                        this.vpn = EnlinkVPN(user!!, token!!) { status, vpn ->
                            if (status) {
                                // 认证完毕
                                prepare {
                                    if (it == RESULT_OK) {
                                        // 当同意创建vpn连接时绑定并启动服务
                                        connector = { service ->
                                            // 当服务启动成功
                                            // 初始化服务
                                            vpn.init(service, dns ?: "211.65.64.65", apps)
                                        }
                                        this.activityBinding.activity.bindService(
                                            EnlinkVpnService::class.java,
                                            connection,
                                            BIND_AUTO_CREATE
                                        )
                                    }
                                    result.success(it == RESULT_OK)
                                }
                            } else {
                                result.success(status)
                            }
                        }
                        this.vpn?.auth()
                    }

                } else {
                    result.success(false)
                }
            }

            "stop" -> {
                connector = {}
                if (this.vpn != null) {
                    this.vpn?.stop()
                }
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
                    // 弹出连接请求
                    this.activityBinding.activity.startActivityForResult(intent, reqCode)

                } ?: callback.invoke(RESULT_OK)
        }
    }

    override fun onDetachedFromActivity() {}

    override fun onDetachedFromActivityForConfigChanges() {}
}