package com.credentics.credence

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class ExpiringDocsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

            val views = RemoteViews(context.packageName, R.layout.expiring_docs_widget)

            for (i in 1..3) {
                val name = prefs.getString("expiring_${i}_name", "") ?: ""
                val date = prefs.getString("expiring_${i}_date", "") ?: ""
                val textViewId = context.resources.getIdentifier("expiring_$i", "id", context.packageName)
                if (textViewId != 0) {
                    views.setTextViewText(textViewId, if (name.isNotEmpty()) "$name • $date" else "")
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
