package com.example.project_wellness

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Shows today's logged calories vs. target plus a macro breakdown — synced
 * from Dart via `lib/core/widget/home_widget_service.dart` whenever the user
 * lands back on the Home screen.
 */
class CalorieWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val calories = widgetData.getInt("calories_logged", 0)
    val target = widgetData.getInt("calories_target", 0)
    val protein = widgetData.getInt("protein_g", 0)
    val carbs = widgetData.getInt("carbs_g", 0)
    val fat = widgetData.getInt("fat_g", 0)

    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.calorie_widget).apply {
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            setTextViewText(
                R.id.widget_calories,
                if (target > 0) "$calories / $target kcal" else "$calories kcal",
            )
            setTextViewText(R.id.widget_protein, "P ${protein}g")
            setTextViewText(R.id.widget_carbs, "C ${carbs}g")
            setTextViewText(R.id.widget_fat, "F ${fat}g")
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
