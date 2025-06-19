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
    _database = await _initDB('reporter.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
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

    await db.execute('CREATE INDEX idx_recording_entries_scene ON recording_entries(scene)');
    await db.execute('CREATE INDEX idx_recording_entries_take ON recording_entries(take)');
    await db.execute('CREATE INDEX idx_recording_entries_createdAt ON recording_entries(createdAt)');
    await db.execute('CREATE INDEX idx_recording_entries_isDiscarded ON recording_entries(isDiscarded)');

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
  }

  Future<int> saveRecordingEntry(RecordingEntry entry) async {
    final db = await database;
    return await db.insert('recording_entries', entry.toMap());
  }

  Future<int> updateRecordingEntry(RecordingEntry entry) async {
    final db = await database;
    return await db.update(
      'recording_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteRecordingEntry(int id) async {
    final db = await database;
    return await db.delete(
      'recording_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<RecordingEntry>> getAllRecordingEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('recording_entries');
    return List.generate(maps.length, (i) => RecordingEntry.fromMap(maps[i]));
  }

  Future<RecordingEntry?> getLatestRecordingEntry() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recording_entries',
      orderBy: 'id DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? RecordingEntry.fromMap(maps.first) : null;
  }

  Future<int> saveAppSettings(AppSettings settings) async {
    final db = await database;
    final map = settings.toMap();
    map['id'] = 1; // 保证唯一
    return await db.insert(
      'app_settings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AppSettings?> getAppSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('app_settings');
    return maps.isNotEmpty ? AppSettings.fromMap(maps.first) : null;
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('recording_entries');
    await db.delete('app_settings');
  }

  Future<List<RecordingEntry>> getRecordingEntries({
    int page = 1,
    int pageSize = 50,
    String? searchQuery,
    bool? isDiscarded,
    String? sortBy,
    bool ascending = true,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = '(fileName LIKE ? OR scene LIKE ? OR take LIKE ? OR slate LIKE ? OR notes LIKE ?)';
      final searchPattern = '%$searchQuery%';
      whereArgs = List.filled(5, searchPattern);
    }
    
    if (isDiscarded != null) {
      if (whereClause.isNotEmpty) {
        whereClause = '($whereClause) AND isDiscarded = ?';
      } else {
        whereClause = 'isDiscarded = ?';
      }
      whereArgs.add(isDiscarded ? 1 : 0);
    }
    
    final offset = (page - 1) * pageSize;
    final orderBy = sortBy != null ? '$sortBy ${ascending ? 'ASC' : 'DESC'}' : 'createdAt DESC';
    
    final List<Map<String, dynamic>> maps = await db.query(
      'recording_entries',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );
    
    return List.generate(maps.length, (i) => RecordingEntry.fromMap(maps[i]));
  }

  Future<int> getRecordingEntriesCount({
    String? searchQuery,
    bool? isDiscarded,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = '(fileName LIKE ? OR scene LIKE ? OR take LIKE ? OR slate LIKE ? OR notes LIKE ?)';
      final searchPattern = '%$searchQuery%';
      whereArgs = List.filled(5, searchPattern);
    }
    
    if (isDiscarded != null) {
      if (whereClause.isNotEmpty) {
        whereClause = '($whereClause) AND isDiscarded = ?';
      } else {
        whereClause = 'isDiscarded = ?';
      }
      whereArgs.add(isDiscarded ? 1 : 0);
    }
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM recording_entries ${whereClause.isEmpty ? '' : 'WHERE $whereClause'}',
      whereArgs.isEmpty ? null : whereArgs,
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }
}