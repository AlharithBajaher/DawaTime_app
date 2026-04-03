import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pharmacy_task_model.dart';

class PharmacyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<List<PharmacyTaskModel>> watchTasks() {
    final uid = _uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('pharmacy')
        .where('pharmacistId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map(PharmacyTaskModel.fromFirestore)
              .toList(growable: false);

          tasks.sort((a, b) {
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1;
            }

            final createdA = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final createdB = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return createdB.compareTo(createdA);
          });

          return tasks;
        });
  }

  Future<void> addTask({
    required String title,
    required String details,
    required String category,
    required String priority,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user found.');
    }

    await _firestore.collection('pharmacy').add({
      'pharmacistId': uid,
      'title': title,
      'details': details,
      'category': category,
      'priority': priority,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    required String details,
    required String category,
    required String priority,
    required bool isCompleted,
  }) async {
    await _firestore.collection('pharmacy').doc(taskId).update({
      'title': title,
      'details': details,
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted,
    });
  }

  Future<void> toggleTask(PharmacyTaskModel task) async {
    await _firestore.collection('pharmacy').doc(task.id).update({
      'isCompleted': !task.isCompleted,
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('pharmacy').doc(taskId).delete();
  }
}
