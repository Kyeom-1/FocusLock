package com.example.focuslock

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Schedules "deadline is near" notifications with AlarmManager. The full
 * list is also saved to SharedPreferences so [BootReceiver] can restore the
 * alarms after the phone restarts.
 */
object DeadlineReminders {
    private const val PREFS = "focus_lock_reminders"
    private const val KEY_ITEMS = "items"
    private const val CHANNEL_ID = "deadline_reminders"

    data class Reminder(val id: Int, val at: Long, val title: String, val body: String)

    /** Replaces every scheduled reminder with [items]. */
    fun setAll(context: Context, items: List<Reminder>) {
        load(context).forEach { cancel(context, it.id) }
        save(context, items)
        val now = System.currentTimeMillis()
        val future = items.filter { it.at > now }
        future.forEach { schedule(context, it) }
        Log.d("FocusLock", "setAll: ${items.size} received, ${future.size} scheduled: " +
            future.joinToString { "${it.title}@${java.util.Date(it.at)}" })
    }

    /** One-off test alarm that is NOT stored, so list syncs never remove it. */
    fun scheduleTest(context: Context, delayMs: Long) {
        val r = Reminder(999001, System.currentTimeMillis() + delayMs,
            "FocusLock test", "If you can see this, deadline reminders can show.")
        schedule(context, r)
        Log.d("FocusLock", "test alarm set for ${java.util.Date(r.at)}")
    }

    /** Called after boot: re-create alarms that are still in the future. */
    fun restore(context: Context) {
        val now = System.currentTimeMillis()
        load(context).filter { it.at > now }.forEach { schedule(context, it) }
    }

    private fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun pendingIntent(context: Context, r: Reminder?, id: Int): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            if (r != null) {
                putExtra("id", r.id)
                putExtra("title", r.title)
                putExtra("body", r.body)
            }
        }
        return PendingIntent.getBroadcast(
            context, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun schedule(context: Context, r: Reminder) {
        // Inexact-while-idle needs no special permission; Android may deliver
        // it a few minutes late when the phone is dozing.
        alarmManager(context).setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP, r.at, pendingIntent(context, r, r.id),
        )
    }

    private fun cancel(context: Context, id: Int) {
        alarmManager(context).cancel(pendingIntent(context, null, id))
    }

    private fun save(context: Context, items: List<Reminder>) {
        val arr = JSONArray()
        items.forEach {
            arr.put(JSONObject().put("id", it.id).put("at", it.at)
                .put("title", it.title).put("body", it.body))
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY_ITEMS, arr.toString()).apply()
    }

    private fun load(context: Context): List<Reminder> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_ITEMS, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map {
                val o = arr.getJSONObject(it)
                Reminder(o.getInt("id"), o.getLong("at"), o.getString("title"), o.getString("body"))
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun notify(context: Context, id: Int, title: String, body: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Deadline reminders", NotificationManager.IMPORTANCE_HIGH)
                    .apply { description = "Alerts when a task deadline is near" },
            )
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setColor(0xFFE8A33D.toInt())
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launch ->
            builder.setContentIntent(
                PendingIntent.getActivity(
                    context, 0, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
        }
        nm.notify(id, builder.build())
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", 0)
        val title = intent.getStringExtra("title") ?: "Task deadline"
        Log.d("FocusLock", "ReminderReceiver fired id=$id title=$title")
        try {
            DeadlineReminders.notify(context, id, title, intent.getStringExtra("body") ?: "")
            Log.d("FocusLock", "Reminder notification posted id=$id")
        } catch (e: Exception) {
            Log.e("FocusLock", "Reminder notify failed", e)
        }
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            DeadlineReminders.restore(context)
        }
    }
}
