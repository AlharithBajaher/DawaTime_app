import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/config/admin_access.dart';
import '../models/app_user_model.dart';
import '../models/password_reset_request_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );
  final Random _random = Random.secure();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  Stream<AppUserModel?> watchUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      return AppUserModel.fromFirestore(doc);
    });
  }

  Future<String?> getUserRole(String uid) async {
    final profile = await getUserProfile(uid);
    return profile?.role;
  }

  Future<AppUserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }

    return AppUserModel.fromFirestore(doc);
  }

  Future<AppUserModel?> getCurrentUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) {
      return null;
    }

    return getUserProfile(uid);
  }

  Future<void> updateCurrentUserProfile({
    required String name,
    required String username,
    String? pharmacyName,
    String? pharmacyLocation,
    String? pharmacyPhone,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No authenticated user found for profile update.');
    }

    final normalizedUsername = normalizeUsername(username);
    if (name.trim().length < 3) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: 'Please enter a clear full name.',
      );
    }

    if (normalizedUsername.length < 4) {
      throw FirebaseAuthException(
        code: 'invalid-username',
        message: 'Please use at least 4 letters, numbers, or underscores.',
      );
    }

    final isAvailable = await isUsernameAvailable(
      normalizedUsername,
      exceptUid: user.uid,
    );
    if (!isAvailable) {
      throw FirebaseAuthException(
        code: 'username-taken',
        message: 'This username is already taken.',
      );
    }

    final profile = await getUserProfile(user.uid);
    final isPharmacist = profile?.role == 'pharmacist';
    final trimmedName = name.trim();
    final trimmedPharmacyName = pharmacyName?.trim() ?? '';
    final trimmedPharmacyLocation = pharmacyLocation?.trim() ?? '';
    final trimmedPharmacyPhone = pharmacyPhone?.trim() ?? '';

    final updateData = <String, dynamic>{
      'name': name.trim(),
      'username': normalizedUsername,
      'photoUrl': user.photoURL,
    };
    if (isPharmacist) {
      updateData['pharmacyName'] = trimmedPharmacyName;
      updateData['pharmacyLocation'] = trimmedPharmacyLocation;
      updateData['pharmacyPhone'] = trimmedPharmacyPhone;
    }

    await _firestore.collection('users').doc(user.uid).update(updateData);

    if (isPharmacist) {
      await _syncPublishedMedicinesProfile(
        pharmacistId: user.uid,
        pharmacistName: trimmedName,
        pharmacyName: trimmedPharmacyName,
        pharmacyLocation: trimmedPharmacyLocation,
        pharmacyPhone: trimmedPharmacyPhone,
      );
    }

    await user.updateDisplayName(trimmedName);
  }

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String username,
    required String email,
    required String role,
    String authProvider = 'password',
    String? photoUrl,
    String approvalStatus = 'approved',
    String? pharmacyName,
    String? pharmacyLocation,
    String? pharmacyPhone,
  }) async {
    final resolvedRole = _resolvedRole(email: email, requestedRole: role);
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'username': username,
      'email': email,
      'role': resolvedRole,
      'approvalStatus': resolvedRole == 'pharmacist'
          ? approvalStatus
          : 'approved',
      'authProvider': authProvider,
      'photoUrl': photoUrl,
      'pharmacyName': pharmacyName,
      'pharmacyLocation': pharmacyLocation,
      'pharmacyPhone': pharmacyPhone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUserModel> createProfileIfMissing({
    required String uid,
    required String name,
    required String username,
    required String email,
    required String role,
    String authProvider = 'password',
    String? photoUrl,
    String? pharmacyName,
    String? pharmacyLocation,
    String? pharmacyPhone,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final existing = await docRef.get();

    if (existing.exists) {
      final profile = AppUserModel.fromFirestore(existing);
      if (AdminAccess.isBootstrapAdminEmail(email) &&
          (profile.role != 'admin' || profile.approvalStatus != 'approved')) {
        await docRef.set({
          'role': 'admin',
          'approvalStatus': 'approved',
          'email': email,
          'username': username,
          'name': name,
        }, SetOptions(merge: true));
        final updated = await docRef.get();
        return AppUserModel.fromFirestore(updated);
      }
      return profile;
    }

    final resolvedRole = _resolvedRole(email: email, requestedRole: role);
    await docRef.set({
      'name': name,
      'username': username,
      'email': email,
      'role': resolvedRole,
      'approvalStatus': resolvedRole == 'pharmacist' ? 'pending' : 'approved',
      'authProvider': authProvider,
      'photoUrl': photoUrl,
      'pharmacyName': pharmacyName,
      'pharmacyLocation': pharmacyLocation,
      'pharmacyPhone': pharmacyPhone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final created = await docRef.get();
    return AppUserModel.fromFirestore(created);
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<AppUserModel> registerWithEmail({
    required String name,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final credential = await register(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw StateError('No authenticated user found after registration.');
    }

    final normalizedUsername = normalizeUsername(username).isEmpty
        ? buildUsernameFromIdentity(email: email, uid: user.uid)
        : normalizeUsername(username);

    return createProfileIfMissing(
      uid: user.uid,
      name: name,
      username: normalizedUsername,
      email: email,
      role: role,
      authProvider: 'password',
    );
  }

  Future<AppUserModel> signInWithEmailAccount({
    required String email,
    required String password,
    String fallbackRole = 'patient',
  }) async {
    final credential = await signIn(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw StateError('No authenticated user found after sign in.');
    }

    final adminProfile = await ensureAdminProfile(user);
    if (adminProfile != null && adminProfile.role == 'admin') {
      return adminProfile;
    }

    final existingProfile = await getUserProfile(user.uid);
    if (existingProfile != null) {
      return existingProfile;
    }

    final fallbackUsername = buildUsernameFromIdentity(
      email: email,
      uid: user.uid,
    );
    return createProfileIfMissing(
      uid: user.uid,
      name: _deriveNameFromEmail(email),
      username: fallbackUsername,
      email: email,
      role: fallbackRole,
      authProvider: 'password',
    );
  }

  Future<String?> findEmailByUsernameOrEmail(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.contains('@')) {
      return trimmed.toLowerCase();
    }

    final normalized = normalizeUsername(trimmed);
    if (normalized.isEmpty) {
      return null;
    }

    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first.data()['email'] as String?;
  }

  Future<AppUserModel> signInAdmin({
    required String identifier,
    required String password,
  }) async {
    final email = await findEmailByUsernameOrEmail(identifier);
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No admin account matches this identifier.',
      );
    }

    final credential = await signIn(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw StateError('No authenticated user found after admin sign in.');
    }

    final profile = await ensureAdminProfile(user);
    if (profile == null || profile.role != 'admin') {
      await signOut();
      throw FirebaseAuthException(
        code: 'unauthorized-admin',
        message: 'This account is not allowed to access the admin dashboard.',
      );
    }

    return profile;
  }

  Future<AppUserModel> signInWithGoogle({required String selectedRole}) async {
    late final UserCredential credential;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});
      credential = await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'aborted-by-user',
          message: 'تم إلغاء تسجيل الدخول عبر Google.',
        );
      }

      final googleAuth = await googleUser.authentication;
      final authCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      credential = await _auth.signInWithCredential(authCredential);
    }

    final user = credential.user;
    if (user == null) {
      throw StateError('No authenticated user found after Google sign in.');
    }

    final adminProfile = await ensureAdminProfile(user);
    if (adminProfile != null && adminProfile.role == 'admin') {
      return adminProfile;
    }

    final existingProfile = await getUserProfile(user.uid);
    if (existingProfile != null) {
      return existingProfile;
    }

    final generatedUsername = buildUsernameFromIdentity(
      email: user.email ?? '',
      uid: user.uid,
    );
    return createProfileIfMissing(
      uid: user.uid,
      name: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : _deriveNameFromEmail(user.email ?? ''),
      username: generatedUsername,
      email: user.email ?? '',
      role: selectedRole,
      authProvider: 'google',
      photoUrl: user.photoURL,
    );
  }

  Future<bool> isUsernameAvailable(String username, {String? exceptUid}) async {
    final normalizedUsername = normalizeUsername(username);
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return true;
      }

      if (exceptUid != null && query.docs.first.id == exceptUid) {
        return true;
      }

      return false;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return true;
      }
      rethrow;
    }
  }

  String buildUsernameFromIdentity({
    required String email,
    required String uid,
  }) {
    final base = normalizeUsername(email.split('@').first);
    final safeBase = base.isEmpty ? 'user' : base;
    final suffix = uid.length >= 4 ? uid.substring(0, 4).toLowerCase() : uid;
    return '${safeBase}_$suffix';
  }

  Stream<List<AppUserModel>> watchUsersByRole(
    String role, {
    String? approvalStatus,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .where('role', isEqualTo: role);

    if (approvalStatus != null) {
      query = query.where('approvalStatus', isEqualTo: approvalStatus);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(AppUserModel.fromFirestore).toList(growable: false),
    );
  }

  Stream<List<AppUserModel>> watchAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppUserModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<PasswordResetRequestModel>> watchPasswordResetRequests() {
    return _firestore
        .collection('password_reset_requests')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PasswordResetRequestModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> submitPasswordResetRequest({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }

    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (userQuery.docs.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account found for this email.',
      );
    }

    final docId = _requestDocIdFromEmail(normalizedEmail);
    await _firestore.collection('password_reset_requests').doc(docId).set({
      'email': normalizedEmail,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> issuePasswordResetCode({
    required String requestId,
    required String adminUid,
  }) async {
    final code = (_random.nextInt(900000) + 100000).toString();
    final expiry = DateTime.now().toLocal().add(const Duration(minutes: 30));

    await _firestore.collection('password_reset_requests').doc(requestId).set({
      'status': 'code_sent',
      'accessCode': code,
      'handledBy': adminUid,
      'sentAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiry),
    }, SetOptions(merge: true));

    return code;
  }

  Future<void> sendPasswordResetEmailViaCode({
    required String email,
    required String accessCode,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedCode = accessCode.trim();
    if (normalizedEmail.isEmpty || normalizedCode.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-argument',
        message: 'Email and access code are required.',
      );
    }

    final requestId = _requestDocIdFromEmail(normalizedEmail);

    try {
      await _firestore
          .collection('password_reset_requests')
          .doc(requestId)
          .set({
            'email': normalizedEmail,
            'status': 'email_sent',
            'accessCode': normalizedCode,
            'emailSentAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw FirebaseAuthException(
          code: 'invalid-access-code',
          message: 'The access code is invalid or expired.',
        );
      }
      rethrow;
    }

    await _auth.sendPasswordResetEmail(email: normalizedEmail);
  }

  Future<void> updatePharmacistApproval({
    required String userId,
    required String approvalStatus,
    required String adminUid,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'approvalStatus': approvalStatus,
      'approvedBy': adminUid,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  String normalizeUsername(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_]+'),
      '',
    );
    return normalized;
  }

  String _deriveNameFromEmail(String email) {
    final prefix = email.split('@').first.trim();
    if (prefix.isEmpty) {
      return 'New User';
    }
    return prefix.replaceAll(RegExp(r'[._-]+'), ' ');
  }

  Future<AppUserModel?> ensureAdminProfile(User user) async {
    final email = user.email?.trim().toLowerCase();
    final existing = await getUserProfile(user.uid);

    if (!AdminAccess.isBootstrapAdminEmail(email)) {
      return existing;
    }

    await _firestore.collection('users').doc(user.uid).set({
      'email': email,
      'role': 'admin',
      'approvalStatus': 'approved',
      'name': existing?.name.isNotEmpty == true
          ? existing!.name
          : _deriveNameFromEmail(email ?? ''),
      'username': existing?.username.isNotEmpty == true
          ? existing!.username
          : buildUsernameFromIdentity(email: email ?? '', uid: user.uid),
      'authProvider': existing?.authProvider ?? 'password',
      'photoUrl': existing?.photoUrl ?? user.photoURL,
      'createdAt': existing?.createdAt ?? FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return getUserProfile(user.uid);
  }

  String _resolvedRole({required String email, required String requestedRole}) {
    if (AdminAccess.isBootstrapAdminEmail(email)) {
      return 'admin';
    }

    return requestedRole;
  }

  String _requestDocIdFromEmail(String email) {
    return email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9@._-]'), '');
  }

  Future<void> _syncPublishedMedicinesProfile({
    required String pharmacistId,
    required String pharmacistName,
    required String pharmacyName,
    required String pharmacyLocation,
    required String pharmacyPhone,
  }) async {
    final snapshot = await _firestore
        .collection('shared_medicines')
        .where('pharmacistId', isEqualTo: pharmacistId)
        .get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'pharmacistName': pharmacistName,
        'pharmacyName': pharmacyName,
        'location': pharmacyLocation,
        'pharmacyPhone': pharmacyPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
