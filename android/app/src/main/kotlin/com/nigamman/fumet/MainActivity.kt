package com.nigamman.fumet

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.app.PendingIntent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nigamman.fumet/widgets"
    private val PIN_ACTION = "com.nigamman.fumet.WIDGET_PINNED"
    private var pinReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "requestPinWidget") {
                val widgetType = call.argument<String>("type") ?: "small"
                val success = requestPinWidget(widgetType)
                result.success(success)
            } else {
                result.notImplemented()
            }
        }

        // Register the dynamic broadcast receiver for pin success callback
        pinReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == PIN_ACTION) {
                    methodChannel?.invokeMethod("onWidgetPinned", null)
                }
            }
        }
        
        val filter = IntentFilter(PIN_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pinReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(pinReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        pinReceiver?.let {
            unregisterReceiver(it)
        }
    }

    private fun requestPinWidget(type: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val provider = if (type == "medium") {
                ComponentName(this, SafeToSpendWidgetProvider::class.java)
            } else {
                ComponentName(this, SafeToSpendSmallWidgetProvider::class.java)
            }

            if (appWidgetManager.isRequestPinAppWidgetSupported) {
                val intent = Intent(PIN_ACTION).apply {
                    setPackage(packageName)
                }
                
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                
                val pendingIntent = PendingIntent.getBroadcast(
                    this,
                    0,
                    intent,
                    flags
                )

                return appWidgetManager.requestPinAppWidget(provider, null, pendingIntent)
            }
        }
        return false
    }
}
