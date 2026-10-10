package com.example.focuslock

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "focus_lock/app_blocker"
    private val notifChannelName = "focus_lock/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerNotificationChannel(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startBlocking" -> {
                        @Suppress("UNCHECKED_CAST")
                        val packages = (call.argument<List<String>>("packages") ?: emptyList())
                        BlockerPrefs.setBlocking(applicationContext, true, packages)
                        result.success(null)
                    }
                    "stopBlocking" -> {
                        BlockerPrefs.setBlocking(applicationContext, false, emptyList())
                        result.success(null)
                    }
                    "isAccessibilityServiceEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private var pendingPermissionResult: MethodChannel.Result? = null

    private fun notificationsAllowed(): Boolean =
        (getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager)
            .areNotificationsEnabled()

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1001) {
            pendingPermissionResult?.success(notificationsAllowed())
            pendingPermissionResult = null
        }
    }

    private fun registerNotificationChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notifChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= 33 &&
                            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                            PackageManager.PERMISSION_GRANTED
                        ) {
                            pendingPermissionResult = result
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
                        } else {
                            result.success(notificationsAllowed())
                        }
                    }
                    "show" -> {
                        val title = call.argument<String>("title") ?: "Focus mode on"
                        val text = call.argument<String>("text") ?: ""
                        val endMillis = call.argument<Number>("endMillis")?.toLong()
                        val timeLeft = call.argument<String>("timeLeft")
                        FocusNotifier.show(applicationContext, title, text, endMillis, timeLeft)
                        result.success(null)
                    }
                    "setReminders" -> {
                        val raw = call.argument<List<Map<String, Any>>>("items") ?: emptyList()
                        val items = raw.map {
                            DeadlineReminders.Reminder(
                                (it["id"] as Number).toInt(),
                                (it["at"] as Number).toLong(),
                                it["title"] as String,
                                it["body"] as String,
                            )
                        }
                        DeadlineReminders.setAll(applicationContext, items)
                        result.success(null)
                    }
                    "testReminder" -> {
                        DeadlineReminders.notify(applicationContext, 999002,
                            "FocusLock test (now)", "Immediate test notification")
                        DeadlineReminders.scheduleTest(applicationContext, 15_000L)
                        result.success(null)
                    }
                    "cancel" -> {
                        FocusNotifier.cancel(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponent = "$packageName/${FocusAccessibilityService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false

        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        while (splitter.hasNext()) {
            if (splitter.next().equals(expectedComponent, ignoreCase = true)) return true
        }
        return false
    }
}
