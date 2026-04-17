import '../models/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings?> getSettings();
  Future<int> saveSettings(AppSettings settings);
  Future<void> deleteSettings();
}
