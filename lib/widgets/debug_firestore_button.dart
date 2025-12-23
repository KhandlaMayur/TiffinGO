import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Debug widget: writes a small document to Firestore for connectivity testing.
///
/// Usage:
/// - Add `DebugFirestoreButton()` to any `Scaffold.floatingActionButton` or
///   place it in a screen body.
class DebugFirestoreButton extends StatelessWidget {
  final String collection;

  const DebugFirestoreButton({
    Key? key,
    this.collection = 'health_check',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.bug_report),
      label: const Text('Debug Firestore'),
      backgroundColor: const Color(0xFF1E3A8A),
      onPressed: () async {
        final scaffold = ScaffoldMessenger.of(context);
        try {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
          await FirebaseFirestore.instance.collection(collection).add({
            'createdAt': FieldValue.serverTimestamp(),
            'message': 'hello from app',
            'uid': uid,
            'platform': Theme.of(context).platform.toString(),
          });

          scaffold.showSnackBar(const SnackBar(
            content: Text('Firestore write succeeded'),
            backgroundColor: Colors.green,
          ));
        } catch (e) {
          scaffold.showSnackBar(SnackBar(
            content: Text('Firestore write failed: $e'),
            backgroundColor: Colors.red,
          ));
        }
      },
    );
  }
}
