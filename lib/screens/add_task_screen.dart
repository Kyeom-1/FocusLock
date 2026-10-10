import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';
import '../widgets/segmented_selector.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final keyForm = GlobalKey<FormState>();
  final title = TextEditingController();
  final desc = TextEditingController();
  String priority = 'Medium', verification = 'Photo';
  int duration = 25;
  DateTime? startDate;
  DateTime? deadline;

  static const durations = [5, 10, 15, 25, 30, 45, 60, 90];

  @override
  void dispose() {
    title.dispose();
    desc.dispose();
    super.dispose();
  }

  Future<void> pickStart() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: startDate ?? now,
    );
    if (d == null || !mounted) return;

    final t = await showTimePicker(
      context: context,
      initialTime: startDate != null
          ? TimeOfDay.fromDateTime(startDate!)
          : TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30))),
      helpText: 'Start time',
    );
    if (t == null || !mounted) return;

    final picked = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    if (picked.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a start time in the future.')),
      );
      return;
    }
    if (deadline != null && !picked.isBefore(deadline!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start must be before the deadline.')),
      );
      return;
    }
    setState(() => startDate = picked);
  }

  Future<void> pickDeadline() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: deadline ?? now,
    );
    if (d == null || !mounted) return;

    final t = await showTimePicker(
      context: context,
      initialTime: deadline != null
          ? TimeOfDay.fromDateTime(deadline!)
          : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      helpText: 'Deadline time',
    );
    if (t == null || !mounted) return;

    final picked = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    if (picked.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a deadline time in the future.')),
      );
      return;
    }
    if (startDate != null && !picked.isAfter(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deadline must be after the start.')),
      );
      return;
    }
    setState(() => deadline = picked);
  }

  Future<void> save() async {
    if (!keyForm.currentState!.validate()) return;
    if (deadline != null || startDate != null) {
      // Needed on Android 13+ so start/deadline reminders can show up.
      await NotificationService().requestPermission();
    }
    if (!mounted) return;
    await context.read<TaskProvider>().addTask(
      Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.text.trim(),
        description: desc.text.trim(),
        priority: priority,
        durationMinutes: duration,
        startDate: startDate,
        deadline: deadline,
        verificationType: verification,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create task')),
    body: Form(
      key: keyForm,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Task title'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a task' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: desc,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 28),
          _sectionLabel('Priority'),
          SegmentedSelector<String>(
            options: const ['Low', 'Medium', 'High'],
            value: priority,
            labelBuilder: (v) => v,
            onChanged: (v) => setState(() => priority = v),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Focus duration'),
          SegmentedSelector<int>(
            options: durations,
            value: duration,
            labelBuilder: (v) => '$v min',
            onChanged: (v) => setState(() => duration = v),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Completion verification'),
          SegmentedSelector<String>(
            options: const ['Photo', 'Timer', 'Manual'],
            value: verification,
            labelBuilder: (v) => v,
            onChanged: (v) => setState(() => verification = v),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pickStart,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: Text(
                    startDate == null
                        ? 'Set a start (date & time)'
                        : 'Starts ${DateFormat.yMMMd().add_jm().format(startDate!)}',
                  ),
                ),
              ),
              if (startDate != null)
                IconButton(
                  onPressed: () => setState(() => startDate = null),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear start',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pickDeadline,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(
                    deadline == null
                        ? 'Set a deadline (date & time)'
                        : DateFormat.yMMMd().add_jm().format(deadline!),
                  ),
                ),
              ),
              if (deadline != null)
                IconButton(
                  onPressed: () => setState(() => deadline = null),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear deadline',
                ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: save,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Create task'),
            ),
          ),
        ],
      ),
    ),
  );
}
