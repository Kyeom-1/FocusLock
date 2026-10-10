import 'package:flutter/material.dart';

/// A distracting app FocusLock can detect and block, by its real Android
/// package name. The accessibility service compares the foreground app's
/// package name against the user's selection of these — it never needs to
/// know the app is actually installed.
class DistractionApp {
  final String label;
  final String packageName;
  final IconData icon;

  const DistractionApp({
    required this.label,
    required this.packageName,
    required this.icon,
  });
}

const List<DistractionApp> kDistractionApps = [
  DistractionApp(
    label: 'TikTok',
    packageName: 'com.zhiliaoapp.musically',
    icon: Icons.music_note_outlined,
  ),
  DistractionApp(
    label: 'Facebook',
    packageName: 'com.facebook.katana',
    icon: Icons.groups_outlined,
  ),
  DistractionApp(
    label: 'Instagram',
    packageName: 'com.instagram.android',
    icon: Icons.camera_alt_outlined,
  ),
  DistractionApp(
    label: 'YouTube',
    packageName: 'com.google.android.youtube',
    icon: Icons.play_circle_outline,
  ),
  DistractionApp(
    label: 'Reddit',
    packageName: 'com.reddit.frontpage',
    icon: Icons.forum_outlined,
  ),
];
