import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/firestore_task_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirestoreTaskService _service;
  final NotificationService _notifications = NotificationService();
  StreamSubscription<List<Task>>? _sub;
  String? _uid;
  List<Task> _tasks = [];
  bool _loading = false;

  TaskProvider(this._service);

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get pendingTasks => _tasks.where((t) => !t.completed).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.completed).toList();
  bool get isLoading => _loading;

  /// Re-point this provider at a different user's tasks (or clear
  /// everything when [uid] is null, e.g. on sign-out). Safe to call
  /// repeatedly with the same uid.
  void bindToUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _sub?.cancel();
    _tasks = [];

    if (uid == null) {
      _loading = false;
      _notifications.syncDeadlineReminders(const []);
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _sub = _service.watchTasks(uid).listen((tasks) {
      _tasks = tasks;
      _loading = false;
      _notifications.syncDeadlineReminders(tasks);
      notifyListeners();
    });
  }

  Future<void> addTask(Task t) async {
    final uid = _uid;
    if (uid == null) return;
    await _service.addTask(uid, t);
  }

  Future<void> deleteTask(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await _service.deleteTask(uid, id);
  }

  Future<void> completeTask(String id, {String? proofImageUrl}) async {
    final uid = _uid;
    if (uid == null) return;
    final t = _tasks.firstWhere((x) => x.id == id);
    t.completed = true;
    t.completedAt = DateTime.now();
    t.proofImageUrl = proofImageUrl;
    await _service.updateTask(uid, t);
  }

  int get completedToday {
    final n = DateTime.now();
    return _tasks.where((t) {
      final d = t.completedAt;
      return t.completed &&
          d != null &&
          d.year == n.year &&
          d.month == n.month &&
          d.day == n.day;
    }).length;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
