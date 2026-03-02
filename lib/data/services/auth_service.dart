import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'];
  }

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String email,
    required String role,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
    Future<UserCredential> signIn({
  required String email,
  required String password,
}) async {
  return await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

Future<UserCredential> register({
  required String email,
  required String password,
}) async {
  return await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
}
}