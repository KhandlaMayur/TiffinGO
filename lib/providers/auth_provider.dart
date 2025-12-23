import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/otp_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  List<UserModel> _registeredUsers = [];
  String? _pendingEmail; // Email waiting for OTP verification
  bool _isOtpVerification = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  List<UserModel> get registeredUsers => _registeredUsers;
  String? get pendingEmail => _pendingEmail;
  bool get isOtpVerification => _isOtpVerification;

  /// Check if email exists in registered users
  bool emailExists(String email) {
    return _registeredUsers.any((user) => user.email == email.toLowerCase());
  }

  /// Register user and send OTP to email
  Future<bool> registerUserAndSendOtp(UserModel user) async {
    try {
      // Check if email already exists
      if (emailExists(user.email)) {
        return false; // Email already registered
      }

      // Generate OTP
      final otpService = OtpService();
      final otp = otpService.generateOtp();
      otpService.storeOtp(user.email, otp);

      // Send OTP to email
      final sent = await otpService.sendOtpToEmail(user.email, otp);
      if (!sent) {
        return false; // Failed to send OTP
      }

      // Store user as pending (not yet verified)
      _pendingEmail = user.email.toLowerCase();
      _registeredUsers.add(user);
      await _saveUsers();

      notifyListeners();
      return true;
    } catch (e) {
      print('Error in registerUserAndSendOtp: $e');
      return false;
    }
  }

  /// Mark email as verified during registration
  Future<void> markEmailAsVerified(String email) async {
    _pendingEmail = null;
    await _saveUsers();
    notifyListeners();
  }

  /// Verify email for login and send OTP
  Future<bool> initiateLoginWithOtp(String email) async {
    try {
      // Check if email exists
      if (!emailExists(email)) {
        return false;
      }

      // Generate and send OTP
      final otpService = OtpService();
      final otp = otpService.generateOtp();
      otpService.storeOtp(email, otp);

      final sent = await otpService.sendOtpToEmail(email, otp);
      if (!sent) {
        return false;
      }

      _pendingEmail = email.toLowerCase();
      _isOtpVerification = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error in initiateLoginWithOtp: $e');
      return false;
    }
  }

  /// Complete login after OTP verification
  Future<bool> completeOtpLogin(String email) async {
    try {
      final user = _registeredUsers.firstWhere(
        (user) => user.email == email.toLowerCase(),
        orElse: () =>
            UserModel(fullName: '', email: '', contact: '', password: ''),
      );

      if (user.email.isEmpty) {
        return false;
      }

      _currentUser = user;
      _isLoggedIn = true;
      _pendingEmail = null;
      _isOtpVerification = false;
      await _saveCurrentUser();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error in completeOtpLogin: $e');
      return false;
    }
  }

  /// Old password-based login (kept for compatibility)
  Future<bool> loginUser(String emailOrContact, String password) async {
    final user = _registeredUsers.firstWhere(
      (user) =>
          (user.email == emailOrContact || user.contact == emailOrContact),
      orElse: () =>
          UserModel(fullName: '', email: '', contact: '', password: ''),
    );

    if (user.email.isEmpty) {
      return false; // User not found
    }

    if (user.password == password) {
      _currentUser = user;
      _isLoggedIn = true;
      await _saveCurrentUser();
      notifyListeners();
      return true;
    }

    return false; // Wrong password
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    await _clearCurrentUser();
    notifyListeners();
  }

  Future<void> updateUserProfile(
      String fullName, String email, String contact) async {
    if (_currentUser != null) {
      _currentUser = UserModel(
        fullName: fullName,
        email: email,
        contact: contact,
        password: _currentUser!.password,
      );

      // Update in registered users list
      final index = _registeredUsers.indexWhere(
        (user) => user.contact == _currentUser!.contact,
      );
      if (index != -1) {
        _registeredUsers[index] = _currentUser!;
        await _saveUsers();
        await _saveCurrentUser();
      }
      notifyListeners();
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson =
        _registeredUsers.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList('registered_users', usersJson);
  }

  Future<void> _saveCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
      await prefs.setBool('is_logged_in', true);
    }
  }

  Future<void> _clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    await prefs.setBool('is_logged_in', false);
  }

  Future<void> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersList = prefs.getStringList('registered_users');
    if (usersList != null) {
      _registeredUsers = usersList
          .map((userString) {
            try {
              final Map<String, dynamic> json = jsonDecode(userString);
              return UserModel.fromJson(json);
            } catch (e) {
              // Skip malformed entries
              return null;
            }
          })
          .whereType<UserModel>()
          .toList();
    }

    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (isLoggedIn) {
      final currentUserString = prefs.getString('current_user');
      if (currentUserString != null) {
        try {
          final Map<String, dynamic> json = jsonDecode(currentUserString);
          _currentUser = UserModel.fromJson(json);
          _isLoggedIn = true;
        } catch (e) {
          // ignore malformed current user
        }
      }
    }
    notifyListeners();
  }
}
