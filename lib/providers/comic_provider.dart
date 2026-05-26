import 'package:flutter/material.dart';
import '../models/comic_model.dart';
import '../services/api_service.dart';

class ComicProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Comic> homeComics = [];
  List<Comic> pagedComics = [];
  List<Comic> randomComics = [];
  // cache latest chapter name by comic slug
  final Map<String, String> latestChapterNames = {};
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
      if (page == 1 && !_randomized) {
        final Map<String, Comic> uniqueMap = {};
        for (final comic in pagedComics) {
          uniqueMap[comic.id] = comic;
        }
        final uniqueList = uniqueMap.values.toList();
        uniqueList.shuffle();
        randomComics = uniqueList.take(10).toList();
        _randomized = true;
      }
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadLatestChapter(String slug) async {
    if (latestChapterNames.containsKey(slug) && latestChapterNames[slug]!.isNotEmpty) return;
    try {
      final detail = await _apiService.fetchComicDetail(slug);
      String latest = '';
      if (detail.chapters.isNotEmpty) {
        // Prefer chapter with largest numeric index extracted from name
        int? bestNum;
        String? bestName;
        final reg = RegExp(r"(\d+)");
        for (final ch in detail.chapters) {
          final m = reg.firstMatch(ch.name);
          if (m != null) {
            final num = int.tryParse(m.group(1)!) ?? 0;
            if (bestNum == null || num > bestNum) {
              bestNum = num;
              bestName = ch.name;
            }
          }
        }
        if (bestName != null) {
          latest = bestName;
        } else {
          // fallback to last chapter in list (assume chronological)
          latest = detail.chapters.last.name;
        }
      }
      latestChapterNames[slug] = latest;
      notifyListeners();
    } catch (e) {
      print('Error loading latest chapter for $slug: $e');
      latestChapterNames[slug] = '';
      notifyListeners();
    }
  }
} 