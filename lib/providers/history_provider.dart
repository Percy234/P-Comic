import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class HistoryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> histories = [];

  HistoryProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      loadHistories();
    });
  }

  Future<void> loadHistories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      histories = [];
    } else {
      try {
        histories = await _firestoreService.getHistories(user.uid);
      } catch (e) {
        histories = [];
      }
    }
    notifyListeners();
  }

  Future<void> recordHistory({
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
    required String chapterName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Chỉ lưu lịch sử khi đã đăng nhập
    
    // Cập nhật UI trước (Optimistic UI)
    histories.removeWhere((item) => item['comicId'] == comicId);
    histories.insert(0, {
      'userId': user.uid,
      'comicId': comicId,
      'name': name,
      'slug': slug,
      'thumbUrl': thumbUrl,
      'chapterName': chapterName,
      'visitedAt': DateTime.now().toIso8601String(),
    });
    notifyListeners();

    try {
      await _firestoreService.addHistory(
        userId: user.uid,
        comicId: comicId,
        name: name,
        slug: slug,
        thumbUrl: thumbUrl,
        chapterName: chapterName,
      );
    } catch (e) {
      // Nếu có lỗi, tải lại từ Firestore để đồng bộ chính xác dữ liệu thực tế
      await loadHistories();
    }
  }

  // Xóa một truyện khỏi lịch sử
  Future<void> removeHistory(String comicId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Optimistic UI
    histories.removeWhere((item) => item['comicId'] == comicId);
    notifyListeners();

    try {
      await _firestoreService.removeHistory(user.uid, comicId);
    } catch (e) {
      await loadHistories();
    }
  }

  // Xóa toàn bộ lịch sử đọc
  Future<void> clearAllHistories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Optimistic UI
    histories = [];
    notifyListeners();

    try {
      await _firestoreService.clearAllHistories(user.uid);
    } catch (e) {
      await loadHistories();
    }
  }
}
