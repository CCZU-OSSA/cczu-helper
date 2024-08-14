package io.github.cczuossa.cczu_helper

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.github.cczuossa.cczu_helper.flutter.EnlinkVpnPlugin

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 注册插件
        provideFlutterEngine(this)?.plugins?.add(EnlinkVpnPlugin())

    }
}
