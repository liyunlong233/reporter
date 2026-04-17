import '../datasources/local_database.dart';
import '../../models/app_settings.dart';
import '../../repositories/settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  final LocalDatabase _database;

  LocalSettingsRepository(this._database);

  @override
  Future<AppSettings?> getSettings() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query('app_settings');
    return maps.isNotEmpty ? AppSettings.fromMap(maps.first) : null;
  }

  @override
  Future<int> saveSettings(AppSettings settings) async {
    final db = await _database.database;
    final existingSettings = await getSettings();
    
    if (existingSettings != null) {
      // 如果已存在设置，则更新而不是插入
      return await db.update(
        'app_settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [existingSettings.id],
      );
    } else {
      // 如果是第一条设置，则插入
      return await db.insert('app_settings', settings.toMap());
    }
  }

  @override
  Future<void> deleteSettings() async {
    final db = await _database.database;
    await db.delete('app_settings');
  }
}
