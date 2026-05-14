import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.approvalStatus,
    required this.authProvider,
    this.photoUrl,
    this.pharmacyName,
    this.pharmacyLocation,
    this.pharmacyPhone,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String username;
  final String email;
  final String role;
  final String approvalStatus;
  final String authProvider;
  final String? photoUrl;
  final String? pharmacyName;
  final String? pharmacyLocation;
  final String? pharmacyPhone;
  final String? approvedBy;
  final Timestamp? approvedAt;
  final Timestamp? createdAt;

  bool get isApproved => approvalStatus == 'approved';

  bool get needsAdminApproval =>
      role == 'pharmacist' && approvalStatus == 'pending';

  bool get isRejected => role == 'pharmacist' && approvalStatus == 'rejected';

  bool get hasPharmacyProfile =>
      role == 'pharmacist' &&
      (pharmacyName?.trim().isNotEmpty ?? false) &&
      (pharmacyLocation?.trim().isNotEmpty ?? false);

  String get displayName {
    final cleanName = name.trim();
    if (cleanName.isNotEmpty) {
      return cleanName;
    }

    final cleanUsername = username.trim();
    if (cleanUsername.isNotEmpty) {
      return cleanUsername;
    }

    final emailPrefix = email.split('@').first.trim();
    if (emailPrefix.isNotEmpty) {
      return emailPrefix.replaceAll(RegExp(r'[._-]+'), ' ');
    }

    return 'DawaTime User';
  }

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'DU';
    }

    final first = String.fromCharCode(parts.first.runes.first).toUpperCase();
    final second = parts.length > 1
        ? String.fromCharCode(parts.last.runes.first).toUpperCase()
        : '';
    return '$first$second';
  }

  AppUserModel copyWith({
    String? uid,
    String? name,
    String? username,
    String? email,
    String? role,
    String? approvalStatus,
    String? authProvider,
    String? photoUrl,
    String? pharmacyName,
    String? pharmacyLocation,
    String? pharmacyPhone,
    String? approvedBy,
    Timestamp? approvedAt,
    Timestamp? createdAt,
  }) {
    return AppUserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      authProvider: authProvider ?? this.authProvider,
      photoUrl: photoUrl ?? this.photoUrl,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyLocation: pharmacyLocation ?? this.pharmacyLocation,
      pharmacyPhone: pharmacyPhone ?? this.pharmacyPhone,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};

    return AppUserModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'patient',
      approvalStatus: data['approvalStatus'] as String? ?? 'approved',
      authProvider: data['authProvider'] as String? ?? 'password',
      photoUrl: data['photoUrl'] as String?,
      pharmacyName: data['pharmacyName'] as String?,
      pharmacyLocation: data['pharmacyLocation'] as String?,
      pharmacyPhone: data['pharmacyPhone'] as String?,
      approvedBy: data['approvedBy'] as String?,
      approvedAt: data['approvedAt'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
