import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication_model.dart';

class MedicationService {

  final _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // إضافة دواء
  Future<void> addMedication({
    required String name,
    required String dose,
    required String time,
  }) async {

    await _firestore.collection('medications').add({
      'userId': _uid,
      'name': name,
      'dose': dose,
      'time': time,
      'createdAt': Timestamp.now(),
    });
  }

  // جلب أدوية المستخدم الحالي
  Stream<List<MedicationModel>> getUserMedications() {

    return _firestore
        .collection('medications')
        .where('userId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MedicationModel.fromFirestore(doc)).toList());
  }

  // حذف دواء
  Future<void> deleteMedication(String id) async {
    await _firestore.collection('medications').doc(id).delete();
  }
}