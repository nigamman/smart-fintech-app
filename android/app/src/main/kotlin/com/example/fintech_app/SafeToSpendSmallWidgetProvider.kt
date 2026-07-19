package com.example.fintech_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SafeToSpendSmallWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.safe_to_spend_small_widget_layout).apply {
                // Get data saved from Flutter
                val safeToSpendText = widgetData.getString("safe_to_spend_text", "₹0") ?: "₹0"
                val totalBalanceText = widgetData.getString("total_balance_text", "Total Cash: ₹0") ?: "Total Cash: ₹0"
                val remainingDaysText = widgetData.getString("remaining_days_text", "-- days remaining") ?: "-- days remaining"

                // Update views
                setTextViewText(R.id.widget_title, "Safe Today")
                setTextViewText(R.id.widget_safe_to_spend, safeToSpendText)
                setTextViewText(R.id.widget_total_balance, totalBalanceText)
                setTextViewText(R.id.widget_remaining_days, remainingDaysText)

                // 1. Tapping the widget body deep-links to Dashboard screen
                val dashboardIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fintrack://dashboard")
                )
                // Set pending intent on the root layout itself by omitting view ID or targeting the container
                // RemoteViews requires a view ID, but we can set it on widget_title/widget_safe_to_spend or layout children
                setOnClickPendingIntent(R.id.widget_safe_to_spend, dashboardIntent)
                setOnClickPendingIntent(R.id.widget_title, dashboardIntent)
                setOnClickPendingIntent(R.id.widget_total_balance, dashboardIntent)

                // 2. Tapping the custom "+" button deep-links to Add Transaction screen
                val addExpenseIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fintrack://add-transaction?type=expense")
                )
                setOnClickPendingIntent(R.id.btn_add_custom, addExpenseIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
