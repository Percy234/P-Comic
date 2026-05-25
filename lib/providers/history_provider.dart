import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> histories = [];

  Future<void> loadHistories() async {
    histories = await _db.getHistories();
    notifyListeners();
  }

  Future<void> recordHistory({
    required String comicId,
    required String name,
    required String slug,
    required String thumbUrl,
  }) async {
    await _db.insertHistoryData(
      comicId: comicId,
      name: name,
      slug: slug,
      thumbUrl: thumbUrl,
    );
    await loadHistories();
  }
}
