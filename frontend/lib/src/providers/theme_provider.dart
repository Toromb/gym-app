import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  String? _userId;
  String get _themeKey => _userId != null ? 'theme_mode_$_userId' : 'theme_mode_guest';

  ThemeProvider();

  void setUserId(String? id) {
    if (_userId != id) {
      _userId = id;
      _loadTheme(); // Reload for new user
    }
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (_themeMode == ThemeMode.dark) {
      prefs.setString(_themeKey, 'dark');
    } else if (_themeMode == ThemeMode.light) {
      prefs.setString(_themeKey, 'light');
    } else {
      prefs.remove(_themeKey);
    }
  }
}
