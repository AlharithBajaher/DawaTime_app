import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pharmacy_rating_model.dart';

class PharmacyRatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<List<PharmacyRatingModel>> watchRatingsForPharmacist(
    String pharmacistId,
  ) {
    return _firestore
        .collection('pharmacy_ratings')
        .where('pharmacistId', isEqualTo: pharmacistId)
        .snapshots()
        .map((snapshot) {
          final ratings = snapshot.docs
              .map(PharmacyRatingModel.fromFirestore)
              .toList(growable: false);
          final sorted = List<PharmacyRatingModel>.from(ratings);
          sorted.sort((a, b) {
            final updatedA = a.updatedAt?.millisecondsSinceEpoch ?? 0;
            final updatedB = b.updatedAt?.millisecondsSinceEpoch ?? 0;
            return updatedB.compareTo(updatedA);
          });
          return sorted;
        });
  }

  Stream<PharmacyRatingSummary> watchSummaryForPharmacist(String pharmacistId) {
    return watchRatingsForPharmacist(pharmacistId).map((ratings) {
      if (ratings.isEmpty) {
        return const PharmacyRatingSummary(average: 0, count: 0);
      }

      final total = ratings.fold<int>(
        0,
        (runningTotal, rating) => runningTotal + rating.rating,
      );
      return PharmacyRatingSummary(
        average: total / ratings.length,
        count: ratings.length,
      );
    });
  }

  Future<void> submitRating({
    required String pharmacistId,
    required String pharmacyName,
    required int rating,
    required String comment,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('No authenticated patient found.');
    }

    final profileSnapshot = await _firestore.collection('users').doc(uid).get();
    final profileData = profileSnapshot.data();
    final profileName = (profileData?['name'] as String?)?.trim();
    final username = (profileData?['username'] as String?)?.trim();
    final fallbackEmail = _auth.currentUser?.email?.split('@').first ?? 'User';
    final resolvedPatientName = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : (username != null && username.isNotEmpty)
        ? username
        : fallbackEmail;

    final normalizedRating = rating.clamp(1, 5);
    final normalizedComment = comment.trim();
    final docId = '${pharmacistId}_$uid';

    await _firestore.collection('pharmacy_ratings').doc(docId).set({
      'pharmacistId': pharmacistId,
      'pharmacyName': pharmacyName,
      'patientId': uid,
      'patientName': resolvedPatientName,
      'rating': normalizedRating,
      'comment': normalizedComment,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
