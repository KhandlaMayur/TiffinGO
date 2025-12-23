import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme {
    return _isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme;
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveTheme();
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    await _saveTheme();
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }
}
