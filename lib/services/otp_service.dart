import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpService {
  static final OtpService _instance = OtpService._internal();

  factory OtpService() {
    return _instance;
  }

  OtpService._internal();

  // Store OTPs temporarily (email -> {otp, timestamp})
  final Map<String, Map<String, dynamic>> _otpStorage = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a 6-digit OTP
  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Store OTP for an email (valid for 5 minutes)
  void storeOtp(String email, String otp) {
    final normalizedEmail = email.toLowerCase().trim();
    _otpStorage[normalizedEmail] = {
      'otp': otp,
      'timestamp': DateTime.now(),
      'attempts': 0,
    };
    print('✓ OTP Generated for $normalizedEmail: $otp');
  }

  /// Verify OTP for an email - reads from local storage
  bool verifyOtp(String email, String otp) {
    final normalizedEmail = email.toLowerCase().trim();
    final normalizedOtp = otp.trim();

    print('🔍 Verifying OTP...');
    print('   Email: $normalizedEmail');
    print('   Entered OTP: $normalizedOtp');
    print('   Stored OTPs: $_otpStorage');

    final otpData = _otpStorage[normalizedEmail];

    if (otpData == null) {
      print('✗ OTP not found for $normalizedEmail');
      print('   Available emails: ${_otpStorage.keys.toList()}');
      return false;
    }

    final storedOtp = otpData['otp'] as String;
    print('   Stored OTP: $storedOtp');

    // Check if OTP has expired (5 minutes)
    final timestamp = otpData['timestamp'] as DateTime;
    final now = DateTime.now();
    final difference = now.difference(timestamp).inMinutes;

    print('   Time elapsed: $difference minutes');

    if (difference > 5) {
      _otpStorage.remove(normalizedEmail);
      print('✗ OTP expired for $normalizedEmail');
      return false;
    }

    // Check if OTP matches (compare as strings)
    if (storedOtp == normalizedOtp) {
      _otpStorage.remove(normalizedEmail);
      print('✓ OTP verified successfully for $normalizedEmail');
      return true;
    }

    // Increment attempts
    otpData['attempts'] = (otpData['attempts'] as int) + 1;
    final attempts = otpData['attempts'] as int;

    // Lock after 5 attempts
    if (attempts >= 5) {
      _otpStorage.remove(normalizedEmail);
      print(
          '✗ OTP attempts exceeded for $normalizedEmail (attempted $attempts times)');
      return false;
    }

    print(
        '✗ Invalid OTP for $normalizedEmail. Stored: $storedOtp, Entered: $normalizedOtp. Attempt: $attempts/5');
    return false;
  }

  /// Send OTP via email to Firestore Cloud Functions
  /// This will trigger a Cloud Function to send the email
  Future<bool> sendOtpToEmail(String email, String otp) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();

      // Store OTP request in Firestore - Cloud Function will pick this up and send email
      await _firestore.collection('otp_requests').add({
        'email': normalizedEmail,
        'otp': otp,
        'createdAt': DateTime.now(),
        'sent': false,
      });

      print('✓ OTP Email will be sent to: $normalizedEmail');
      print('✓ OTP Code: $otp');
      print('✓ Check your Gmail inbox for the OTP code');

      return true;
    } catch (e) {
      print('✗ Error sending OTP: $e');
      return false;
    }
  }

  /// Check if OTP was recently sent to this email
  bool hasRecentOtp(String email) {
    return _otpStorage.containsKey(email.toLowerCase().trim());
  }

  /// Clear OTP for an email
  void clearOtp(String email) {
    _otpStorage.remove(email.toLowerCase().trim());
  }

  /// Debug: Print all stored OTPs
  void debugPrintOtps() {
    print('🔧 DEBUG - All stored OTPs:');
    _otpStorage.forEach((email, data) {
      print('   $email: ${data['otp']} (${data['timestamp']})');
    });
  }
}
