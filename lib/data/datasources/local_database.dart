import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reporter.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recording_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fileName TEXT NOT NULL,
        startTC TEXT NOT NULL,
        scene TEXT NOT NULL,
        take TEXT NOT NULL,
        slate TEXT NOT NULL,
        isDiscarded INTEGER NOT NULL,
        notes TEXT NOT NULL,
        createdAt TEXT NOT NULL,
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
      CREATE TABLE app_settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectName TEXT NOT NULL,
        productionCompany TEXT,
        soundEngineer TEXT,
        boomOperator TEXT,
        equipmentModel TEXT,
        fileFormat TEXT,
        frameRate REAL,
        rollNumber TEXT,
        projectDate TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS recording_entry');
      
      await db.execute('''
        CREATE TABLE recording_entries(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fileName TEXT NOT NULL,
          startTC TEXT NOT NULL,
          scene TEXT NOT NULL,
          take TEXT NOT NULL,
          slate TEXT NOT NULL,
          isDiscarded INTEGER NOT NULL,
          notes TEXT NOT NULL,
          createdAt TEXT NOT NULL,
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
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS track_configs');
    }
    if (oldVersion < 4) {
      // 版本 4 没有破坏性变更，只是修复了 app_settings 的保存逻辑
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE recording_entries ADD COLUMN track1_checked INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE recording_entries ADD COLUMN track2_checked INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE recording_entries ADD COLUMN track3_checked INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE recording_entries ADD COLUMN track4_checked INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE recording_entries ADD COLUMN track5_checked INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE recording_entries ADD COLUMN track6_checked INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE recording_entries ADD COLUMN track7_checked INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE recording_entries ADD COLUMN track8_checked INTEGER DEFAULT 0');
    }
    if (oldVersion < 6) {
      for (var i = 9; i <= 24; i++) {
        await db.execute('ALTER TABLE recording_entries ADD COLUMN track$i TEXT');
        await db.execute('ALTER TABLE recording_entries ADD COLUMN track${i}_checked INTEGER DEFAULT 0');
      }
      await db.execute('ALTER TABLE app_settings ADD COLUMN channelCount INTEGER DEFAULT 8');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE app_preferences(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          includeDiscardedInPDF INTEGER NOT NULL DEFAULT 1,
          defaultFileFormats TEXT NOT NULL DEFAULT '',
          defaultEquipmentModels TEXT NOT NULL DEFAULT '',
          selectedFileFormat TEXT,
          selectedEquipmentModel TEXT
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
