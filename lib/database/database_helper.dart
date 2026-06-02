import 'package:hive_flutter/hive_flutter.dart';
import '../models/comic_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  static const String _favoritesBoxName = 'favorites';
  static const String _historiesBoxName = 'histories';
  static const String _followsBoxName = 'follows';

  // Khởi tạo các Box lưu trữ dữ liệu
  Future<void> initHive() async {
    await Hive.initFlutter();
    await Hive.openBox(_favoritesBoxName);
    await Hive.openBox(_historiesBoxName);
    await Hive.openBox(_followsBoxName);
  }

  Box get _favoritesBox => Hive.box(_favoritesBoxName);
  Box get _historiesBox => Hive.box(_historiesBoxName);

  // --- FAVORITES ---
  Future<void> insertFavorite(Comic comic) async {
    await insertFavoriteData(
      comicId: comic.id,
      name: comic.name,
      slug: comic.slug,
      thumbUrl: comic.thumbUrl,
    );
  }

  Future<void> insertFavoriteData({
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
  }) async {
    await _favoritesBox.put(comicId, {
      'comicId': comicId,
      'name': name,
      'slug': slug,
      'thumbUrl': thumbUrl,
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFavorite(String comicId) async {
    await _favoritesBox.delete(comicId);
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final rawData = _favoritesBox.values;
    final list = rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    
    // Sắp xếp theo addedAt mới nhất lên đầu
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a['addedAt'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['addedAt'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    return list;
  }

  Future<bool> isFavorite(String comicId) async {
    return _favoritesBox.containsKey(comicId);
  }

  // --- HISTORIES ---
  Future<void> insertHistoryData({
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
  }) async {
    await _historiesBox.put(comicId, {
      'comicId': comicId,
      'name': name,
      'slug': slug,
      'thumbUrl': thumbUrl,
      'visitedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHistories() async {
    final rawData = _historiesBox.values;
    final list = rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    
    // Sắp xếp theo visitedAt mới nhất lên đầu
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a['visitedAt'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['visitedAt'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    return list;
  }
}
