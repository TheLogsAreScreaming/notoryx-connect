package com.bastionmesh.bastion

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Home-screen status: radio link, nodes, battery, unread messages and SOS. */
class StatusWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.status_widget).apply {
                setTextViewText(R.id.widget_title, widgetData.getString("widget_title", "NOTORYX Connect"))
                setTextViewText(R.id.widget_detail, widgetData.getString("widget_detail", "Open the app to connect a radio"))
                setTextViewText(R.id.widget_messages, widgetData.getString("widget_messages", ""))
                setTextViewText(R.id.widget_updated, widgetData.getString("widget_updated", ""))
                val alert = widgetData.getString("widget_alert", "") ?: ""
                setTextViewText(R.id.widget_alert, alert)
                setViewVisibility(R.id.widget_alert, if (alert.isEmpty()) View.GONE else View.VISIBLE)
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
        RadioTileService.requestRefresh(context)
    }
}
