import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/app_settings.dart';
import '../models/track_config.dart';
import '../models/recording_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sound_report.db');
    return _database!;
  }

  Future<int> saveRecordingEntry(RecordingEntry entry) async {
    final db = await database;
    if (entry.id == null) {
      return await db.insert('recording_entry', entry.toMap());
    } else {
      return await db.update(
        'recording_entry',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    }
  }

  Future<List<RecordingEntry>> getAllRecordingEntries() async {
    final db = await database;
    final maps = await db.query('recording_entry');
    return List.generate(maps.length, (i) => RecordingEntry.fromMap(maps[i]));
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('app_settings');
      await txn.delete('track_config');
      await txn.delete('recording_entry');
    });
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE recording_entry ADD COLUMN isDiscarded INTEGER');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE recording_entry ADD COLUMN createdAt INTEGER');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE recording_entry ADD COLUMN tempScene TEXT');
          await db.execute('UPDATE recording_entry SET tempScene = CAST(scene AS TEXT)');
          await db.execute('ALTER TABLE recording_entry DROP COLUMN scene');
          await db.execute('ALTER TABLE recording_entry RENAME COLUMN tempScene TO scene');
          
          await db.execute('ALTER TABLE recording_entry ADD COLUMN tempTake TEXT');
          await db.execute('UPDATE recording_entry SET tempTake = CAST(take AS TEXT)');
          await db.execute('ALTER TABLE recording_entry DROP COLUMN take');
          await db.execute('ALTER TABLE recording_entry RENAME COLUMN tempTake TO take');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE app_settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectName TEXT,
        productionCompany TEXT,
        soundEngineer TEXT,
        boomOperator TEXT,
        equipmentModel TEXT,
        fileFormat TEXT,
        frameRate REAL,
        projectDate TEXT,
        rollNumber TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE track_config(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        track1 TEXT,
        track2 TEXT,
        track3 TEXT,
        track4 TEXT,
        track5 TEXT,
        track6 TEXT,
        track7 TEXT,
        track8 TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recording_entry(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fileName TEXT,
        startTC TEXT,
        scene TEXT,
        take TEXT,
        slate TEXT,
        isDiscarded INTEGER,
        notes TEXT,
        trackConfigId INTEGER,
        createdAt INTEGER
      )
    ''');
  }


  // 应用设置操作方法
  Future<int> saveAppSettings(AppSettings settings) async {
    final db = await database;
    return db.insert('app_settings', settings.toMap());
  }

  Future<AppSettings?> getAppSettings() async {
    final db = await database;
    final maps = await db.query('app_settings', orderBy: 'id DESC', limit: 1);
    return maps.isEmpty ? null : AppSettings.fromMap(maps.first);
  }

  // 轨道配置操作方法
  Future<int> saveTrackConfig(TrackConfig config) async {
    final db = await database;
    return db.insert('track_config', config.toMap());
  }

  Future<TrackConfig?> getLatestTrackConfig() async {
    final db = await database;
    final maps = await db.query(
      'track_config',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return TrackConfig.fromMap(maps.first);
    }
    return null;
  }

  Future<RecordingEntry?> getLatestRecordingEntry() async {
    final db = await database;
    final maps = await db.query(
      'recording_entry',
      orderBy: 'id DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? RecordingEntry.fromMap(maps.first) : null;
  }
}