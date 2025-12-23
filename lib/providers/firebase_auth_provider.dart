import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  fb.User? _firebaseUser;
  Map<String, dynamic>? _userDoc;

  fb.User? get firebaseUser => _firebaseUser;
  Map<String, dynamic>? get userDoc => _userDoc;

  FirebaseAuthProvider() {
    _authService.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        // load user doc from single `register_login` collection
        final snap = await FirebaseFirestore.instance
            .collection('register_login')
            .doc(user.uid)
            .get();
        _userDoc = snap.exists ? snap.data() : null;
      } else {
        _userDoc = null;
      }
      notifyListeners();
    });
  }

  Future<fb.User?> registerWithEmail(String email, String password, String name,
      {String? phone, Map<String, dynamic>? extraFields}) async {
    final user = await _authService.registerWithEmail(
      email,
      password,
      name,
      phone: phone,
      extraFields: extraFields,
    );
    return user;
  }

  Future<fb.User?> loginWithEmail(String email, String password) async {
    final user = await _authService.loginWithEmail(email, password);
    return user;
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
