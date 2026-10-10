import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A row of tappable options with a filled state for the current choice —
/// used in place of [DropdownButtonFormField] wherever there are only a
/// handful of options, so the choice is visible at a glance rather than
/// hidden behind a tap-to-reveal menu.
class SegmentedSelector<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;

  const SegmentedSelector({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = option == value;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? AppColors.signal : Colors.transparent,
              border: Border.all(
                color: selected ? AppColors.signal : AppColors.hairline,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              labelBuilder(option),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.graphite : AppColors.paper,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
