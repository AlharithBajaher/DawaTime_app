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
  final String? approvedBy;
  final Timestamp? approvedAt;
  final Timestamp? createdAt;

  bool get isApproved => approvalStatus == 'approved';

  bool get needsAdminApproval =>
      role == 'pharmacist' && approvalStatus == 'pending';

  bool get isRejected => role == 'pharmacist' && approvalStatus == 'rejected';

  AppUserModel copyWith({
    String? uid,
    String? name,
    String? username,
    String? email,
    String? role,
    String? approvalStatus,
    String? authProvider,
    String? photoUrl,
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
      approvedBy: data['approvedBy'] as String?,
      approvedAt: data['approvedAt'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
