package com.example.focuslock

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast

/**
 * Watches for window changes and, whenever blocking is active and the app
 * that just came to the foreground is on the blocked list, sends the user
 * back to the home screen.
 *
 * This only works once the user has manually enabled "FocusLock" under
 * Settings > Accessibility — Android does not allow this permission to be
 * requested through a normal in-app dialog, so [MainActivity] exposes a
 * method to open that settings screen directly instead.
 */
class FocusAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName = event?.packageName?.toString() ?: return
        if (packageName == applicationContext.packageName) return

        if (BlockerPrefs.isActive(this) &&
            BlockerPrefs.blockedPackages(this).contains(packageName)
        ) {
            performGlobalAction(GLOBAL_ACTION_HOME)
            Toast.makeText(
                this,
                "That app is restricted during your focus session",
                Toast.LENGTH_SHORT,
            ).show()
        }
    }

    override fun onInterrupt() {}
}
