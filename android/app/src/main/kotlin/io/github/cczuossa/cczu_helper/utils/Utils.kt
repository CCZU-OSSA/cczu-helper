package io.github.cczuossa.cczu_helper.utils

import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import java.util.concurrent.Executors

class Utils {
    companion object {
        private val pool = Executors.newCachedThreadPool()

        @JvmStatic
        fun async(runnable: () -> Unit) {
            pool.execute(runnable)
        }
    }
}

fun Context.bindService(clazz: Class<*>, conn: ServiceConnection, flags: Int) {
    bindService(Intent(this, clazz), conn, flags)
}