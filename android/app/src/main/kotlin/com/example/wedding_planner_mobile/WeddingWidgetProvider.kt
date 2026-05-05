package com.example.wedding_planner_mobile

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class WeddingWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPlugin", Context.MODE_PRIVATE)
        val views = RemoteViews(context.packageName, R.layout.wedding_widget)

        // Tap anywhere → open app at timeline
        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("bigm://timeline")
        )
        views.setOnClickPendingIntent(R.id.widget_root, launchIntent)

        // Populate up to 3 task rows
        val rowIds = intArrayOf(R.id.task_0_row, R.id.task_1_row, R.id.task_2_row)
        val titleIds = intArrayOf(R.id.task_0_title, R.id.task_1_title, R.id.task_2_title)
        val dateIds = intArrayOf(R.id.task_0_date, R.id.task_1_date, R.id.task_2_date)
        val assigneeIds = intArrayOf(R.id.task_0_assignee, R.id.task_1_assignee, R.id.task_2_assignee)

        var visibleCount = 0
        for (i in 0..2) {
            val title = prefs.getString("task_${i}_title", null)
            val date = prefs.getString("task_${i}_date", null)
            val assignee = prefs.getString("task_${i}_assignee", "") ?: ""
            val visible = prefs.getBoolean("task_${i}_visible", false)

            if (visible && !title.isNullOrEmpty()) {
                views.setViewVisibility(rowIds[i], View.VISIBLE)
                views.setTextViewText(titleIds[i], title)
                views.setTextViewText(dateIds[i], date ?: "")
                views.setTextViewText(assigneeIds[i], assignee)
                visibleCount++
            } else {
                views.setViewVisibility(rowIds[i], View.GONE)
            }
        }

        // Show empty state when no tasks
        views.setViewVisibility(
            R.id.widget_empty,
            if (visibleCount == 0) View.VISIBLE else View.GONE
        )

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
