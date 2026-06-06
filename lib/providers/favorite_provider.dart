import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';

class FavoriteProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Map<String, dynamic>> favorites = [];

  FavoriteProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      loadFavorites();
    });
  }

  Future<void> loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      favorites = [];
    } else {
      favorites = await _db.getFavorites(user.uid);
    }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Chỉ cho phép thích khi đã đăng nhập
    
    try {
      final exists = isFavoriteComic(comicId);

      if (exists) {
        await _db.removeFavorite(user.uid, comicId);

        favorites.removeWhere(
          (item) => item['comicId'] == comicId,
        );
      } else {
        await _db.insertFavoriteData(
          userId: user.uid,
          comicId: comicId,
          name: name,
          slug: slug,
          thumbUrl: thumbUrl,
        );

        favorites.insert(0, {
          'userId': user.uid,
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.removeFavorite(user.uid, comicId);

    favorites.removeWhere(
      (item) => item['comicId'] == comicId,
    );

    notifyListeners();
  }
}