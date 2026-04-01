import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// One-time utility to create the admin account in Firebase Auth and Firestore.
/// Run this ONCE by navigating to AdminSeedScreen from anywhere, then remove.
class AdminSeedScreen extends StatefulWidget {
  const AdminSeedScreen({super.key});

  @override
  State<AdminSeedScreen> createState() => _AdminSeedScreenState();
}

class _AdminSeedScreenState extends State<AdminSeedScreen> {
  bool _isRunning = false;
  String _status = 'Press the button to seed admin account.';

  Future<void> _seedAdmin() async {
    setState(() {
      _isRunning = true;
      _status = 'Creating admin account...';
    });

    try {
      const email = 'khandlamayur90@gmail.com';
      const password = 'Nefm@139';
      const phone = '8401102212';
      const name = 'Admin';

      // Try to create the Firebase Auth account
      UserCredential cred;
      try {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Account already exists — sign in to get the uid
          cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final uid = cred.user!.uid;

      // Create/update the admin_register document
      await FirebaseFirestore.instance
          .collection('admin_register')
          .doc(uid)
          .set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'admin',
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _status = '✅ Admin account seeded successfully!\n'
            'UID: $uid\n'
            'Email: $email\n'
            'Phone: $phone\n\n'
            'You can now login as Admin from the login screen.';
      });

      // Sign out so the user can login normally
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Seed Utility'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 64, color: Color(0xFF001F54)),
              const SizedBox(height: 24),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isRunning ? null : _seedAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F54),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: _isRunning
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Seed Admin Account', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
