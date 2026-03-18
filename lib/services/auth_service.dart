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
        'isAdmin': false,
      };
      if (extraFields != null) data.addAll(extraFields);
      
      final role = (extraFields?['role']?.toString().toLowerCase()) ?? 'user';
      final collectionName = role == 'seller' ? 'seller_register' : 'user_register';

      // Store registration info in appropriate collection
      await _db.collection(collectionName).doc(user.uid).set(data);
    }
    return user;
  }

  Future<User?> loginWithEmail(String email, String password, {String role = 'user'}) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final user = cred.user;
    if (user != null) {
      try {
        final collectionName = role.toLowerCase() == 'seller' ? 'seller_login' : 'user_login';
        // Store login info in appropriate collection
        await _db.collection(collectionName).doc(user.uid).set(
          {
            'uid': user.uid,
            'email': email,
            'lastLoginAt': FieldValue.serverTimestamp(),
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
