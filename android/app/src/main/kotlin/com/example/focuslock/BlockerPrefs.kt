package com.example.focuslock

import android.content.Context

/**
 * Tiny native SharedPreferences wrapper used to hand the current block
 * list from [MainActivity] (driven by Flutter) over to
 * [FocusAccessibilityService], which runs independently of the Flutter
 * engine and can't receive MethodChannel calls directly.
 */
object BlockerPrefs {
    private const val PREFS_NAME = "focus_lock_blocker_prefs"
    private const val KEY_ACTIVE = "blocking_active"
    private const val KEY_PACKAGES = "blocked_packages"

    fun setBlocking(context: Context, active: Boolean, packages: List<String>) {
        prefs(context).edit()
            .putBoolean(KEY_ACTIVE, active)
            .putStringSet(KEY_PACKAGES, packages.toSet())
            .apply()
    }

    fun isActive(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ACTIVE, false)

    fun blockedPackages(context: Context): Set<String> =
        prefs(context).getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
