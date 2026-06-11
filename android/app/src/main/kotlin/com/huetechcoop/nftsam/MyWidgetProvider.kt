package com.huetechcoop.nftsam

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider // Đổi thành AppWidgetProvider chuẩn của Android
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin // Thêm thư viện này để đọc dữ liệu

// Kế thừa AppWidgetProvider thay vì HomeWidgetProvider
class MyWidgetProvider : AppWidgetProvider() {

    // Hàm onUpdate chuẩn của Android không có tham số SharedPreferences truyền vào sẵn
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {

        // Tự lấy dữ liệu (SharedPreferences) mà Flutter đã lưu thông qua HomeWidgetPlugin
        val widgetData = HomeWidgetPlugin.getData(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Dữ liệu thời tiết
                setTextViewText(R.id.widget_day, widgetData.getString("day_str", "--/--"))
                setTextViewText(R.id.widget_icon, widgetData.getString("weather_icon", "☀️"))
                setTextViewText(R.id.widget_temp, widgetData.getString("temp_range", "0° - 0°"))
                setTextViewText(R.id.widget_precip, widgetData.getString("precip_sum", "0mm"))

                // Dữ liệu cây sâm
                setTextViewText(R.id.widget_total_plants, widgetData.getString("total_plants", "Đang tải..."))
                setTextViewText(R.id.widget_health_score, widgetData.getString("health_score", "Đang tải..."))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}