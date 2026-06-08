import 'package:hive_flutter/hive_flutter.dart';

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
    await Hive.openBox('settings');
  }

  Box get _favoritesBox => Hive.box(_favoritesBoxName);
  Box get _historiesBox => Hive.box(_historiesBoxName);

  // --- FAVORITES ---
  Future<void> insertFavoriteData({
    required String userId,
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
    String? author,
    String? genres,
  }) async {
    final key = '${userId}_$comicId';
    await _favoritesBox.put(key, {
      'userId': userId,
      'comicId': comicId,
      'name': name,
      'slug': slug,
      'thumbUrl': thumbUrl,
      'author': author ?? 'Đang cập nhật',
      'genres': genres ?? '',
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFavorite(String userId, String comicId) async {
    final key = '${userId}_$comicId';
    await _favoritesBox.delete(key);
  }

  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    final rawData = _favoritesBox.values;
    final list = rawData
        .where((e) => e is Map && e['userId'] == userId)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    
    // Sắp xếp theo addedAt mới nhất lên đầu
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a['addedAt'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['addedAt'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    return list;
  }

  Future<bool> isFavorite(String userId, String comicId) async {
    final key = '${userId}_$comicId';
    return _favoritesBox.containsKey(key);
  }

  // --- HISTORIES ---
  Future<void> insertHistoryData({
    required String userId,
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
    required String chapterName,
  }) async {
    final key = '${userId}_$comicId';
    await _historiesBox.put(key, {
      'userId': userId,
      'comicId': comicId,
      'name': name,
      'slug': slug,
      'thumbUrl': thumbUrl,
      'chapterName': chapterName,
      'visitedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHistories(String userId) async {
    final rawData = _historiesBox.values;
    final list = rawData
        .where((e) => e is Map && e['userId'] == userId)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a['visitedAt'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['visitedAt'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    return list;
  }
}
