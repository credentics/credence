package com.credentics.credence

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

class VaultHealthWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val score = prefs.getInt("vault_health_score", -1)
            val grade = prefs.getString("vault_health_grade", "Unknown") ?: "Unknown"

            val views = RemoteViews(context.packageName, R.layout.vault_health_widget)
            views.setTextViewText(R.id.vault_score, if (score >= 0) "$score" else "--")
            views.setTextViewText(R.id.vault_grade, grade)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
