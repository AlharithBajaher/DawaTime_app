import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/medication_model.dart';
import 'notification_service.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  static const List<String> _allowedMedicationKeys = <String>[
    'userId',
    'name',
    'dose',
    'form',
    'quantity',
    'remainingQuantity',
    'doseUnit',
    'time',
    'hour',
    'minute',
    'frequency',
    'doseTimes',
    'intervalDays',
    'notificationIds',
    'takenDoseLogs',
    'skippedDoseLogs',
    'isArchived',
    'archivedAt',
    'createdAt',
  ];

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
        await NotificationService.cancelNotifications(medication.notificationIds);
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
    DoseTakeResult result;
    try {
      result = await _firestore.runTransaction<DoseTakeResult>((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return const DoseTakeResult(
            archivedMedication: true,
            remainingQuantity: 0,
          );
        }

        final data = snapshot.data() ?? const <String, dynamic>{};
        final takenDoseLogs = Map<String, dynamic>.from(
          data['takenDoseLogs'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
        final currentRemaining =
            (data['remainingQuantity'] as num?)?.toInt() ??
            (data['quantity'] as num?)?.toInt() ??
            0;

        if (takenDoseLogs.containsKey(key)) {
          return DoseTakeResult(
            archivedMedication: false,
            remainingQuantity: currentRemaining,
          );
        }

        final nextRemaining = (currentRemaining - 1).clamp(0, 1000000).toInt();
        final shouldArchive = nextRemaining <= 0;
        final base = _sanitizeMedicationData(data);
        final nextTakenLogs = Map<String, dynamic>.from(
          base['takenDoseLogs'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
        final nextSkippedLogs = Map<String, dynamic>.from(
          base['skippedDoseLogs'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
        nextTakenLogs[key] = Timestamp.fromDate(takenTime);
        nextSkippedLogs.remove(key);

        base['takenDoseLogs'] = nextTakenLogs;
        base['skippedDoseLogs'] = nextSkippedLogs;
        base['remainingQuantity'] = shouldArchive ? 0 : nextRemaining;
        base['isArchived'] = shouldArchive;
        base['archivedAt'] = shouldArchive ? Timestamp.fromDate(takenTime) : null;

        transaction.set(docRef, base);

        return DoseTakeResult(
          archivedMedication: shouldArchive,
          remainingQuantity: shouldArchive ? 0 : nextRemaining,
        );
      });
    } catch (_) {
      if (medication.isDoseTaken(scheduledAt)) {
        result = DoseTakeResult(
          archivedMedication: medication.remainingQuantity <= 0,
          remainingQuantity: medication.remainingQuantity,
        );
      } else {
        final nextRemaining = (medication.remainingQuantity - 1)
            .clamp(0, medication.quantity)
            .toInt();
        final shouldArchive = nextRemaining <= 0;
        await docRef.set({
          'takenDoseLogs.$key': Timestamp.fromDate(takenTime),
          'skippedDoseLogs.$key': FieldValue.delete(),
          'remainingQuantity': shouldArchive ? 0 : nextRemaining,
          'isArchived': shouldArchive,
          'archivedAt': shouldArchive ? Timestamp.fromDate(takenTime) : null,
        }, SetOptions(merge: true));
        result = DoseTakeResult(
          archivedMedication: shouldArchive,
          remainingQuantity: shouldArchive ? 0 : nextRemaining,
        );
      }
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
          NotificationService.lowStockNotificationIdForMedication(medication.id),
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
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return;
        }

        final base = _sanitizeMedicationData(snapshot.data() ?? const <String, dynamic>{});
        final nextTakenLogs = Map<String, dynamic>.from(
          base['takenDoseLogs'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
        final nextSkippedLogs = Map<String, dynamic>.from(
          base['skippedDoseLogs'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        );
        nextTakenLogs.remove(key);
        nextSkippedLogs[key] = Timestamp.fromDate(skippedTime);
        base['takenDoseLogs'] = nextTakenLogs;
        base['skippedDoseLogs'] = nextSkippedLogs;
        transaction.set(docRef, base);
      });
    } catch (_) {
      await docRef.set({
        'skippedDoseLogs.$key': Timestamp.fromDate(skippedTime),
        'takenDoseLogs.$key': FieldValue.delete(),
      }, SetOptions(merge: true));
    }
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

  Map<String, dynamic> _sanitizeMedicationData(Map<String, dynamic> data) {
    final userId = (data['userId'] as String?) ?? (_uid ?? '');
    final name = (data['name'] as String?) ?? '';
    final dose = (data['dose'] as String?) ?? '';
    final form = (data['form'] as String?) ?? 'tablet';
    final quantity = ((data['quantity'] as num?)?.toInt() ?? 1).clamp(0, 1000000);
    final remainingQuantity = ((data['remainingQuantity'] as num?)?.toInt() ?? quantity)
        .clamp(0, quantity);
    final doseUnit = (data['doseUnit'] as String?) ?? 'tablet';
    final hour = ((data['hour'] as num?)?.toInt() ?? 9).clamp(0, 23);
    final minute = ((data['minute'] as num?)?.toInt() ?? 0).clamp(0, 59);
    final doseTimes = data['doseTimes'] is List
        ? (data['doseTimes'] as List)
              .whereType<Map>()
              .map((item) {
                final map = Map<String, dynamic>.from(item);
                return <String, int>{
                  'hour': ((map['hour'] as num?)?.toInt() ?? hour).clamp(0, 23),
                  'minute': ((map['minute'] as num?)?.toInt() ?? minute).clamp(0, 59),
                };
              })
              .toList(growable: false)
        : <Map<String, int>>[];
    final safeDoseTimes = doseTimes.isNotEmpty
        ? doseTimes
        : <Map<String, int>>[
            <String, int>{'hour': hour, 'minute': minute},
          ];
    final frequency =
        ((data['frequency'] as num?)?.toInt() ?? safeDoseTimes.length)
            .clamp(1, 24);
    final intervalDays = ((data['intervalDays'] as num?)?.toInt() ?? 1)
        .clamp(1, 365);
    final notificationIds = (data['notificationIds'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<num>()
        .map((id) => id.toInt())
        .toList(growable: false);
    final takenDoseLogs = Map<String, dynamic>.from(
      data['takenDoseLogs'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    final skippedDoseLogs = Map<String, dynamic>.from(
      data['skippedDoseLogs'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

    final sanitized = <String, dynamic>{
      'userId': userId,
      'name': name,
      'dose': dose,
      'form': form,
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
      'doseUnit': doseUnit,
      'time': (data['time'] as String?) ?? _formatLegacyTime(hour, minute),
      'hour': hour,
      'minute': minute,
      'frequency': frequency,
      'doseTimes': safeDoseTimes,
      'intervalDays': intervalDays,
      'notificationIds': notificationIds,
      'takenDoseLogs': takenDoseLogs,
      'skippedDoseLogs': skippedDoseLogs,
      'isArchived': data['isArchived'] as bool? ?? false,
      'archivedAt': data['archivedAt'],
      'createdAt': data['createdAt'],
    };

    return Map<String, dynamic>.fromEntries(
      sanitized.entries.where((entry) => _allowedMedicationKeys.contains(entry.key)),
    );
  }

  String _formatLegacyTime(int hour, int minute) {
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'PM' : 'AM';
    final minuteLabel = minute.toString().padLeft(2, '0');
    return '$normalizedHour:$minuteLabel $period';
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
