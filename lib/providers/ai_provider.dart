import 'package:flutter/material.dart';
import '../models/ai_recommendation_model.dart';
import '../services/api_service.dart';
import '../services/gemini_service.dart';

class AiProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final ApiService _apiService = ApiService();

  List<AiRecommendationResult> aiResults = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> searchComicsWithAi(String userInput) async {
    if (userInput.trim().isEmpty) {
      aiResults = [];
      errorMessage = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    aiResults = [];
    notifyListeners();

    try {
      final recommendations = await _geminiService.recommendComics(userInput.trim());

      final List<AiRecommendationResult> tempResults = [];

      for (final item in recommendations) {
        final titleVi = item['title_vi'] ?? '';
        final titleEn = item['title_en'] ?? '';
        final reason = item['reason'] ?? '';

        if (titleVi.isEmpty && titleEn.isEmpty) continue;

        List<dynamic> searchedList = [];
        if (titleVi.isNotEmpty) {
          try {
            final response = await _apiService.searchComics(titleVi, 1);
            searchedList = response.comics;
          } catch (_) {}
        }

        if (searchedList.isEmpty && titleEn.isNotEmpty) {
          try {
            final response = await _apiService.searchComics(titleEn, 1);
            searchedList = response.comics;
          } catch (_) {}
        }

        if (searchedList.isNotEmpty) {
          final comic = searchedList.first;
          
          final alreadyExists = tempResults.any((res) => res.comic.slug == comic.slug);
          if (!alreadyExists) {
            tempResults.add(
              AiRecommendationResult(
                comic: comic,
                aiReason: reason,
              ),
            );
          }
        }
      }

      aiResults = tempResults;
      if (aiResults.isEmpty) {
        errorMessage = 'AI đã gợi ý một số truyện nhưng chưa khớp được với dữ liệu của ứng dụng. Bạn hãy mô tả chi tiết hơn nhé!';
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('503') || errorStr.contains('unavailable') || errorStr.contains('busy') || errorStr.contains('demand')) {
        errorMessage = 'Máy chủ AI hiện đang quá tải. Bạn hãy thử lại sau vài giây nhé!';
      } else if (errorStr.contains('429') || errorStr.contains('quota') || errorStr.contains('limit') || errorStr.contains('exhausted')) {
        errorMessage = 'Bạn đã gửi yêu cầu quá nhanh hoặc vượt hạn ngạch. Vui lòng đợi một lát rồi thử lại nhé!';
      } else if (errorStr.contains('api key') || errorStr.contains('key not found') || errorStr.contains('403') || errorStr.contains('denied') || errorStr.contains('permission')) {
        errorMessage = 'Khóa kết nối AI (API Key) không hợp lệ hoặc đã bị chặn quyền truy cập.';
      } else {
        errorMessage = 'Đã xảy ra sự cố khi kết nối với trợ lý AI: ${e.toString().replaceAll('Exception: ', '')}';
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearResults() {
    aiResults = [];
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }
}
