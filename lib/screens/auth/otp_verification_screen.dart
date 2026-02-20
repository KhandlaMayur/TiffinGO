import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/firebase_auth_provider.dart';
import '../../services/otp_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool isRegistration;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.isRegistration,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  int _remainingTime = 300; // 5 minutes in seconds

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _remainingTime--;
          if (_remainingTime > 0) {
            _startTimer();
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOtp() async {
    final otp =
        _otpControllers.map((controller) => controller.text).join().trim();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('\n🔐 OTP Verification Started');
      print('   Email: ${widget.email}');
      print('   OTP Entered: $otp');

      final otpService = OtpService();

      // Debug: Print stored OTPs
      otpService.debugPrintOtps();

      final isValid = otpService.verifyOtp(widget.email, otp);

      if (isValid) {
        print('✓ OTP Verification Successful!\n');
        final authProvider = context.read<AuthProvider>();

        if (widget.isRegistration) {
          // For registration, create Firebase user (so data is stored in Firestore)
          final firebaseAuth = context.read<FirebaseAuthProvider>();

          try {
            // find pending user details saved in AuthProvider
            final pendingUser = authProvider.registeredUsers.firstWhere(
              (u) => u.email.toLowerCase() == widget.email.toLowerCase(),
              orElse: () => throw Exception('Pending user not found'),
            );

            // create firebase auth user and write register_login/{uid}
            final fbUser = await firebaseAuth.registerWithEmail(
              pendingUser.email,
              pendingUser.password,
              pendingUser.fullName,
              phone: pendingUser.contact,
            );

            // mark as verified in local provider
            await authProvider.markEmailAsVerified(widget.email);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      '✓ Email verified and account created. Please login.'),
                  backgroundColor: Colors.green,
                ),
              );
              await Future.delayed(const Duration(seconds: 1));
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            }
          } catch (e) {
            print('Error creating firebase user after OTP: $e');
            if (mounted) {
              setState(() {
                _errorMessage = 'Error creating account: ${e.toString()}';
                _isLoading = false;
              });
            }
          }
        } else {
          // For login, complete the login process and go to home
          await authProvider.completeOtpLogin(widget.email);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Login successful!'),
                backgroundColor: Colors.green,
              ),
            );
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            }
          }
        }
      } else {
        print('✗ OTP Verification Failed!\n');
        if (mounted) {
          setState(() {
            _errorMessage = '✗ Invalid OTP. Please check and try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('✗ OTP Verification Error: $e\n');
      if (mounted) {
        setState(() {
          _errorMessage = '✗ Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _remainingTime = 300;
    });

    final otpService = OtpService();
    final otp = otpService.generateOtp();
    otpService.storeOtp(widget.email, otp);

    // Send OTP via email
    final sent = await otpService.sendOtpToEmail(widget.email, otp);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (sent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent to your email'),
            backgroundColor: Colors.green,
          ),
        );
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF001F54);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        title: const Text('Verify Email'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: navy.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 60,
                  color: navy,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We\'ve sent a 6-digit OTP to\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _otpControllers[index].text.isEmpty
                            ? Colors.grey
                            : navy,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Timer and Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'OTP expires in ${_formatTime(_remainingTime)}',
                    style: TextStyle(
                      color: _remainingTime < 60 ? Colors.red : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: _remainingTime > 0 ? null : _resendOtp,
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: _remainingTime > 0 ? Colors.grey : navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
