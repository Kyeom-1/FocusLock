import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

/// Reads and writes tasks under `users/{uid}/tasks/{taskId}` so every
/// user's data is private to their own account.
class FirestoreTaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksRef(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  Stream<List<Task>> watchTasks(String uid) {
    return _tasksRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Task.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addTask(String uid, Task task) =>
      _tasksRef(uid).doc(task.id).set(task.toMap());

  Future<void> updateTask(String uid, Task task) =>
      _tasksRef(uid).doc(task.id).update(task.toMap());

  Future<void> deleteTask(String uid, String taskId) =>
      _tasksRef(uid).doc(taskId).delete();
}
