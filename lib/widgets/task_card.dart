import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap, onDelete;
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  Color get _accent {
    switch (task.priority) {
      case 'High':
        return AppColors.signal;
      case 'Medium':
        return AppColors.signalDim;
      default:
        return AppColors.hairline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 5, color: _accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (task.priority == 'High') ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.signal.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'High',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: AppColors.signal,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: 4,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: AppColors.ash,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${task.durationMinutes} min',
                                    style: textTheme.bodySmall,
                                  ),
                                  if (task.startDate != null) ...[
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.play_circle_outline,
                                      size: 14,
                                      color: AppColors.ash,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      DateFormat.MMMd().add_jm().format(task.startDate!),
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                  if (task.deadline != null) ...[
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.event_outlined,
                                      size: 14,
                                      color: AppColors.ash,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      DateFormat.MMMd().add_jm().format(task.deadline!),
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.ash,
                          tooltip: 'Delete task',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
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