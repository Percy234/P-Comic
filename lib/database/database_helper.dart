import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/comic_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init(); 

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('p_comic.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int versionn) async {
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comicId TEXT UNIQUE,
        name TEXT,
        slug TEXT,
        thumbUrl TEXT,
        addedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE follows(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comicId TEXT UNIQUE,
        name TEXT,
        slug TEXT,
        thumbUrl TEXT,
        followedAt TEXT
      )
    ''');
  }

  Future<void> insertFavorite(Comic comic) async {
    final db = await instance.database;
    await db.insert(
      'favorites',
      {
        'comicId': comic.id,
        'name': comic.name,
        'slug': comic.slug,
        'thumbUrl': comic.thumbUrl,
        'addedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertFavoriteData({
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
  }) async {
    final db = await instance.database;
    await db.insert(
      'favorites',
      {
        'comicId': comicId,
        'name': name,
        'slug': slug,
        'thumbUrl': thumbUrl,
        'addedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } 

  Future<void> removeFavorite(String comicId) async {
    final db = await instance.database;
    await db.delete(
      'favorites',
      where: 'comicId = ?',
      whereArgs: [comicId],
    );
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await instance.database;
    return await db.query(
      'favorites',
      orderBy: 'addedAt DESC',
    );
  }

  Future<bool> isFavorite(String comicId) async {
    final db = await instance.database;
    final result = await db.query(
      'favorites',
      where: 'comicId = ?',
      whereArgs: [comicId],
    );
    return result.isNotEmpty;
  }
}