import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return AppUser.fromMap(doc.data()!);
  }

  // create user in the firebase
  Future<AppUser?> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = cred.user!;
    final appUser = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: name,
      role: role,
    );

    await _db.collection('users').doc(appUser.uid).set(appUser.toMap());
    return appUser;
  }

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = cred.user!;
    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return null;

    return AppUser.fromMap(doc.data()!);
  }

  Future<void> logout() => _auth.signOut();
}
