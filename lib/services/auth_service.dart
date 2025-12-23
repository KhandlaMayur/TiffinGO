import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<User?> registerWithEmail(String email, String password, String name,
      {String? phone, Map<String, dynamic>? extraFields}) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = cred.user;
    if (user != null) {
      final data = <String, dynamic>{
        'uid': user.uid,
        'name': name,
        'email': email,
        'phone': phone ?? user.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': null,
        'loginCount': 0,
        'isAdmin': false,
        'lastAction': 'register',
      };
      if (extraFields != null) data.addAll(extraFields);
      // Store registration info in single collection `register_login`
      await _db.collection('register_login').doc(user.uid).set(data);
    }
    return user;
  }

  Future<User?> loginWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final user = cred.user;
    if (user != null) {
      try {
        await _db.collection('register_login').doc(user.uid).set(
          {
            'lastLoginAt': FieldValue.serverTimestamp(),
            'lastAction': 'login',
            'loginCount': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        // ignore logging failures
      }
    }
    return user;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<User?> authStateChanges() => _auth.authStateChanges();
}
