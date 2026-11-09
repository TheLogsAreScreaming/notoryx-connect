package com.bastionmesh.bastion

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Sends SMS for the opt-in relay. Only present in builds made with --sms. */
object SmsRelayChannel {
    private const val CHANNEL = "com.bastionmesh.connect/sms"
    private const val REQUEST = 4711

    fun attach(activity: Activity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val granted = activity.checkSelfPermission(Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED
            when (call.method) {
                "hasPermission" -> result.success(granted)
                "requestPermission" -> {
                    if (!granted) activity.requestPermissions(arrayOf(Manifest.permission.SEND_SMS), REQUEST)
                    result.success(granted)
                }
                "send" -> {
                    val number = call.argument<String>("number")
                    val text = call.argument<String>("text")
                    if (!granted || number == null || text == null) {
                        result.error("refused", "SMS permission or message missing", null)
                    } else {
                        try {
                            manager(activity).sendTextMessage(number, null, text, null, null)
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("failed", error.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun manager(activity: Activity): SmsManager =
        if (Build.VERSION.SDK_INT >= 31) activity.getSystemService(SmsManager::class.java) else SmsManager.getDefault()
}
