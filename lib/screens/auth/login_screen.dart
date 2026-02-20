import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/firebase_auth_provider.dart';
import 'register_screen.dart';
import 'otp_verification_screen.dart';
import '../landing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// A clipper that creates a concave arc at the bottom of the widget.
class _BottomArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
        size.width / 2, size.height + 40, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = 'Please fill up details';
      } else if (!value.contains('@') && !RegExp(r'^[0-9]+$').hasMatch(value)) {
        _emailError = 'Invalid email format';
      } else {
        _emailError = null;
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final firebaseAuth = context.read<FirebaseAuthProvider>();
    var emailOrContact = _emailController.text.trim();
    final password = _passwordController.text;

    // If the app has a pending email (waiting OTP verification) and it
    // matches this email, prevent login until verification.
    final pending = authProvider.pendingEmail;

    String? emailToLogin;

    // If the user entered a phone number (digits only), try to lookup email in Firestore
    if (RegExp(r'^[0-9]+$').hasMatch(emailOrContact)) {
      final snap = await FirebaseFirestore.instance
          .collection('register_login')
          .where('phone', isEqualTo: emailOrContact)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone not found. Please register first.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      emailToLogin = snap.docs.first.data()['email'] as String?;
    } else {
      emailToLogin = emailOrContact;
    }

    if (emailToLogin == null || emailToLogin.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email or contact not found. Please register.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = await firebaseAuth.loginWithEmail(emailToLogin, password);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // If there's a pending email and it matches the login email, ask to verify
      if (pending != null &&
          pending.toLowerCase() == emailToLogin.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // All checks passed -> go to landing page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LandingScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF001F54);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            // Navy curved header
            SizedBox(
              height: 260,
              width: double.infinity,
              child: ClipPath(
                clipper: _BottomArcClipper(),
                child: Container(
                  color: navy,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 60.0),
                    child: Text(
                      'Hello!\nWelcome to TiffinGo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content card overlapping the header
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Section label above card
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: navy,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 140),

                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Login',
                                style: TextStyle(
                                  color: navy,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: 'Email or Contact',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(Icons.person,
                                      color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                onChanged: _validateEmail,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please fill up details';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  prefixIcon:
                                      Icon(Icons.lock, color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  if (value.length < 4) {
                                    return 'Password must be at least 4 characters';
                                  }
                                  return null;
                                },
                              ),
                              if (_emailError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _emailError!,
                                    style: TextStyle(
                                      color: _emailError ==
                                              'Please do register first'
                                          ? Colors.red
                                          : _emailError == 'Perfect'
                                              ? Colors.green
                                              : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: navy,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Register',
                                      style: TextStyle(
                                        color: navy,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
