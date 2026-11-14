package com.bastionmesh.bastion

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

/**
 * Quick Settings tile: shows whether a radio is connected, using the same
 * status the home-screen widget shows, and opens the app when tapped.
 * It never connects or sends anything by itself.
 */
@RequiresApi(Build.VERSION_CODES.N)
class RadioTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        refresh()
    }

    override fun onClick() {
        super.onClick()
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (Build.VERSION.SDK_INT >= 34) {
            val pending = PendingIntent.getActivity(
                this, 0, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun refresh() {
        val tile = qsTile ?: return
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val title = prefs.getString("widget_title", null) ?: getString(R.string.radio_tile_no_radio)
        val alert = prefs.getString("widget_alert", "") ?: ""
        val connected = title.startsWith("Connected")
        tile.label = getString(R.string.radio_tile_label)
        tile.icon = Icon.createWithResource(this, R.drawable.ic_radio_tile)
        tile.state = if (connected) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        val detail = if (alert.isNotEmpty()) alert else title
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = detail
        }
        tile.contentDescription = "${tile.label}: $detail"
        tile.updateTile()
    }

    companion object {
        /** The file the home_widget plugin writes the widget status to. */
        private const val PREFS = "HomeWidgetPreferences"

        /** Asks the system to refresh the tile after the status changed. */
        fun requestRefresh(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
            try {
                requestListeningState(context, ComponentName(context, RadioTileService::class.java))
            } catch (_: Exception) {
                // The tile isn't added, or the system refused; it refreshes when opened.
            }
        }
    }
}
