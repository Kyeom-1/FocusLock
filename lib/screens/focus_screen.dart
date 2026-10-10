import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/blocked_apps_provider.dart';
import '../providers/focus_provider.dart';
import '../services/app_blocker_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/focus_dial.dart';
import 'proof_screen.dart';

class FocusScreen extends StatefulWidget {
  final Task task;

  const FocusScreen({super.key, required this.task});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final AppBlockerService blocker = AppBlockerService();
  final NotificationService notifications = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<FocusProvider>().start(widget.task);
      final packages = context.read<BlockedAppsProvider>().selectedPackages;
      blocker.startBlocking(packages);
      final allowed = await notifications.requestPermission();
      debugPrint('Notifications allowed: $allowed');
      if (!mounted) return;
      notifications.showFocusTimer(
        taskTitle: widget.task.title,
        remaining: Duration(minutes: widget.task.durationMinutes),
      );
    });
  }

  /// The only way out of focus mode. Blocking stays on until the proof screen
  /// confirms the task is actually completed.
  Future<void> finish() async {
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finished this task?'),
        content: const Text(
          'Focus mode only ends once you complete the task. '
          'You\'ll confirm it on the next screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep focusing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, finished'),
          ),
        ],
      ),
    );
    if (done != true || !mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProofScreen(task: widget.task)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Focus mode'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: focus.timeUp ? AppColors.ash : AppColors.signal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      focus.timeUp
                          ? 'Time is up. Finish your task to unlock'
                          : 'Session in progress',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.task.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                FocusDial(
                  progress: focus.progress,
                  time: focus.formattedTime,
                  caption: 'remaining',
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 16, color: AppColors.ash),
                    const SizedBox(width: 8),
                    Text('Selected distractions are restricted', style: textTheme.bodyMedium),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: finish,
                    icon: const Icon(Icons.check),
                    label: const Text('I finished the task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
