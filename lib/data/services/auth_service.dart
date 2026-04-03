import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/config/admin_access.dart';
import '../models/app_user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

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

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String username,
    required String email,
    required String role,
    String authProvider = 'password',
    String? photoUrl,
    String approvalStatus = 'approved',
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
}
