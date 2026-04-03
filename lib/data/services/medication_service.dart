import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/medication_model.dart';
import 'notification_service.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> addMedication({
    required String name,
    required String dose,
    required String form,
    required int quantity,
    required String doseUnit,
    required String time,
    required int hour,
    required int minute,
    required int frequency,
    required List<int> notificationIds,
  }) async {
    if (_uid == null) {
      throw StateError('No authenticated user found.');
    }

    await _firestore.collection('medications').add({
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
      'notificationIds': notificationIds,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
    required List<int> notificationIds,
  }) async {
    await _firestore.collection('medications').doc(medicationId).update({
      'name': name,
      'dose': dose,
      'form': form,
      'quantity': quantity,
      'doseUnit': doseUnit,
      'time': time,
      'hour': hour,
      'minute': minute,
      'frequency': frequency,
      'notificationIds': notificationIds,
    });
  }

  Stream<List<MedicationModel>> getUserMedications() {
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
      await NotificationService.cancelNotifications(medication.notificationIds);
    }

    await _firestore.collection('medications').doc(medication.id).delete();
  }
}
