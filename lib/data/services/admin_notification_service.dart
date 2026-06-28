import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationItem {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String approvalStatus;
  final Timestamp? createdAt;
  final bool isRead;

  const AdminNotificationItem({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.approvalStatus,
    this.createdAt,
    this.isRead = false,
  });

  String get roleLabel => role == 'pharmacist' ? 'صيدلي' : 'مريض';

  String get statusLabel {
    switch (approvalStatus) {
      case 'pending':
        return 'بانتظار الموافقة';
      case 'approved':
        return 'تم اعتماده تلقائياً';
      default:
        return approvalStatus;
    }
  }
}

class AdminNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'admin_notifications';
  static const String _readDoc = '_read_tracking';

  Future<String> get _adminUid async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not authenticated');
    return uid;
  }

  Future<void> markNotificationsSeen() async {
    final uid = await _adminUid;
    await _firestore.collection(_collection).doc(_readDoc).set({
      'lastSeenBy': uid,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<UnmodifiableListView<AdminNotificationItem>> watchNewRegistrations() {
    return _firestore
        .collection('users')
        .where('role', isNotEqualTo: 'admin')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
      final lastSeenDoc = await _firestore
          .collection(_collection)
          .doc(_readDoc)
          .get();
      final lastSeenAt = lastSeenDoc.data()?['lastSeenAt'] as Timestamp?;

      final items = <AdminNotificationItem>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userCreatedAt = data['createdAt'] as Timestamp?;
        final isRead = lastSeenAt != null &&
            userCreatedAt != null &&
            userCreatedAt.seconds <= lastSeenAt.seconds;

        items.add(AdminNotificationItem(
          uid: doc.id,
          name: data['name'] as String? ?? '',
          email: data['email'] as String? ?? '',
          role: data['role'] as String? ?? 'patient',
          approvalStatus: data['approvalStatus'] as String? ?? 'approved',
          createdAt: userCreatedAt,
          isRead: isRead,
        ));
      }

      return UnmodifiableListView(items);
    });
  }

  Stream<int> watchUnreadCount() {
    return watchNewRegistrations().map(
      (items) => items.where((item) => !item.isRead).length,
    );
  }
}
