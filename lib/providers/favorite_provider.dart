import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class FavoriteProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> favorites = [];

  bool isFavorite = false;

  Future<void> loadFavorites() async {
    favorites = await _db.getFavorites();
    notifyListeners();
  }

  Future<void> checkFavorite(
    String comicId,
  ) async {
    isFavorite = await _db.isFavorite(comicId);
    notifyListeners();
  }

  Future<void> toggleFavorite({
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
  }) async {
    if (isFavorite) {
      await _db.removeFavorite(comicId);
      isFavorite = false;
    } else {
      await _db.insertFavoriteData(
        comicId: comicId,
        name: name,
        slug: slug,
        thumbUrl: thumbUrl,
      );
      isFavorite = true;
    }
    await loadFavorites();
    notifyListeners();
  }
}