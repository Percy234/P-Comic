import 'package:flutter/material.dart';
import '../models/reading_model.dart';
import '../services/api_service.dart';

class ReadingProvider extends ChangeNotifier {
  ReadingChapter? chapter;
  bool isLoading = false;

  Future<void> loadChapter(String apiUrl) async {
    isLoading = true;
    notifyListeners();
    try {
      chapter = await ApiService().fetchChapter(apiUrl);
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }
}