import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

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
      try {
        favorites = await _firestoreService.getFavorites(user.uid);
      } catch (e) {
        favorites = [];
      }
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
    String? author,
    String? genres,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Chỉ cho phép thích khi đã đăng nhập
    
    try {
      final exists = isFavoriteComic(comicId);

      if (exists) {
        // Cập nhật UI trước (Optimistic UI)
        favorites.removeWhere(
          (item) => item['comicId'] == comicId,
        );
        notifyListeners();

        // Xóa khỏi Firestore
        await _firestoreService.removeFavorite(user.uid, comicId);
      } else {
        // Cập nhật UI trước (Optimistic UI)
        favorites.insert(0, {
          'userId': user.uid,
          'comicId': comicId,
          'name': name,
          'slug': slug,
          'thumbUrl': thumbUrl,
          'author': author ?? 'Đang cập nhật',
          'genres': genres ?? '',
          'addedAt': DateTime.now().toIso8601String(),
        });
        notifyListeners();

        // Lưu lên Firestore
        await _firestoreService.addFavorite(
          userId: user.uid,
          comicId: comicId,
          name: name,
          slug: slug,
          thumbUrl: thumbUrl,
          author: author,
          genres: genres,
        );
      }
    } catch (e) {
      // Nếu có lỗi, tải lại dữ liệu thực tế từ Firestore để đảm bảo đồng bộ
      await loadFavorites();
    }
  }

  Future<void> removeFavoriteById(String comicId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Cập nhật UI trước (Optimistic UI)
    favorites.removeWhere(
      (item) => item['comicId'] == comicId,
    );
    notifyListeners();

    try {
      await _firestoreService.removeFavorite(user.uid, comicId);
    } catch (e) {
      await loadFavorites();
    }
  }
}