import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The focus countdown, drawn as an instrument gauge rather than a stock
/// [CircularProgressIndicator]: a 270° arc open at the bottom, tick marks
/// along it, and the time remaining in tabular figures at the center.
class FocusDial extends StatelessWidget {
  final double progress; // 0 (just started) .. 1 (finished)
  final String time;
  final String caption;
  final double size;

  const FocusDial({
    super.key,
    required this.progress,
    required this.time,
    required this.caption,
    this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DialPainter(progress: progress.clamp(0.0, 1.0)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: size * 0.19,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                caption,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  _DialPainter({required this.progress});

  static const double _startAngle = 0.75 * math.pi; // 135°, bottom-left
  static const double _sweep = 1.5 * math.pi; // 270°, gap at the bottom

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 14;

    final track = Paint()
      ..color = AppColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = AppColors.signal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, _startAngle, _sweep, false, track);
    if (progress > 0) {
      canvas.drawArc(rect, _startAngle, _sweep * progress, false, fill);
    }

    // Tick marks every 10% around the sweep.
    final tickPaint = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1.5;
    for (var i = 0; i <= 10; i++) {
      final angle = _startAngle + _sweep * (i / 10);
      final outer = Offset(
        center.dx + (radius + 10) * math.cos(angle),
        center.dy + (radius + 10) * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (radius + 2) * math.cos(angle),
        center.dy + (radius + 2) * math.sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
