import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _settingsBoxName = 'settings';
  static const String _darkModeKey = 'isDarkMode';

  bool _isDarkMode = false;

  ThemeProvider() {
    final box = Hive.box(_settingsBoxName);
    _isDarkMode = box.get(_darkModeKey, defaultValue: false) as bool;
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final box = Hive.box(_settingsBoxName);
    await box.put(_darkModeKey, _isDarkMode);
  }
}
