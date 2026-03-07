package com.georgeyt9769.cardabase

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Build
import android.widget.RemoteViews
import com.google.zxing.BarcodeFormat
import com.google.zxing.MultiFormatWriter
import com.google.zxing.common.BitMatrix

class CardWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("cardabase_widgets", Context.MODE_PRIVATE)
            val cardData = prefs.getString("card_data", null)

            val views = RemoteViews(context.packageName, R.layout.card_widget)

            if (cardData == null) {
                // Empty state - no card selected yet
                views.setViewVisibility(R.id.widget_text, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_barcode, android.view.View.GONE)
                views.setInt(R.id.widget_bg_border, "setBackgroundColor", Color.DKGRAY)
            } else {
                val cardType = prefs.getString("card_type", "CardType.ean13")
                val red = prefs.getInt("card_r", 255)
                val green = prefs.getInt("card_g", 255)
                val blue = prefs.getInt("card_b", 255)
                val color = Color.rgb(red, green, blue)

                views.setViewVisibility(R.id.widget_text, android.view.View.GONE)
                views.setViewVisibility(R.id.widget_barcode, android.view.View.VISIBLE)
                views.setInt(R.id.widget_bg_border, "setBackgroundColor", color)

                // Generate barcode
                val format = getBarcodeFormat(cardType ?: "")
                val bitmap = generateBarcodeBitmap(cardData, format)

                if (bitmap != null) {
                    views.setImageViewBitmap(R.id.widget_barcode, bitmap)
                }
            }

            // Launch app on click
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(context, appWidgetId, intent, piFlags)
            views.setOnClickPendingIntent(R.id.widget_bg_border, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun getBarcodeFormat(type: String): BarcodeFormat {
            return when (type) {
                "CardType.code39" -> BarcodeFormat.CODE_39
                "CardType.code93" -> BarcodeFormat.CODE_93
                "CardType.code128" -> BarcodeFormat.CODE_128
                "CardType.ean13" -> BarcodeFormat.EAN_13
                "CardType.ean8" -> BarcodeFormat.EAN_8
                "CardType.upca" -> BarcodeFormat.UPC_A
                "CardType.upce" -> BarcodeFormat.UPC_E
                "CardType.codabar" -> BarcodeFormat.CODABAR
                "CardType.qrcode" -> BarcodeFormat.QR_CODE
                "CardType.datamatrix" -> BarcodeFormat.DATA_MATRIX
                "CardType.aztec" -> BarcodeFormat.AZTEC
                "CardType.itf" -> BarcodeFormat.ITF
                else -> BarcodeFormat.CODE_128
            }
        }

        private fun generateBarcodeBitmap(data: String, format: BarcodeFormat): Bitmap? {
            try {
                val writer = MultiFormatWriter()
                val bitMatrix: BitMatrix = writer.encode(data, format, 800, 400)
                val width = bitMatrix.width
                val height = bitMatrix.height
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

                for (x in 0 until width) {
                    for (y in 0 until height) {
                        bitmap.setPixel(x, y, if (bitMatrix.get(x, y)) Color.BLACK else Color.WHITE)
                    }
                }
                return bitmap
            } catch (e: Exception) {
                e.printStackTrace()
                return null
            }
        }
    }
}
