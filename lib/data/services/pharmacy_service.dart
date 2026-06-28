import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pharmacy_task_model.dart';
import 'notification_service.dart';

class PharmacyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> _syncInventoryAlertSafely({
    required String itemId,
    required String itemName,
    required int quantity,
    required int minQuantity,
    bool isArabic = false,
  }) async {
    try {
      await NotificationService.syncInventoryAlert(
        itemId: itemId,
        itemName: itemName,
        quantity: quantity,
        minQuantity: minQuantity,
        isArabic: isArabic,
      );
    } catch (_) {
      // Keep inventory CRUD reliable even if local alert sync fails.
    }
  }

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
            if (a.isOutOfStock != b.isOutOfStock) {
              return a.isOutOfStock ? 1 : -1;
            }

            if (a.isLowStock != b.isLowStock) {
              return a.isLowStock ? -1 : 1;
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
    required int quantity,
    required int minQuantity,
    required String unit,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated user found.');
    }

    final safeQuantity = quantity < 0 ? 0 : quantity;
    final safeMinQuantity = minQuantity < 0 ? 0 : minQuantity;

    final docRef = await _firestore.collection('pharmacy').add({
      'pharmacistId': uid,
      'title': title,
      'details': details,
      'category': category,
      'priority': priority,
      'quantity': safeQuantity,
      'minQuantity': safeMinQuantity,
      'unit': unit,
      'isOutOfStock': safeQuantity <= 0,
      'isCompleted': safeQuantity <= 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _syncInventoryAlertSafely(
      itemId: docRef.id,
      itemName: title,
      quantity: safeQuantity,
      minQuantity: safeMinQuantity,
    );
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    required String details,
    required String category,
    required String priority,
    required int quantity,
    required int minQuantity,
    required String unit,
  }) async {
    final safeQuantity = quantity < 0 ? 0 : quantity;
    final safeMinQuantity = minQuantity < 0 ? 0 : minQuantity;

    await _firestore.collection('pharmacy').doc(taskId).update({
      'title': title,
      'details': details,
      'category': category,
      'priority': priority,
      'quantity': safeQuantity,
      'minQuantity': safeMinQuantity,
      'unit': unit,
      'isOutOfStock': safeQuantity <= 0,
      'isCompleted': safeQuantity <= 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _syncInventoryAlertSafely(
      itemId: taskId,
      itemName: title,
      quantity: safeQuantity,
      minQuantity: safeMinQuantity,
    );
  }

  Future<void> toggleTask(PharmacyTaskModel task) async {
    final nextOutOfStock = !task.isOutOfStock;
    final nextQuantity = nextOutOfStock
        ? 0
        : task.quantity.clamp(1, 1000000).toInt();
    await _firestore.collection('pharmacy').doc(task.id).update({
      'isOutOfStock': nextOutOfStock,
      'isCompleted': nextOutOfStock,
      'quantity': nextQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _syncInventoryAlertSafely(
      itemId: task.id,
      itemName: task.title,
      quantity: nextQuantity,
      minQuantity: task.minQuantity,
    );
  }

  Future<void> adjustStock({
    required PharmacyTaskModel task,
    required int delta,
  }) async {
    final nextQuantity = (task.quantity + delta).clamp(0, 1000000).toInt();
    await _firestore.collection('pharmacy').doc(task.id).update({
      'quantity': nextQuantity,
      'isOutOfStock': nextQuantity <= 0,
      'isCompleted': nextQuantity <= 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _syncInventoryAlertSafely(
      itemId: task.id,
      itemName: task.title,
      quantity: nextQuantity,
      minQuantity: task.minQuantity,
    );
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await NotificationService.cancelNotification(
        NotificationService.inventoryNotificationIdForItem(taskId),
      );
    } catch (_) {
      // Keep delete flow working even if local cancel fails.
    }
    await _firestore.collection('pharmacy').doc(taskId).delete();
  }
}
