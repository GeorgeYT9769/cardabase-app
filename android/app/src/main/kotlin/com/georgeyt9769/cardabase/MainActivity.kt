package com.georgeyt9769.cardabase

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.os.Environment
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "cardabase_widget"
    private val STORAGE_CHANNEL = "cardabase_storage"

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getExternalStorageDirectory") {
                // Deprecated on Android 10+, but this app already relies on
                // MANAGE_EXTERNAL_STORAGE / legacy external storage and needs
                // the public root for the *current* user, not user 0.
                @Suppress("DEPRECATION")
                val path = Environment.getExternalStorageDirectory().absolutePath
                result.success(path)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setWidgetCard") {
                val data: String? = call.argument("data")
                val name: String? = call.argument("name")
                val type: String? = call.argument("type")
                val r = call.argument<Int>("r") ?: 255
                val g = call.argument<Int>("g") ?: 255
                val b = call.argument<Int>("b") ?: 255

                if (data != null && type != null) {
                    saveWidgetData(data, name, type, r, g, b)
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

    private fun saveWidgetData(data: String, name: String?, type: String, r: Int, g: Int, b: Int) {
        val prefs = applicationContext.getSharedPreferences("cardabase_widgets", MODE_PRIVATE)
        prefs.edit()
            .putString("card_data", data)
            .putString("card_name", name)
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
