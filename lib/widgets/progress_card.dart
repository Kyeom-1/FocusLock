import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Today's progress, shown as one segment per task rather than a smooth
/// bar — so "3 of 5" is something you can actually count, not just read.
/// Falls back to a plain hairline bar once there are too many segments to
/// read individually.
class ProgressCard extends StatelessWidget {
  final int completed, total;
  const ProgressCard({super.key, required this.completed, required this.total});

  static const int _maxSegments = 14;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Today', style: textTheme.titleLarge),
              const Spacer(),
              Text(
                '$completed',
                style: textTheme.headlineMedium?.copyWith(color: AppColors.signal),
              ),
              Text(' / $total tasks', style: textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Text(
              'Add a task to start today\u2019s run.',
              style: textTheme.bodyMedium,
            )
          else if (total <= _maxSegments)
            Row(
              children: List.generate(total, (i) {
                final done = i < completed;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                    height: 10,
                    decoration: BoxDecoration(
                      color: done ? AppColors.signal : Colors.transparent,
                      border: Border.all(
                        color: done ? AppColors.signal : AppColors.hairline,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (completed / total).clamp(0.0, 1.0),
                minHeight: 10,
              ),
            ),
        ],
      ),
    );
  }
}
