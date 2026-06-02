import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class FavoriteProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Map<String, dynamic>> favorites = [];

  Future<void> loadFavorites() async {
    favorites = await _db.getFavorites();
    notifyListeners();
  }

  bool isFavoriteComic(String comicId) {
    return favorites.any(
      (item) => item['comicId'] == comicId,
    );
  }

  Future<void> toggleFavorite({
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
  }) async {
    try {
      final exists = isFavoriteComic(comicId);

      if (exists) {
        await _db.removeFavorite(comicId);

        favorites.removeWhere(
          (item) => item['comicId'] == comicId,
        );
      } else {
        await _db.insertFavoriteData(
          comicId: comicId,
          name: name,
          slug: slug,
          thumbUrl: thumbUrl,
        );

        favorites.insert(0, {
          'comicId': comicId,
          'name': name,
          'slug': slug,
          'thumbUrl': thumbUrl,
          'addedAt': DateTime.now().toIso8601String(),
        });
      }

      notifyListeners();
    } catch (e) {
      // Báo lỗi nếu xảy ra
    }
  }

  Future<void> removeFavoriteById(String comicId) async {
    await _db.removeFavorite(comicId);

    favorites.removeWhere(
      (item) => item['comicId'] == comicId,
    );

    notifyListeners();
  }
}