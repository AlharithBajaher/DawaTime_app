import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyRatingModel {
  const PharmacyRatingModel({
    required this.id,
    required this.pharmacistId,
    required this.patientId,
    required this.patientName,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String pharmacistId;
  final String patientId;
  final String patientName;
  final int rating;
  final String comment;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  factory PharmacyRatingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PharmacyRatingModel(
      id: doc.id,
      pharmacistId: data['pharmacistId'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      rating: ((data['rating'] as num?)?.toInt() ?? 0).clamp(1, 5),
      comment: data['comment'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}

class PharmacyRatingSummary {
  const PharmacyRatingSummary({
    required this.average,
    required this.count,
  });

  final double average;
  final int count;

  bool get hasRatings => count > 0;
}
