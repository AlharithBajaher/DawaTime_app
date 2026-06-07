import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/medication_model.dart';
import 'notification_service.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _medicationsCollectionName = 'medications';
  static const String _medicationReportsCollectionName = 'medication_reports';

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _medicationsCollection =>
      _firestore.collection(_medicationsCollectionName);

  CollectionReference<Map<String, dynamic>> get _medicationReportsCollection =>
      _firestore.collection(_medicationReportsCollectionName);

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

    final docRef = await _medicationsCollection.add({
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

    await _medicationReportsCollection.doc(docRef.id).set({
      'userId': _uid,
      'sourceMedicationId': docRef.id,
      'name': name,
      'dose': dose,
      'form': form,
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
      'doseUnit': doseUnit,
      'time': time,
      'hour': hour,
      'minute': minute,
      'frequency': frequency,
      'doseTimes': doseTimes.map((doseTime) => doseTime.toMap()).toList(),
      'intervalDays': intervalDays,
      'notificationIds': notificationIds,
      'takenDoseLogs': const <String, dynamic>{},
      'skippedDoseLogs': const <String, dynamic>{},
      'isArchived': false,
      'archivedAt': null,
      'isDeleted': false,
      'deletedAt': null,
      'deletedReason': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

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
    final docRef = _medicationsCollection.doc(medicationId);
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

    final uid = _uid;
    if (uid != null) {
      await _medicationReportsCollection.doc(medicationId).set({
        'userId': uid,
        'sourceMedicationId': medicationId,
        'name': name,
        'dose': dose,
        'form': form,
        'quantity': quantity,
        'remainingQuantity': remainingQuantity,
        'doseUnit': doseUnit,
        'time': time,
        'hour': hour,
        'minute': minute,
        'frequency': frequency,
        'doseTimes': doseTimes.map((doseTime) => doseTime.toMap()).toList(),
        'intervalDays': intervalDays,
        'notificationIds': notificationIds,
        'isArchived': false,
        'archivedAt': null,
        'isDeleted': false,
        'deletedAt': null,
        'deletedReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Stream<List<MedicationModel>> getUserMedications({
    bool includeArchived = false,
  }) {
    if (_uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection(_medicationsCollectionName)
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

  Stream<List<MedicationModel>> getUserMedicationReports() {
    if (_uid == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection(_medicationReportsCollectionName)
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
          final medications = snapshot.docs
              .map((doc) => MedicationModel.fromFirestore(doc))
              .toList(growable: false);

          medications.sort((a, b) {
            final createdA = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final createdB = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return createdB.compareTo(createdA);
          });

          return medications;
        });
  }

  Future<void> syncMedicationReportFromMedication(
    MedicationModel medication,
  ) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    await _upsertMedicationReport(
      medicationId: medication.id,
      userId: uid,
      payload: _buildReportPayloadFromMedication(
        medication: medication,
        isDeleted: false,
      ),
    );
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

    final uid = _uid;
    if (uid != null) {
      await _upsertMedicationReport(
        medicationId: medication.id,
        userId: uid,
        payload: _buildReportPayloadFromMedication(
          medication: medication,
          isDeleted: true,
          deletedReason: 'deleted_by_user',
          deletedAt: DateTime.now().toLocal(),
        ),
      );
    }

    await _medicationsCollection.doc(medication.id).delete();
  }

  Future<DoseTakeResult> markDoseAsTaken({
    required MedicationModel medication,
    required DateTime scheduledAt,
    DateTime? takenAt,
  }) async {
    final takenTime = (takenAt ?? DateTime.now()).toLocal();
    final key = MedicationModel.doseLogKeyFor(scheduledAt);
    final docRef = _medicationsCollection.doc(medication.id);
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
      final uid = _uid;
      if (uid != null) {
        await _upsertMedicationReport(
          medicationId: medication.id,
          userId: uid,
          payload: _buildReportPayloadFromMedication(
            medication: medication,
            takenDoseLogs: nextTakenLogs,
            skippedDoseLogs: nextSkippedLogs,
            remainingQuantity: shouldArchive ? 0 : nextRemaining,
            isArchived: shouldArchive,
            archivedAt: shouldArchive ? takenTime : null,
            isDeleted: shouldArchive,
            deletedReason: shouldArchive ? 'out_of_stock' : null,
            deletedAt: shouldArchive ? takenTime : null,
          ),
        );
      }

      if (shouldArchive) {
        await docRef.delete();
      } else {
        await docRef.set({
          'takenDoseLogs': nextTakenLogs,
          'skippedDoseLogs': nextSkippedLogs,
          'remainingQuantity': nextRemaining,
          'isArchived': false,
          'archivedAt': null,
        }, SetOptions(merge: true));
      }
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
    final docRef = _medicationsCollection.doc(medication.id);
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

    final uid = _uid;
    if (uid != null) {
      await _upsertMedicationReport(
        medicationId: medication.id,
        userId: uid,
        payload: _buildReportPayloadFromMedication(
          medication: medication,
          takenDoseLogs: nextTakenLogs,
          skippedDoseLogs: nextSkippedLogs,
        ),
      );
    }
  }

  Future<void> clearTakenDose({
    required MedicationModel medication,
    required DateTime scheduledAt,
  }) async {
    final key = MedicationModel.doseLogKeyFor(scheduledAt);
    await _medicationsCollection.doc(medication.id).update({
      'takenDoseLogs.$key': FieldValue.delete(),
    });

    final nextTakenLogs = Map<String, dynamic>.fromEntries(
      medication.takenDoseLogs.entries
          .where((entry) => entry.key != key)
          .map(
            (entry) => MapEntry<String, dynamic>(
              entry.key,
              Timestamp.fromDate(entry.value),
            ),
          ),
    );
    final uid = _uid;
    if (uid != null) {
      await _upsertMedicationReport(
        medicationId: medication.id,
        userId: uid,
        payload: _buildReportPayloadFromMedication(
          medication: medication,
          takenDoseLogs: nextTakenLogs,
        ),
      );
    }
  }

  Future<void> clearSkippedDose({
    required MedicationModel medication,
    required DateTime scheduledAt,
  }) async {
    final key = MedicationModel.doseLogKeyFor(scheduledAt);
    await _medicationsCollection.doc(medication.id).update({
      'skippedDoseLogs.$key': FieldValue.delete(),
    });

    final nextSkippedLogs = Map<String, dynamic>.fromEntries(
      medication.skippedDoseLogs.entries
          .where((entry) => entry.key != key)
          .map(
            (entry) => MapEntry<String, dynamic>(
              entry.key,
              Timestamp.fromDate(entry.value),
            ),
          ),
    );
    final uid = _uid;
    if (uid != null) {
      await _upsertMedicationReport(
        medicationId: medication.id,
        userId: uid,
        payload: _buildReportPayloadFromMedication(
          medication: medication,
          skippedDoseLogs: nextSkippedLogs,
        ),
      );
    }
  }

  Future<void> replaceNotificationIds({
    required String medicationId,
    required List<int> notificationIds,
  }) async {
    await _medicationsCollection.doc(medicationId).set({
      'notificationIds': notificationIds,
    }, SetOptions(merge: true));
    await _medicationReportsCollection.doc(medicationId).set({
      'notificationIds': notificationIds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _upsertMedicationReport({
    required String medicationId,
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    await _medicationReportsCollection.doc(medicationId).set({
      'userId': userId,
      'sourceMedicationId': medicationId,
      ...payload,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Map<String, dynamic> _buildReportPayloadFromMedication({
    required MedicationModel medication,
    Map<String, dynamic>? takenDoseLogs,
    Map<String, dynamic>? skippedDoseLogs,
    int? remainingQuantity,
    bool? isArchived,
    DateTime? archivedAt,
    bool? isDeleted,
    String? deletedReason,
    DateTime? deletedAt,
  }) {
    final mappedTakenLogs =
        takenDoseLogs ??
        Map<String, dynamic>.fromEntries(
          medication.takenDoseLogs.entries.map(
            (entry) => MapEntry<String, dynamic>(
              entry.key,
              Timestamp.fromDate(entry.value),
            ),
          ),
        );
    final mappedSkippedLogs =
        skippedDoseLogs ??
        Map<String, dynamic>.fromEntries(
          medication.skippedDoseLogs.entries.map(
            (entry) => MapEntry<String, dynamic>(
              entry.key,
              Timestamp.fromDate(entry.value),
            ),
          ),
        );

    return {
      'name': medication.name,
      'dose': medication.dose,
      'form': medication.form,
      'quantity': medication.quantity,
      'remainingQuantity': remainingQuantity ?? medication.remainingQuantity,
      'doseUnit': medication.doseUnit,
      'time': medication.time,
      'hour': medication.hour,
      'minute': medication.minute,
      'frequency': medication.frequency,
      'doseTimes': medication.doseTimes
          .map((doseTime) => doseTime.toMap())
          .toList(growable: false),
      'intervalDays': medication.intervalDays,
      'notificationIds': medication.notificationIds,
      'takenDoseLogs': mappedTakenLogs,
      'skippedDoseLogs': mappedSkippedLogs,
      'isArchived': isArchived ?? medication.isArchived,
      'archivedAt': archivedAt == null ? medication.archivedAt : Timestamp.fromDate(archivedAt),
      'isDeleted': isDeleted ?? false,
      'deletedReason': deletedReason,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt),
      'createdAt': medication.createdAt ?? FieldValue.serverTimestamp(),
    };
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
