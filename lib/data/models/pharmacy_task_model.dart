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
    required this.quantity,
    required this.minQuantity,
    required this.unit,
    required this.isOutOfStock,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String pharmacistId;
  final String title;
  final String details;
  final String category;
  final String priority;
  final bool isCompleted;
  final int quantity;
  final int minQuantity;
  final String unit;
  final bool isOutOfStock;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  bool get isLowStock => !isOutOfStock && quantity <= minQuantity;

  factory PharmacyTaskModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
    final minQuantity = (data['minQuantity'] as num?)?.toInt() ?? 5;
    final legacyOutOfStock = data['isCompleted'] as bool? ?? false;
    final isOutOfStock =
        data['isOutOfStock'] as bool? ?? legacyOutOfStock || quantity <= 0;

    return PharmacyTaskModel(
      id: doc.id,
      pharmacistId: data['pharmacistId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      details: data['details'] as String? ?? '',
      category: data['category'] as String? ?? 'dispense',
      priority: data['priority'] as String? ?? 'medium',
      isCompleted: legacyOutOfStock,
      quantity: quantity,
      minQuantity: minQuantity,
      unit: data['unit'] as String? ?? 'box',
      isOutOfStock: isOutOfStock,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}
