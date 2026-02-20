import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
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

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _fullNameError;
  String? _emailError;
  String? _contactError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateFullName(String value) {
    setState(() {
      if (value.isEmpty) {
        _fullNameError = 'Please fill up details';
      } else if (value.length < 2) {
        _fullNameError = 'Invalid name';
      } else {
        _fullNameError = 'Perfect';
      }
    });
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = 'Please fill up details';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        _emailError = 'Invalid email';
      } else {
        _emailError = 'Perfect';
      }
    });
  }

  void _validateContact(String value) {
    setState(() {
      if (value.isEmpty) {
        _contactError = 'Please fill up details';
      } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
        _contactError = 'Invalid contact';
      } else {
        _contactError = 'Perfect';
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Please fill up details';
      } else {
        // check strength
        final strong = _isStrongPassword(value);
        if (!strong) {
          _passwordError =
              'Weak password. Use ≥8 chars, uppercase, lowercase, number, symbol.';
        } else {
          _passwordError = 'Perfect';
        }
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError = 'Please fill up details';
      } else if (value != _passwordController.text) {
        _confirmPasswordError = 'Invalid password';
      } else {
        _confirmPasswordError = 'Perfect';
      }
    });
  }

  bool _isStrongPassword(String password) {
    // Criteria: at least 8 chars, contains upper, lower, digit and special char
    if (password.length < 8) return false;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]'));
    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // enforce password strength and confirm match before proceeding
    if (_passwordError != 'Perfect') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a stronger password.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_confirmPasswordController.text != _passwordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirm password does not match.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();

    // Check if email already exists in Firestore register_login collection
    final emailSnap = await FirebaseFirestore.instance
        .collection('register_login')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (emailSnap.docs.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('This email is already used. Please enter another email.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if contact already exists in Firestore register_login collection
    final contactSnap = await FirebaseFirestore.instance
        .collection('register_login')
        .where('phone', isEqualTo: contact)
        .limit(1)
        .get();

    if (contactSnap.docs.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'This phone number is already used. Please enter another phone number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = UserModel(
      fullName: _fullNameController.text.trim(),
      email: email,
      contact: contact,
      password: _passwordController.text,
    );

    final authProvider = context.read<AuthProvider>();

    // Try to register and send OTP
    final success = await authProvider.registerUserAndSendOtp(user);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      // Navigate to OTP verification
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            email: user.email,
            isRegistration: true,
          ),
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration failed. Email might already exist or OTP sending failed.',
          ),
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
            SizedBox(
              height: 260,
              width: double.infinity,
              child: ClipPath(
                clipper: _BottomArcClipper(),
                child: Container(
                  color: navy,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 40.0, left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 8.0, left: 16.0),
                          child: Text(
                            'Create Account\nJoin TiffinGo Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                          'Register',
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
                                'Sign Up',
                                style: TextStyle(
                                  color: navy,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _fullNameController,
                                decoration: InputDecoration(
                                  hintText: 'Full Name',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(Icons.person_outline,
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
                                onChanged: _validateFullName,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please fill up details';
                                  }
                                  return null;
                                },
                              ),
                              if (_fullNameError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _fullNameError!,
                                    style: TextStyle(
                                      color: _fullNameError == 'Perfect'
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(Icons.email_outlined,
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
                              if (_emailError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _emailError!,
                                    style: TextStyle(
                                      color: _emailError == 'Perfect'
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _contactController,
                                decoration: InputDecoration(
                                  hintText: 'Phone',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(Icons.phone_outlined,
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
                                keyboardType: TextInputType.phone,
                                onChanged: _validateContact,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please fill up details';
                                  }
                                  return null;
                                },
                              ),
                              if (_contactError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _contactError!,
                                    style: TextStyle(
                                      color: _contactError == 'Perfect'
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
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
                                  prefixIcon: Icon(Icons.lock_outline,
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
                                obscureText: true,
                                onChanged: _validatePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please fill up details';
                                  }
                                  return null;
                                },
                              ),
                              if (_passwordError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _passwordError!,
                                    style: TextStyle(
                                      color: _passwordError == 'Perfect'
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  hintText: 'Confirm Password',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(Icons.lock_outline,
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
                                obscureText: true,
                                onChanged: _validateConfirmPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please fill up details';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              if (_confirmPasswordError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _confirmPasswordError!,
                                    style: TextStyle(
                                      color: _confirmPasswordError == 'Perfect'
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
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
                                          'Register',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
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
