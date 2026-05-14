import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordResetRequestModel {
  const PasswordResetRequestModel({
    required this.id,
    required this.email,
    required this.status,
    this.accessCode,
    this.requestedAt,
    this.updatedAt,
    this.expiresAt,
    this.sentAt,
    this.emailSentAt,
    this.handledBy,
  });

  final String id;
  final String email;
  final String status;
  final String? accessCode;
  final Timestamp? requestedAt;
  final Timestamp? updatedAt;
  final Timestamp? expiresAt;
  final Timestamp? sentAt;
  final Timestamp? emailSentAt;
  final String? handledBy;

  bool get isPending => status == 'pending';
  bool get isCodeSent => status == 'code_sent';
  bool get isEmailSent => status == 'email_sent';

  DateTime? get expiresAtLocal => expiresAt?.toDate().toLocal();

  factory PasswordResetRequestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PasswordResetRequestModel(
      id: doc.id,
      email: (data['email'] as String? ?? '').trim().toLowerCase(),
      status: (data['status'] as String? ?? 'pending').trim(),
      accessCode: data['accessCode'] as String?,
      requestedAt: data['requestedAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      expiresAt: data['expiresAt'] as Timestamp?,
      sentAt: data['sentAt'] as Timestamp?,
      emailSentAt: data['emailSentAt'] as Timestamp?,
      handledBy: data['handledBy'] as String?,
    );
  }
}
