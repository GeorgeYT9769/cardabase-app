package com.georgeyt9769.cardabase

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "cardabase_widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setWidgetCard") {
                val data = call.argument<String>("data")
                val type = call.argument<String>("type")
                val r = call.argument<Int>("r") ?: 255
                val g = call.argument<Int>("g") ?: 255
                val b = call.argument<Int>("b") ?: 255
                
                if (data != null && type != null) {
                    saveWidgetData(data, type, r, g, b)
                    updateAllWidgets()
                    result.success(true)
                } else {
                    result.error("INVALID_ARGS", "Missing data or type", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveWidgetData(data: String, type: String, r: Int, g: Int, b: Int) {
        val prefs = applicationContext.getSharedPreferences("cardabase_widgets", MODE_PRIVATE)
        prefs.edit()
            .putString("card_data", data)
            .putString("card_type", type)
            .putInt("card_r", r)
            .putInt("card_g", g)
            .putInt("card_b", b)
            .apply()
    }

    private fun updateAllWidgets() {
        val ctx = applicationContext
        val appWidgetManager = AppWidgetManager.getInstance(ctx)
        val provider = ComponentName(ctx, CardWidgetProvider::class.java)
        val widgetIds = appWidgetManager.getAppWidgetIds(provider)
        for (id in widgetIds) {
            CardWidgetProvider.updateAppWidget(ctx, appWidgetManager, id)
        }
    }
}
