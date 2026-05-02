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
      version: 10,
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
        track8 TEXT,
        track9 TEXT,
        track10 TEXT,
        track11 TEXT,
        track12 TEXT,
        track13 TEXT,
        track14 TEXT,
        track15 TEXT,
        track16 TEXT,
        track17 TEXT,
        track18 TEXT,
        track19 TEXT,
        track20 TEXT,
        track21 TEXT,
        track22 TEXT,
        track23 TEXT,
        track24 TEXT,
        track1_checked INTEGER DEFAULT 0,
        track2_checked INTEGER DEFAULT 0,
        track3_checked INTEGER DEFAULT 0,
        track4_checked INTEGER DEFAULT 0,
        track5_checked INTEGER DEFAULT 0,
        track6_checked INTEGER DEFAULT 0,
        track7_checked INTEGER DEFAULT 0,
        track8_checked INTEGER DEFAULT 0,
        track9_checked INTEGER DEFAULT 0,
        track10_checked INTEGER DEFAULT 0,
        track11_checked INTEGER DEFAULT 0,
        track12_checked INTEGER DEFAULT 0,
        track13_checked INTEGER DEFAULT 0,
        track14_checked INTEGER DEFAULT 0,
        track15_checked INTEGER DEFAULT 0,
        track16_checked INTEGER DEFAULT 0,
        track17_checked INTEGER DEFAULT 0,
        track18_checked INTEGER DEFAULT 0,
        track19_checked INTEGER DEFAULT 0,
        track20_checked INTEGER DEFAULT 0,
        track21_checked INTEGER DEFAULT 0,
        track22_checked INTEGER DEFAULT 0,
        track23_checked INTEGER DEFAULT 0,
        track24_checked INTEGER DEFAULT 0
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
        projectDate TEXT NOT NULL,
        channelCount INTEGER DEFAULT 8
      )
    ''');

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
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE app_preferences ADD COLUMN customLogoPath TEXT');
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE app_preferences ADD COLUMN addLogoToPDF INTEGER NOT NULL DEFAULT 1');
    }
    if (oldVersion < 10) {
      await db.execute('ALTER TABLE app_preferences ADD COLUMN quickNotes TEXT NOT NULL DEFAULT \'有飞机飞过|发生削波|无线干扰|无线发生摩擦|线路接触不良\'');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
