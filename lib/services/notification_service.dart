import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/task.dart';

/// Shows an ongoing notification with the time left in the focus session.
/// Implemented natively (see FocusNotifier.kt) so Android drives the
/// countdown itself, even while the app is in the background.
class NotificationService {
  static const _channel = MethodChannel('focus_lock/notifications');

  Future<void> initialize() async {}

  /// Android 13+ needs the user to allow notifications.
  /// Returns true if notifications are allowed (waits for the user's answer).
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } catch (e) {
      debugPrint('Notification requestPermission failed: $e');
      return false;
    }
  }

  /// Live countdown that ends [remaining] from now.
  Future<void> showFocusTimer({
    required String taskTitle,
    required Duration remaining,
  }) {
    final end = DateTime.now().add(remaining).millisecondsSinceEpoch;
    return _invoke('show', {
      'title': 'Focus mode on',
      'text': taskTitle,
      'endMillis': end,
    });
  }

  /// Static notification while the session is paused.
  Future<void> showPaused({
    required String taskTitle,
    required String timeLeft,
  }) {
    return _invoke('show', {
      'title': 'Focus paused',
      'text': taskTitle,
      'timeLeft': timeLeft,
    });
  }

  /// Replaces all scheduled deadline reminders with the ones needed for
  /// [tasks]: a start-time reminder, plus 1 hour before, 10 minutes before, and at the deadline. Only
  /// unfinished tasks with a future deadline get reminders.
  Future<void> syncDeadlineReminders(List<Task> tasks) {
    final now = DateTime.now();
    final items = <Map<String, dynamic>>[];
    for (final t in tasks) {
      if (t.completed) continue;

      // "Time to start" reminder at the task's start date/time.
      final s = t.startDate;
      if (s != null && s.isAfter(now)) {
        items.add({
          'id': _stableId(t.id, 4),
          'at': s.millisecondsSinceEpoch,
          'title': t.title,
          'body': 'Time to start. Open FocusLock and lock in!',
        });
      }

      final d = t.deadline;
      if (d == null) continue;
      final steps = [
        (const Duration(hours: 1), 'Due in 1 hour', 1),
        (const Duration(minutes: 10), 'Due in 10 minutes', 2),
        (Duration.zero, 'Deadline reached. Finish it now!', 3),
      ];
      for (final (before, body, kind) in steps) {
        final at = d.subtract(before);
        if (!at.isAfter(now)) continue;
        items.add({
          'id': _stableId(t.id, kind),
          'at': at.millisecondsSinceEpoch,
          'title': t.title,
          'body': body,
        });
      }
    }
    debugPrint('Syncing ${items.length} deadline reminders');
    return _invoke('setReminders', {'items': items});
  }

  int _stableId(String taskId, int kind) {
    var h = 2166136261;
    for (final c in taskId.codeUnits) {
      h = ((h ^ c) * 16777619) & 0x7fffffff;
    }
    return ((h ^ kind) & 0x7fffffff);
  }

  /// Posts a notification immediately and schedules another in 15 seconds.
  Future<void> sendTestReminder() => _invoke('testReminder');

  Future<void> cancelFocusTimer() => _invoke('cancel');

  Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    try {
      await _channel.invokeMethod(method, args);
    } catch (e) {
      debugPrint('Notification $method failed: $e');
    }
  }
}
