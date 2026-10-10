import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/distraction_app.dart';
import '../providers/auth_provider.dart';
import '../providers/blocked_apps_provider.dart';
import '../services/app_blocker_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ring_icon.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool notifications = true, streaks = true;
  final _blocker = AppBlockerService();
  bool _accessibilityEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check when the user comes back from the system Accessibility
    // settings screen, since Android gives no callback for this.
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final enabled = await _blocker.isAccessibilityServiceEnabled();
    if (mounted) setState(() => _accessibilityEnabled = enabled);
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in any time to see your tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final blocked = context.watch<BlockedAppsProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Account', style: textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const RingIcon(icon: Icons.person_outline, size: 44),
                title: Text(
                  (auth.user?.displayName?.isNotEmpty ?? false)
                      ? auth.user!.displayName!
                      : (auth.user?.email ?? 'Signed in'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: (auth.user?.displayName?.isNotEmpty ?? false)
                    ? Text(
                        auth.user?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.alert),
                title: const Text('Sign out', style: TextStyle(color: AppColors.alert)),
                onTap: _confirmSignOut,
              ),
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Focus settings', style: textTheme.titleMedium),
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Focus and task reminders'),
            value: notifications,
            onChanged: (v) => setState(() => notifications = v),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Test reminder notification'),
            subtitle: const Text('Shows one now and another in 15 seconds'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ns = NotificationService();
              await ns.requestPermission();
              await ns.sendTestReminder();
              messenger.showSnackBar(const SnackBar(
                content: Text('Sent. Lock your screen and wait 15 seconds.'),
              ));
            },
          ),
          SwitchListTile(
            title: const Text('Productivity streaks'),
            value: streaks,
            onChanged: (v) => setState(() => streaks = v),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text('Distraction apps', style: textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Selected apps are restricted during an active focus session.',
              style: textTheme.bodyMedium,
            ),
          ),
          if (!_accessibilityEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.signalDim),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.signal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Permission needed to actually block apps',
                            style: textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FocusLock only sends you back to the home screen when a '
                      'selected app opens during a session \u2014 it never reads '
                      'what\u2019s on your screen. This requires enabling '
                      'Accessibility access manually, since Android doesn\u2019t '
                      'allow apps to request it directly.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => _blocker.openAccessibilitySettings(),
                      child: const Text('Open Accessibility settings'),
                    ),
                  ],
                ),
              ),
            ),
          ...kDistractionApps.map(
            (a) => CheckboxListTile(
              secondary: Icon(a.icon, color: AppColors.ash),
              title: Text(a.label),
              value: blocked.isSelected(a),
              onChanged: blocked.isLoaded ? (_) => blocked.toggle(a) : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              _accessibilityEnabled
                  ? 'App blocking is active for your selected apps.'
                  : 'App blocking will take effect once Accessibility access is enabled above.',
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
