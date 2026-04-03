import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyTaskModel {
  const PharmacyTaskModel({
    required this.id,
    required this.pharmacistId,
    required this.title,
    required this.details,
    required this.category,
    required this.priority,
    required this.isCompleted,
    this.createdAt,
  });

  final String id;
  final String pharmacistId;
  final String title;
  final String details;
  final String category;
  final String priority;
  final bool isCompleted;
  final Timestamp? createdAt;

  factory PharmacyTaskModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};

    return PharmacyTaskModel(
      id: doc.id,
      pharmacistId: data['pharmacistId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      details: data['details'] as String? ?? '',
      category: data['category'] as String? ?? 'dispense',
      priority: data['priority'] as String? ?? 'medium',
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
