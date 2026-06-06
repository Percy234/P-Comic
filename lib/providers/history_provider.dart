import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/database_helper.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
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
      histories = await _db.getHistories(user.uid);
    }
    notifyListeners();
  }

  Future<void> recordHistory({
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Chỉ lưu lịch sử khi đã đăng nhập
    
    await _db.insertHistoryData(
      userId: user.uid,
      comicId: comicId,
      name: name,
      slug: slug,
      thumbUrl: thumbUrl,
    );
    await loadHistories();
  }
}
