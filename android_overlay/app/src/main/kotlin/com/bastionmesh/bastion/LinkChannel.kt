package com.bastionmesh.bastion

import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

// Hands links the app was opened with (a QR code's link, a web link, or an
// NFC tag) to Dart: getInitialLink for the one that started the activity,
// and "link" calls for ones that arrive while it runs.
object LinkChannel {
    private const val NAME = "notoryx/links"
    private var channel: MethodChannel? = null
    private var pending: String? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, NAME).also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "getInitialLink") {
                    result.success(pending)
                    pending = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    // Called from onCreate (initial) and onNewIntent (later). The engine
    // outlives activities, so Dart may already be listening even for an
    // "initial" link: keep it for getInitialLink and also push it. Dart
    // ignores the second copy of the same link.
    @Suppress("UNUSED_PARAMETER")
    fun handle(intent: Intent?, initial: Boolean) {
        val link = linkFrom(intent) ?: return
        pending = link
        channel?.invokeMethod("link", link)
    }

    private fun linkFrom(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.action == NfcAdapter.ACTION_NDEF_DISCOVERED) {
            val messages = if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES, NdefMessage::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
            }
            for (m in messages.orEmpty()) {
                for (record in (m as NdefMessage).records) {
                    val uri = record.toUri() ?: continue
                    return uri.toString()
                }
            }
            return intent.dataString
        }
        if (intent.action == Intent.ACTION_VIEW) return intent.dataString
        return null
    }
}
