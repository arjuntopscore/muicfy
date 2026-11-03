import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  
  String? _homeBackgroundImagePath;
  String? _searchBackgroundImagePath;
  String? _libraryBackgroundImagePath;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  String? getBackgroundImageForTab(int index) {
    switch (index) {
      case 0: return _homeBackgroundImagePath;
      case 1: return _searchBackgroundImagePath;
      case 2: return _libraryBackgroundImagePath;
      default: return null;
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _homeBackgroundImagePath = prefs.getString('homeBgPath');
    _searchBackgroundImagePath = prefs.getString('searchBgPath');
    _libraryBackgroundImagePath = prefs.getString('libraryBgPath');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners();
  }

  Future<void> setBackgroundImageForTab(int index, String path) async {
    final prefs = await SharedPreferences.getInstance();
    if (index == 0) {
      _homeBackgroundImagePath = path;
      await prefs.setString('homeBgPath', path);
    } else if (index == 1) {
      _searchBackgroundImagePath = path;
      await prefs.setString('searchBgPath', path);
    } else if (index == 2) {
      _libraryBackgroundImagePath = path;
      await prefs.setString('libraryBgPath', path);
    }
    notifyListeners();
  }

  Future<void> clearBackgroundImageForTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    if (index == 0) {
      _homeBackgroundImagePath = null;
      await prefs.remove('homeBgPath');
    } else if (index == 1) {
      _searchBackgroundImagePath = null;
      await prefs.remove('searchBgPath');
    } else if (index == 2) {
      _libraryBackgroundImagePath = null;
      await prefs.remove('libraryBgPath');
    }
    notifyListeners();
  }
}
