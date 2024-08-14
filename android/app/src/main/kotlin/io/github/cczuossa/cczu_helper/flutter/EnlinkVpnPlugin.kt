package io.github.cczuossa.cczu_helper.flutter

import android.app.Activity.BIND_AUTO_CREATE
import android.app.Activity.RESULT_OK
import android.content.ComponentName
import android.content.ServiceConnection
import android.net.VpnService
import android.os.IBinder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import io.github.cczuossa.cczu_helper.vpn.EnlinkVpnService
import io.github.cczuossa.cczu_helper.utils.bindService
import io.github.cczuossa.cczu_helper.vpn.EnlineVpnForwarder

class EnlinkVpnPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler {

    private var forwarder: EnlineVpnForwarder? = null
    private lateinit var binding: FlutterPluginBinding
    private var service: EnlinkVpnService? = null
    private var eventSink: EventSink? = null
    private lateinit var activityBinding: ActivityPluginBinding

    private val channel by lazy {
        MethodChannel(binding.binaryMessenger, "helper_enlink_vpn")
    }
    private val event by lazy {
        EventChannel(binding.binaryMessenger, "helper_enlink_vpn_event")
    }

    private val connection by lazy {
        object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
                if (binder is EnlinkVpnService.EnlinkVpnServiceBinder) {
                    // 获取服务
                    service = binder.service()
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
        event.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        event.setStreamHandler(null)
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
                prepare {
                    if (it == RESULT_OK) {
                        // 当同意创建vpn连接时绑定并启动服务
                        this.activityBinding.activity.bindService(
                            EnlinkVpnService::class.java,
                            connection,
                            BIND_AUTO_CREATE
                        )
                    }
                    result.success(it == RESULT_OK)
                }
            }

            "connect" -> {
                this.service?.apply {
                    val args = call.arguments as Map<*, *>
                    result.success(
                        this.forward(
                            args.getOrDefault("address", "0.0.0.0") as String,
                            args.getOrDefault("mask", 32) as Int,
                            arrayListOf<String>().apply {
                                (args.getOrDefault("dns", "127.0.0.1") as String)
                                    .split(",")
                                    .forEach {
                                        add(it)
                                    }
                            },
                            arrayListOf<String>().apply {
                                (args.getOrDefault(
                                    "apps",
                                    this@EnlinkVpnPlugin.activityBinding.activity.packageName
                                ) as String)
                                    .split(",")
                                    .forEach {
                                        add(it)
                                    }
                            }
                        ) { proxyIn ->
                            // 从proxyIn读入然后传入事件中
                            if (eventSink != null) {
                                eventSink?.success(proxyIn)
                            }
                        }.apply {
                            this@EnlinkVpnPlugin.forwarder = this
                        } != null

                    )

                } ?: result.success(false)

            }

            "write" -> {
                this.forwarder?.apply {
                    // 写出到proxy
                    val data = call.arguments as ByteArray
                    write(data)
                } ?: result.success(false)
            }


        }
    }


    private fun prepare(callback: (result: Int) -> Unit) {
        // 弹出创建VPN连接请求
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


    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {

    }

    override fun onDetachedFromActivity() {}

    override fun onDetachedFromActivityForConfigChanges() {}
}