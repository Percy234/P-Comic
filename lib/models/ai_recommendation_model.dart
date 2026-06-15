import 'comic_model.dart';

class AiRecommendationResult {
  final Comic comic;
  final String aiReason;

  AiRecommendationResult({
    required this.comic,
    required this.aiReason,
  });
}
