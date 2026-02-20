import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../providers/auth_provider.dart';

class EditProfileDialog extends StatefulWidget {
  final AuthProvider authProvider;

  const EditProfileDialog({
    super.key,
    required this.authProvider,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.authProvider.currentUser?.fullName ?? '';
    _emailController.text = widget.authProvider.currentUser?.email ?? '';
    _contactController.text = widget.authProvider.currentUser?.contact ?? '';

    // If no local current user (using Firebase auth), try to load from Firestore
    if ((widget.authProvider.currentUser == null ||
            widget.authProvider.currentUser!.email.isEmpty) &&
        fb.FirebaseAuth.instance.currentUser != null) {
      final uid = fb.FirebaseAuth.instance.currentUser!.uid;
      FirebaseFirestore.instance
          .collection('register_login')
          .doc(uid)
          .get()
          .then((doc) {
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _fullNameController.text =
                (data['fullName'] ?? data['name'] ?? '').toString();
            _emailController.text = (data['email'] ?? '') as String;
            _contactController.text =
                (data['phone'] ?? data['contact'] ?? '').toString();
          });
        }
      }).catchError((_) {
        // ignore
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Update local provider first
      await widget.authProvider.updateUserProfile(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _contactController.text.trim(),
      );

      // If user is signed in with Firebase, update Firestore record as well
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('register_login')
              .doc(fbUser.uid)
              .set({
            'fullName': _fullNameController.text.trim(),
            'name': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _contactController.text.trim(),
            'contact': _contactController.text.trim(),
          }, SetOptions(merge: true));
        } catch (e) {
          // ignore Firestore update errors for now
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF1E3A8A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email, color: Color(0xFF1E3A8A)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              decoration: InputDecoration(
                labelText: 'Contact Number',
                prefixIcon: const Icon(Icons.phone, color: Color(0xFF1E3A8A)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter contact number';
                }
                if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                  return 'Please enter valid 10-digit contact number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
