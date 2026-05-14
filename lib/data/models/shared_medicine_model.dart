import 'package:cloud_firestore/cloud_firestore.dart';

class SharedMedicineModel {
  const SharedMedicineModel({
    required this.id,
    required this.pharmacistId,
    required this.pharmacistEmail,
    required this.pharmacistName,
    required this.pharmacyName,
    required this.name,
    required this.description,
    required this.usageInstructions,
    required this.dosage,
    required this.packageSize,
    required this.price,
    required this.location,
    required this.pharmacyPhone,
    required this.category,
    required this.isAvailable,
    required this.requiresPrescription,
    required this.searchIndex,
    this.imageUrl,
    this.imageStoragePath,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String pharmacistId;
  final String pharmacistEmail;
  final String pharmacistName;
  final String pharmacyName;
  final String name;
  final String description;
  final String usageInstructions;
  final String dosage;
  final String packageSize;
  final double price;
  final String location;
  final String pharmacyPhone;
  final String category;
  final bool isAvailable;
  final bool requiresPrescription;
  final List<String> searchIndex;
  final String? imageUrl;
  final String? imageStoragePath;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  String get availabilityLabel =>
      isAvailable ? 'Available now' : 'Out of stock';

  String get prescriptionLabel =>
      requiresPrescription ? 'Prescription required' : 'OTC / no prescription';

  String formattedPrice({required bool isArabic}) {
    final normalized = price.toStringAsFixed(
      price.truncateToDouble() == price ? 0 : 2,
    );
    return isArabic ? '$normalized ر.ي' : '$normalized YER';
  }

  String displayTimelineLabel() {
    final source = updatedAt?.toDate() ?? createdAt?.toDate();
    if (source == null) {
      return '--:--';
    }

    final hour = source.hour % 12 == 0 ? 12 : source.hour % 12;
    final minute = source.minute.toString().padLeft(2, '0');
    final period = source.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  bool matchesQuery(String query) {
    final normalizedQuery = normalizeSearchValue(query);
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return searchIndex.any(
      (keyword) => normalizeSearchValue(keyword).contains(normalizedQuery),
    );
  }

  static List<String> buildSearchIndex({
    required String name,
    required String pharmacistName,
    required String pharmacyName,
    required String description,
    required String dosage,
    required String category,
    required String location,
  }) {
    return {
      normalizeSearchValue(name),
      normalizeSearchValue(pharmacistName),
      normalizeSearchValue(pharmacyName),
      normalizeSearchValue(description),
      normalizeSearchValue(dosage),
      normalizeSearchValue(category),
      normalizeSearchValue(location),
    }.where((value) => value.isNotEmpty).toList(growable: false);
  }

  static String normalizeSearchValue(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  factory SharedMedicineModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};

    return SharedMedicineModel(
      id: doc.id,
      pharmacistId: data['pharmacistId'] as String? ?? '',
      pharmacistEmail: data['pharmacistEmail'] as String? ?? '',
      pharmacistName: data['pharmacistName'] as String? ?? '',
      pharmacyName: data['pharmacyName'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      usageInstructions: data['usageInstructions'] as String? ?? '',
      dosage: data['dosage'] as String? ?? '',
      packageSize: data['packageSize'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      location: data['location'] as String? ?? '',
      pharmacyPhone: data['pharmacyPhone'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      isAvailable: data['isAvailable'] as bool? ?? true,
      requiresPrescription: data['requiresPrescription'] as bool? ?? false,
      searchIndex: (data['searchIndex'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      imageUrl: data['imageUrl'] as String?,
      imageStoragePath: data['imageStoragePath'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}

