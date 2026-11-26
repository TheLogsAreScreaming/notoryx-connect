package com.bastionmesh.bastion

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PersistableBundle
import android.os.SystemClock
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * "notoryx/clipboard" for SARNEG text.
 *
 * copySensitive(text): copies with the "sensitive" flag, so Android and
 * keyboards that honour it don't show it in previews or keep it in history.
 * clear(): removes the clip, so nothing is left to paste.
 * scheduleClear(ms): clears the clip after [ms] even if the app has been
 * frozen or killed by then, using a system alarm. If the alarm still hasn't
 * fired when the app next starts, the clear happens then.
 * cancelClear(): drops a scheduled clear.
 */
object SecretClipboardChannel {
    // ClipDescription.EXTRA_IS_SENSITIVE on Android 13+; older keyboards
    // read the same key by name.
    private const val IS_SENSITIVE = "android.content.extra.IS_SENSITIVE"
    private const val PREFS = "notoryx_clipboard"
    private const val DUE_AT = "clear_due_at_wall_ms"

    fun register(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        // A clear that was due while the app was gone happens now.
        clearIfOverdue(app)
        MethodChannel(messenger, "notoryx/clipboard").setMethodCallHandler { call, result ->
            when (call.method) {
                "copySensitive" -> {
                    val text = call.arguments as? String
                    if (text == null) {
                        result.error("args", "copySensitive needs the text", null)
                        return@setMethodCallHandler
                    }
                    val clip = ClipData.newPlainText("", text)
                    clip.description.extras = PersistableBundle().apply {
                        putBoolean(
                            if (Build.VERSION.SDK_INT >= 33) ClipDescription.EXTRA_IS_SENSITIVE else IS_SENSITIVE,
                            true,
                        )
                    }
                    clipboard(app).setPrimaryClip(clip)
                    result.success(null)
                }
                "clear" -> {
                    clearNow(app)
                    cancel(app)
                    result.success(null)
                }
                "scheduleClear" -> {
                    val ms = (call.arguments as? Number)?.toLong()
                    if (ms == null || ms < 0) {
                        result.error("args", "scheduleClear needs a delay in ms", null)
                        return@setMethodCallHandler
                    }
                    schedule(app, ms)
                    result.success(null)
                }
                "cancelClear" -> {
                    cancel(app)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun clipboard(context: Context) =
        context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

    fun clearNow(context: Context) {
        val clipboard = clipboard(context)
        if (Build.VERSION.SDK_INT >= 28) {
            clipboard.clearPrimaryClip()
        } else {
            clipboard.setPrimaryClip(ClipData.newPlainText("", ""))
        }
    }

    private fun pending(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, ClipboardClearReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun schedule(context: Context, delayMs: Long) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putLong(DUE_AT, System.currentTimeMillis() + delayMs).apply()
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val at = SystemClock.elapsedRealtime() + delayMs
        // Exact when the system allows it; otherwise Android may run it a
        // little later, and the overdue check on next start backs it up.
        if (Build.VERSION.SDK_INT < 31 || alarms.canScheduleExactAlarms()) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, pending(context))
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, at, pending(context))
        }
    }

    fun cancel(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(DUE_AT).apply()
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.cancel(pending(context))
    }

    private fun clearIfOverdue(context: Context) {
        val due = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getLong(DUE_AT, 0L)
        if (due in 1..System.currentTimeMillis()) {
            clearNow(context)
            cancel(context)
        }
    }
}

/** Runs the scheduled SARNEG clipboard clear, even with the app killed. */
class ClipboardClearReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        SecretClipboardChannel.clearNow(context)
        SecretClipboardChannel.cancel(context)
    }
}
