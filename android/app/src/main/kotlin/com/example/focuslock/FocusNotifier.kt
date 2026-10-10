package com.example.focuslock

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import java.util.Date

/**
 * Ongoing "focus session" notification. When [endMillis] is given, Android
 * itself renders and updates a countdown chronometer, so the time keeps
 * ticking correctly even if the Flutter side is throttled in the background.
 */
object FocusNotifier {
    private const val CHANNEL_ID = "focus_timer"
    private const val NOTIF_ID = 4242

    private const val AMBER = 0xFFE8A33D.toInt()

    private fun bind(
        context: Context,
        layout: Int,
        taskTitle: String,
        endMillis: Long?,
        timeLeft: String?,
    ): RemoteViews {
        val rv = RemoteViews(context.packageName, layout)
        rv.setTextViewText(R.id.focus_task, taskTitle)
        if (endMillis != null) {
            val base = SystemClock.elapsedRealtime() + (endMillis - System.currentTimeMillis())
            rv.setChronometer(R.id.focus_chrono, base, null, true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                rv.setChronometerCountDown(R.id.focus_chrono, true)
            }
            rv.setViewVisibility(R.id.focus_chrono, android.view.View.VISIBLE)
            rv.setViewVisibility(R.id.focus_static, android.view.View.GONE)
            val endsAt = android.text.format.DateFormat.getTimeFormat(context).format(Date(endMillis))
            rv.setTextViewText(R.id.focus_sub, "Ends at $endsAt \u00b7 distractions blocked")
        } else {
            rv.setViewVisibility(R.id.focus_chrono, android.view.View.GONE)
            rv.setViewVisibility(R.id.focus_static, android.view.View.VISIBLE)
            rv.setTextViewText(R.id.focus_static, timeLeft ?: "--:--")
            rv.setTextViewText(R.id.focus_label, "FOCUS PAUSED")
            rv.setTextViewText(R.id.focus_sub, "Paused \u00b7 tap to resume")
        }
        return rv
    }

    fun show(
        context: Context,
        title: String,
        text: String,
        endMillis: Long?,
        timeLeft: String? = null,
    ) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Focus timer", NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shows the time left in your focus session"
                setShowBadge(false)
            }
            nm.createNotificationChannel(channel)
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentTitle(title)
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)

        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launch ->
            builder.setContentIntent(
                PendingIntent.getActivity(
                    context, 0, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
        }

        builder.setColor(AMBER).setShowWhen(false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder
                .setStyle(Notification.DecoratedCustomViewStyle())
                .setCustomContentView(bind(context, R.layout.notification_focus_small, text, endMillis, timeLeft))
                .setCustomBigContentView(bind(context, R.layout.notification_focus_big, text, endMillis, timeLeft))
        }

        if (endMillis != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Remove itself when the session time is up.
            builder.setTimeoutAfter(maxOf(1L, endMillis - System.currentTimeMillis()))
        }

        nm.notify(NOTIF_ID, builder.build())
    }

    fun cancel(context: Context) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(NOTIF_ID)
    }
}
