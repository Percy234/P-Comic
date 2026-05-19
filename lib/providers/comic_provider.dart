import 'package:flutter/material.dart';
import '../models/comic_model.dart';
import '../services/api_service.dart';

class ComicProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Comic> homeComics = [];
  List<Comic> pagedComics = [];
  List<Comic> randomComics = [];
  bool _randomized = false;
  bool isLoading = false;
  int currentPage = 1;
  int totalItems = 0;
  int totalPerPage = 24;


  Future<void> loadHomeComics() async {
    try {
      homeComics = await _apiService.fetchHomeComics();
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadPagedComics(int page) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.fetchPagedComics(page,);
      pagedComics = response.comics;
      currentPage = response.currentPage;
      totalItems = response.totalItems;
      totalPerPage = response.totalPerPage;
      // Compute randomComics once when loading page 1
      if (page == 1 && !_randomized) {
        final Map<String, Comic> uniqueMap = {};
        for (final comic in pagedComics) {
          uniqueMap[comic.id] = comic;
        }
        final uniqueList = uniqueMap.values.toList();
        uniqueList.shuffle();
        randomComics = uniqueList.take(6).toList();
        _randomized = true;
      }
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }
} 