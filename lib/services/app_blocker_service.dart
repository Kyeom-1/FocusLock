import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppBlockerService {
  static const _channel = MethodChannel('focus_lock/app_blocker');

  /// Regional TikTok builds use different package names.
  static const _aliases = {
    'com.zhiliaoapp.musically': [
      'com.ss.android.ugc.trill',
      'com.zhiliaoapp.musically.go',
    ],
  };

  /// Tells the native AccessibilityService which packages to send the user
  /// home from while a focus session is active. No-ops (silently) if the
  /// user hasn't granted the Accessibility permission yet.
  Future<void> startBlocking(List<String> packages) async {
    final expanded = {
      ...packages,
      for (final p in packages) ...?_aliases[p],
    }.toList();
    try {
      await _channel.invokeMethod('startBlocking', {'packages': expanded});
    } on PlatformException catch (e) {
      debugPrint('startBlocking failed: $e');
    }
  }

  Future<void> stopBlocking() async {
    try {
      await _channel.invokeMethod('stopBlocking');
    } on PlatformException catch (e) {
      debugPrint('stopBlocking failed: $e');
    }
  }

  /// Whether the user has enabled FocusLock's Accessibility Service. Real
  /// app blocking only happens when this is true.
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens Settings > Accessibility. Android does not allow this
  /// permission to be requested through a normal in-app dialog.
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      debugPrint('openAccessibilitySettings failed: $e');
    }
  }
}