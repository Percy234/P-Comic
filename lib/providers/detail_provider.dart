import 'package:flutter/material.dart';
import '../models/comic_detail_model.dart';
import '../services/api_service.dart';

class DetailProvider extends ChangeNotifier {
  ComicDetail? comicDetail;
  bool isLoading = false;

  Future<void> loadDetail(String slug) async {
    isLoading = true;
    notifyListeners();
    try {
      comicDetail = await ApiService().fetchComicDetail(slug);
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }
}