import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A hairline circular ring around a child — the same instrument-dial
/// language as [FocusDial], scaled down to mark identity: the login
/// screen's lock mark, the settings screen's account mark. One recurring
/// device instead of a generic filled avatar circle.
class RingIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const RingIcon({
    super.key,
    required this.icon,
    this.size = 64,
    this.color = AppColors.signal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairline, width: 1.5),
      ),
      child: Icon(icon, color: color, size: size * 0.42),
    );
  }
}
