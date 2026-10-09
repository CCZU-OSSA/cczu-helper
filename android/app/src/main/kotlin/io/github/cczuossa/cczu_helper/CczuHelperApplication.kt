package io.github.cczuossa.cczu_helper

import io.flutter.app.FlutterMultiDexApplication

class CczuHelperApplication : FlutterMultiDexApplication() {
    companion object {
        init {
            System.loadLibrary("hub")
        }

        @JvmStatic
        external fun initializeRustls(context: CczuHelperApplication)
    }

    override fun onCreate() {
        super.onCreate()
        initializeRustls(this)
    }
}
