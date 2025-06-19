import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  List<String> _deviceModels = [];
  List<String> _fileFormats = [];

  ThemeMode get themeMode => _themeMode;
  List<String> get deviceModels => _deviceModels;
  List<String> get fileFormats => _fileFormats;

  AppState() {
    _loadFromPrefs();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('themeMode', mode.index);
  }

  void setDeviceModels(List<String> models) async {
    _deviceModels = List.from(models);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('deviceModels', _deviceModels);
  }

  void setFileFormats(List<String> formats) async {
    _fileFormats = List.from(formats);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('fileFormats', _fileFormats);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    _deviceModels = prefs.getStringList('deviceModels') ?? ['Zoom F8n', 'Sound Devices 633'];
    _fileFormats = prefs.getStringList('fileFormats') ?? ['24Bit 48kHz BWF WAV'];
    notifyListeners();
  }
} 