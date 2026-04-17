import '../datasources/local_database.dart';
import '../../models/app_preferences.dart';

class LocalPreferencesRepository {
  final LocalDatabase _database;

  LocalPreferencesRepository(this._database);

  Future<AppPreferences?> getPreferences() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query('app_preferences');
    return maps.isNotEmpty ? AppPreferences.fromMap(maps.first) : null;
  }

  Future<int> savePreferences(AppPreferences preferences) async {
    final db = await _database.database;
    final existingPreferences = await getPreferences();
    
    if (existingPreferences != null) {
      return await db.update(
        'app_preferences',
        preferences.toMap(),
        where: 'id = ?',
        whereArgs: [existingPreferences.id],
      );
    } else {
      return await db.insert('app_preferences', preferences.toMap());
    }
  }

  Future<void> deletePreferences() async {
    final db = await _database.database;
    await db.delete('app_preferences');
  }
}
