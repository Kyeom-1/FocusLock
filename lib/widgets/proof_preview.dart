import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Local preview of a just-captured proof photo, shown before it's
/// uploaded to Firebase Storage. Framed with the same hairline language
/// as the rest of the app rather than a bare image.
class ProofPreview extends StatelessWidget {
  final File file;
  const ProofPreview({super.key, required this.file});

  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.hairline),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.file(file, fit: BoxFit.cover),
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.graphite.withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Text('Proof', style: Theme.of(context).textTheme.labelSmall),
          ),
        ),
      ],
    ),
  );
}
