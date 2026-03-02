import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationModel {
  final String id;
  final String userId;
  final String name;
  final String dose;
  final String time;
  final Timestamp createdAt;

  MedicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dose,
    required this.time,
    required this.createdAt,
  });

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MedicationModel(
      id: doc.id,
      userId: data['userId'],
      name: data['name'],
      dose: data['dose'],
      time: data['time'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dose': dose,
      'time': time,
      'createdAt': createdAt,
    };
  }
}