package io.github.cczuossa.cczu_helper.utils

import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Handler
import android.os.Looper
import java.util.concurrent.Executors

class Utils {
    companion object {
        private val pool = Executors.newCachedThreadPool()
        private val handler = Handler(Looper.getMainLooper())

        @JvmStatic
        fun async(runnable: () -> Unit) {
            pool.execute(runnable)
        }

        /**
         * 运行于主线程上
         */
        @JvmStatic
        fun sync(runnable: () -> Unit) {
            handler.post(runnable)
        }
    }
}

fun Context.bindService(clazz: Class<*>, conn: ServiceConnection, flags: Int) {
    bindService(Intent(this, clazz), conn, flags)
}

fun Context.stopService(clazz: Class<*>) {
    stopService(Intent(this, clazz))
}