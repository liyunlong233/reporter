import '../datasources/local_database.dart';
import '../../models/recording_entry.dart';
import '../../repositories/recording_repository.dart';

class LocalRecordingRepository implements RecordingRepository {
  final LocalDatabase _database;

  LocalRecordingRepository(this._database);

  @override
  Future<List<RecordingEntry>> getAllRecordings() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query('recording_entries');
    return List.generate(maps.length, (i) => RecordingEntry.fromMap(maps[i]));
  }

  @override
  Future<RecordingEntry?> getRecordingById(int id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recording_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? RecordingEntry.fromMap(maps.first) : null;
  }

  @override
  Future<RecordingEntry?> getLatestRecording() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recording_entries',
      orderBy: 'id DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? RecordingEntry.fromMap(maps.first) : null;
  }

  @override
  Future<int> saveRecording(RecordingEntry entry) async {
    final db = await _database.database;
    return await db.insert('recording_entries', entry.toMap());
  }

  @override
  Future<int> updateRecording(RecordingEntry entry) async {
    final db = await _database.database;
    return await db.update(
      'recording_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  @override
  Future<void> deleteRecording(int id) async {
    final db = await _database.database;
    await db.delete(
      'recording_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<RecordingEntry>> getActiveRecordings() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recording_entries',
      where: 'isDiscarded = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => RecordingEntry.fromMap(maps[i]));
  }

  @override
  Future<List<RecordingEntry>> getDiscardedRecordings() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recording_entries',
      where: 'isDiscarded = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => RecordingEntry.fromMap(maps[i]));
  }

  @override
  Future<void> deleteAllRecordings() async {
    final db = await _database.database;
    await db.delete('recording_entries');
  }
}
