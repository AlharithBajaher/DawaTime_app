import 'package:cloud_firestore/cloud_firestore.dart';

enum OperationType {
  createMedication,
  updateMedication,
  deleteMedication,
  takeDose,
  skipDose,
  updateProfileImage,
  uploadMedicationImage,
  updateStockQuantity,
  syncNotification,
  syncMedicationReminders,
}

enum OperationStatus {
  pending,
  inProgress,
  completed,
  failed,
}

class PendingOperation {
  final String? id;
  final OperationType type;
  final Map<String, dynamic> data;
  final OperationStatus status;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final String? error;
  final String userId;
  final String? referencePath; // For tracking original document path
  final Map<String, dynamic>? metadata;

  PendingOperation({
    this.id,
    required this.type,
    required this.data,
    this.status = OperationStatus.pending,
    required this.createdAt,
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.error,
    required this.userId,
    this.referencePath,
    this.metadata,
  });

  factory PendingOperation.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PendingOperation(
      id: doc.id,
      type: OperationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => OperationType.createMedication,
      ),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      status: OperationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OperationStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastAttemptAt: data['lastAttemptAt'] != null
          ? (data['lastAttemptAt'] as Timestamp).toDate()
          : null,
      attemptCount: data['attemptCount'] ?? 0,
      error: data['error'],
      userId: data['userId'],
      referencePath: data['referencePath'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'data': data,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastAttemptAt': lastAttemptAt != null
          ? Timestamp.fromDate(lastAttemptAt!)
          : null,
      'attemptCount': attemptCount,
      'error': error,
      'userId': userId,
      'referencePath': referencePath,
      'metadata': metadata,
    };
  }

  PendingOperation copyWith({
    String? id,
    OperationType? type,
    Map<String, dynamic>? data,
    OperationStatus? status,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    int? attemptCount,
    String? error,
    String? userId,
    String? referencePath,
    Map<String, dynamic>? metadata,
  }) {
    return PendingOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      error: error ?? this.error,
      userId: userId ?? this.userId,
      referencePath: referencePath ?? this.referencePath,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get canRetry => attemptCount < 3 && status != OperationStatus.completed;

  Duration get nextRetryDelay {
    if (attemptCount == 0) return const Duration(seconds: 5);
    if (attemptCount == 1) return const Duration(seconds: 30);
    return const Duration(minutes: 5);
  }
}