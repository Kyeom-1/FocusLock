import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/distraction_app.dart';

/// The user's chosen set of distracting apps to restrict during a focus
/// session, persisted locally (this is a per-device preference, not
/// per-account data, so it stays in shared_preferences rather than
/// Firestore).
class BlockedAppsProvider extends ChangeNotifier {
  static const _prefsKey = 'blocked_package_names';

  Set<String> _selectedPackages = {};
  bool _loaded = false;

  BlockedAppsProvider() {
    _load();
  }

  bool get isLoaded => _loaded;

  /// Package names currently selected for blocking.
  List<String> get selectedPackages => _selectedPackages.toList();

  bool isSelected(DistractionApp app) => _selectedPackages.contains(app.packageName);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedPackages = (prefs.getStringList(_prefsKey) ?? const [
      'com.zhiliaoapp.musically',
      'com.facebook.katana',
      'com.instagram.android',
    ]).toSet();
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(DistractionApp app) async {
    if (_selectedPackages.contains(app.packageName)) {
      _selectedPackages.remove(app.packageName);
    } else {
      _selectedPackages.add(app.packageName);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _selectedPackages.toList());
  }
}
