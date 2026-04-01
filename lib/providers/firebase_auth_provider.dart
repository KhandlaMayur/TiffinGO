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
        // try to load user doc from 'user_register', then 'seller_register', then 'admin_register'
        var snap = await FirebaseFirestore.instance
            .collection('user_register')
            .doc(user.uid)
            .get();
        if (!snap.exists) {
          snap = await FirebaseFirestore.instance
              .collection('seller_register')
              .doc(user.uid)
              .get();
        }
        if (!snap.exists) {
          snap = await FirebaseFirestore.instance
              .collection('admin_register')
              .doc(user.uid)
              .get();
        }
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

  Future<fb.User?> loginWithEmail(String email, String password, {String role = 'user'}) async {
    final user = await _authService.loginWithEmail(email, password, role: role);
    return user;
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
