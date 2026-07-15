package com.example.fintech_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SafeToSpendWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.safe_to_spend_widget_layout).apply {
                // Get data saved from Flutter as Strings
                val safeToSpendText = widgetData.getString("safe_to_spend_text", "₹0") ?: "₹0"
                val totalBalanceText = widgetData.getString("total_balance_text", "Total Cash: ₹0") ?: "Total Cash: ₹0"
                val remainingDaysText = widgetData.getString("remaining_days_text", "-- days remaining") ?: "-- days remaining"

                // Update views
                setTextViewText(R.id.widget_title, "Safe to Spend Today")
                setTextViewText(R.id.widget_safe_to_spend, safeToSpendText)
                setTextViewText(R.id.widget_total_balance, totalBalanceText)
                setTextViewText(R.id.widget_remaining_days, remainingDaysText)

                // Get dynamic top categories from Flutter
                val topCat1Name = widgetData.getString("top_category_1_name", "food") ?: "food"
                val topCat1Label = widgetData.getString("top_category_1_label", "Food") ?: "Food"
                val topCat2Name = widgetData.getString("top_category_2_name", "shopping") ?: "shopping"
                val topCat2Label = widgetData.getString("top_category_2_label", "Shopping") ?: "Shopping"

                // Set dynamic button labels
                setTextViewText(R.id.btn_top_cat_1, topCat1Label)
                setTextViewText(R.id.btn_top_cat_2, topCat2Label)

                // Set click action for dynamic category 1 (opens app with preselected category)
                val topCat1Intent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fintrack://add-transaction?type=expense&category=$topCat1Name")
                )
                setOnClickPendingIntent(R.id.btn_top_cat_1, topCat1Intent)

                // Set click action for dynamic category 2 (opens app with preselected category)
                val topCat2Intent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fintrack://add-transaction?type=expense&category=$topCat2Name")
                )
                setOnClickPendingIntent(R.id.btn_top_cat_2, topCat2Intent)

                // Fixed Coffee background log button (does not open the app)
                val coffeeIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("fintrack://add_expense?amount=10&category=food&note=Coffee")
                )
                setOnClickPendingIntent(R.id.btn_coffee, coffeeIntent)

                // Custom Add Button (+) deep-links directly
                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fintrack://add-transaction?type=expense")
                )
                setOnClickPendingIntent(R.id.btn_add_custom, launchIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
