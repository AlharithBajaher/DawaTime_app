import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/medication_model.dart';
import 'notification_service.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<String> addMedication({
    required String name,
    required String dose,
    required String form,
    required int quantity,
    required String doseUnit,
    required String time,
    required int hour,
    required int minute,
    required int frequency,
    required List<MedicationDoseTime> doseTimes,
    required int intervalDays,
    required List<int> notificationIds,
    required int remainingQuantity,
  }) async {
    if (_uid == null) {
      throw StateError('No authenticated user found.');
    }

    final docRef = await _firestore.collection('medications').add({
      'userId': _uid,
      'name': name,
      'dose': dose,
      'form': form,
      'quantity': quantity,
      'doseUnit': doseUnit,
      'time': time,
      'hour': hour,
      'minute': minute,
      'frequency': frequency,
      'doseTimes': doseTimes.map((doseTime) => doseTime.toMap()).toList(),
      'intervalDays': intervalDays,
      'notificationIds': notificationIds,
      'remainingQuantity': remainingQuantity,
      'isArchived': false,
      'archivedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> updateMedication({
    required String medicationId,
    required String name,
    required String dose,
    required String form,
    required int quantity,
    required String doseUnit,
    required String time,
    required int hour,
    required int minute,
    required int frequency,
    required List<MedicationDoseTime> doseTimes,
    required int intervalDays,
    required List<int> notificationIds,
    required int remainingQuantity,
  }) async {
    final docRef = _firestore.collection('medications').doc(medicationId);
    await docRef.set({
      'name': name,
      'dose': dose,
      'form': form,
      'quantity': quantity,
      'doseUnit': doseUnit,
      'time': time,
      'hour': hour,
      'minute': minute,
      'frequency': frequency,
      'doseTimes': doseTimes.map((doseTime) => doseTime.toMap()).toList(),
      'intervalDays': intervalDays,
      'notificationIds': notificationIds,
      'remainingQuantity': remainingQuantity,
      'isArchived': false,
      'archivedAt': null,
    }, SetOptions(merge: true));
  }

  Stream<List<MedicationModel>> getUserMedications({
    bool includeArchived = false,
  }) {
    if (_uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('medications')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
          final medications = snapshot.docs
              .map((doc) => MedicationModel.fromFirestore(doc))
              .where((medication) => includeArchived || !medication.isArchived)
              .toList(growable: false);

          medications.sort((a, b) {
            final createdA = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final createdB = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return createdB.compareTo(createdA);
          });

          return medications;
        });
  }

  Future<void> deleteMedication(MedicationModel medication) async {
    if (medication.notificationIds.isNotEmpty) {
      try {
        await NotificationService.cancelNotifications(
          medication.notificationIds,
        );
      } catch (_) {
        // Continue deleting even if local notifications cannot be cancelled.
      }
    }
    try {
      await NotificationService.cancelNotification(
        NotificationService.lowStockNotificationIdForMedication(medication.id),
      );
    } catch (_) {
      // Continue deleting even if low-stock reminder cannot be cancelled.
    }

    await _firestore.collection('medications').doc(medication.id).delete();
  }

  Future<DoseTakeResult> markDoseAsTaken({
    required MedicationModel medication,
    required DateTime scheduledAt,
    DateTime? takenAt,
  }) async {
    final takenTime = (takenAt ?? DateTime.now()).toLocal();
    final key = MedicationModel.doseLogKeyFor(scheduledAt);
    final docRef = _firestore.collection('medications').doc(medication.id);
    final takenDoseLogs = Map<String, dynamic>.fromEntries(
      medication.takenDoseLogs.entries.map(
        (entry) => MapEntry<String, dynamic>(
          entry.key,
          Timestamp.fromDate(entry.value),
        ),
      ),
    );
    final skippedDoseLogs = Map<String, dynamic>.fromEntries(
      medication.skippedDoseLogs.entries.map(
        (entry) => MapEntry<String, dynamic>(
          entry.key,
          Timestamp.fromDate(entry.value),
        ),
      ),
    );
    final currentRemaining = medication.remainingQuantity;

    final DoseTakeResult result;
    if (takenDoseLogs.containsKey(key)) {
      result = DoseTakeResult(
        archivedMedication: currentRemaining <= 0,
        remainingQuantity: currentRemaining,
      );
    } else {
      final nextRemaining = (currentRemaining - 1).clamp(0, 1000000).toInt();
      final shouldArchive = nextRemaining <= 0;
      final nextTakenLogs = Map<String, dynamic>.from(takenDoseLogs)
        ..[key] = Timestamp.fromDate(takenTime);
      final nextSkippedLogs = Map<String, dynamic>.from(skippedDoseLogs)
        ..remove(key);
      await docRef.set({
        'takenDoseLogs': nextTakenLogs,
        'skippedDoseLogs': nextSkippedLogs,
        'remainingQuantity': shouldArchive ? 0 : nextRemaining,
        'isArchived': shouldArchive,
        'archivedAt': shouldArchive ? Timestamp.fromDate(takenTime) : null,
      }, SetOptions(merge: true));
      result = DoseTakeResult(
        archivedMedication: shouldArchive,
        remainingQuantity: shouldArchive ? 0 : nextRemaining,
      );
    }

    if (result.archivedMedication) {
      if (medication.notificationIds.isNotEmpty) {
        try {
          await NotificationService.cancelNotifications(
            medication.notificationIds,
          );
        } catch (_) {}
      }
      try {
        await NotificationService.cancelNotification(
          NotificationService.lowStockNotificationIdForMedication(
            medication.id,
          ),
        );
      } catch (_) {}
    }

    return result;
  }

  Future<void> markDoseAsSkipped({
    required MedicationModel medication,
    required DateTime scheduledAt,
    DateTime? skippedAt,
  }) async {
    final skippedTime = (skippedAt ?? DateTime.now()).toLocal();
    final key = MedicationModel.doseLogKeyFor(scheduledAt);
    final docRef = _firestore.collection('medications').doc(medication.id);
    final nextSkippedLogs = Map<String, dynamic>.fromEntries(
      medication.skippedDoseLogs.entries.map(
        (entry) => MapEntry<String, dynamic>(
          entry.key,
          Timestamp.fromDate(entry.value),
        ),
      ),
    )..[key] = Timestamp.fromDate(skippedTime);
    final nextTakenLogs = Map<String, dynamic>.fromEntries(
      medication.takenDoseLogs.entries.map(
        (entry) => MapEntry<String, dynamic>(
          entry.key,
          Timestamp.fromDate(entry.value),
        ),
      ),
    )..remove(key);
    await docRef.set({
      'skippedDoseLogs': nextSkippedLogs,
      'takenDoseLogs': nextTakenLogs,
    }, SetOptions(merge: true));
  }

  Future<void> clearTakenDose({
    required MedicationModel medication,
    required DateTime scheduledAt,
  }) async {
    final key = MedicationModel.doseLogKeyFor(scheduledAt);
    await _firestore.collection('medications').doc(medication.id).update({
      'takenDoseLogs.$key': FieldValue.delete(),
    });
  }

  Future<void> clearSkippedDose({
    required MedicationModel medication,
    required DateTime scheduledAt,
  }) async {
    final key = MedicationModel.doseLogKeyFor(scheduledAt);
    await _firestore.collection('medications').doc(medication.id).update({
      'skippedDoseLogs.$key': FieldValue.delete(),
    });
  }

  Future<void> replaceNotificationIds({
    required String medicationId,
    required List<int> notificationIds,
  }) async {
    await _firestore.collection('medications').doc(medicationId).set({
      'notificationIds': notificationIds,
    }, SetOptions(merge: true));
  }
}

class DoseTakeResult {
  const DoseTakeResult({
    required this.archivedMedication,
    required this.remainingQuantity,
  });

  final bool archivedMedication;
  final int remainingQuantity;
}
