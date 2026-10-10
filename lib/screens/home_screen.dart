import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_card.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';
import 'focus_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, String title, VoidCallback onConfirmed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"$title" will be removed. This can\u2019t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('FocusLock', style: textTheme.headlineSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              children: [
                ProgressCard(completed: p.completedToday, total: p.tasks.length),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text('My tasks', style: textTheme.titleLarge),
                    const Spacer(),
                    Text('${p.pendingTasks.length} remaining', style: textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 12),
                if (p.pendingTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        const Icon(Icons.task_alt, size: 40, color: AppColors.ash),
                        const SizedBox(height: 14),
                        Text(
                          'Nothing queued up. Add a task to lock in.',
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...p.pendingTasks.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(
                        task: t,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FocusScreen(task: t)),
                        ),
                        onDelete: () => _confirmDelete(
                          context,
                          t.title,
                          () => p.deleteTask(t.id),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTaskScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
    );
  }
}
