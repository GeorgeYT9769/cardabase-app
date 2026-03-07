package com.georgeyt9769.cardabase

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class CardWidgetPinReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return

        // Read the pending card data saved by MainActivity
        val prefs = context.getSharedPreferences("cardabase_widgets", Context.MODE_PRIVATE)
        val data = prefs.getString("pending_data", null) ?: return
        val type = prefs.getString("pending_type", null) ?: return
        val r = prefs.getInt("pending_r", 255)
        val g = prefs.getInt("pending_g", 255)
        val b = prefs.getInt("pending_b", 255)

        // Save with the actual widget ID
        prefs.edit()
            .putString("data_$appWidgetId", data)
            .putString("type_$appWidgetId", type)
            .putInt("r_$appWidgetId", r)
            .putInt("g_$appWidgetId", g)
            .putInt("b_$appWidgetId", b)
            .remove("pending_data")
            .remove("pending_type")
            .remove("pending_r")
            .remove("pending_g")
            .remove("pending_b")
            .apply()

        val appWidgetManager = AppWidgetManager.getInstance(context)
        CardWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
    }
}
