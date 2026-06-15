import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

class GeminiService {
  static const String _apiKey = ApiConfig.geminiApiKey;

  Future<List<Map<String, String>>> recommendComics(String userInput) async {
    if (_apiKey.trim().isEmpty) {
      throw Exception('API Key của Gemini chưa được cấu hình.');
    }

    // Danh sách các mô hình thử nghiệm theo thứ tự ưu tiên
    final List<String> candidateModels = [
      'gemini-flash-lite-latest',  // 1. Bản Flash Lite siêu nhẹ (siêu ổn định, tránh nghẽn 503)
      'gemini-flash-latest',       // 2. Bản Flash tiêu chuẩn
      'gemini-2.5-flash-lite',     // 3. Bản 2.5 Flash Lite thế hệ mới
    ];

    int modelIndex = 0;
    int retryCount = 0;
    const int maxRetriesPerModel = 2;
    Duration delay = const Duration(seconds: 1);

    while (modelIndex < candidateModels.length) {
      final currentModel = candidateModels[modelIndex];
      try {
        debugPrint('Calling Gemini with model: $currentModel...');
        final model = GenerativeModel(
          model: currentModel,
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
          requestOptions: const RequestOptions(apiVersion: 'v1beta'),
        );

        final systemPrompt = '''
Bạn là trợ lý tìm truyện tranh chuyên nghiệp của ứng dụng P-Comic.
Nhiệm vụ của bạn là phân tích mô tả tự nhiên của người dùng để tìm và gợi ý tối đa 5 bộ truyện tranh nổi tiếng, quen thuộc nhất phù hợp với mô tả đó (có thể từ Manga Nhật Bản, Manhwa Hàn Quốc, Manhua Trung Quốc...).

Yêu cầu trả về kết quả dưới dạng JSON là một danh sách (mảng) các đối tượng có cấu trúc chính xác như sau:
[
  {
    "title_vi": "Tên truyện bằng tiếng Việt (Ví dụ: Thanh gươm diệt quỷ, Đảo hải tặc...)",
    "title_en": "Tên truyện bằng tiếng Anh hoặc tên gốc phổ biến (Ví dụ: Demon Slayer, One Piece...)",
    "reason": "Lý do ngắn gọn tại sao bộ truyện này phù hợp (1-2 câu tiếng Việt, súc tích và hấp dẫn)"
  }
]
Chú ý:
- Bạn chỉ được trả về chuỗi JSON thô có cấu trúc như trên, không thêm bất kỳ văn bản dẫn dắt, giải thích hay markdown code block nào cả.
''';

        final content = [
          Content.text('$systemPrompt\nYêu cầu người dùng: "$userInput"')
        ];

        final response = await model.generateContent(content);
        final responseText = response.text;

        if (responseText == null || responseText.trim().isEmpty) {
          throw Exception('Không nhận được phản hồi từ Gemini API.');
        }

        final cleanText = responseText.trim();
        final List<dynamic> decodedList = jsonDecode(cleanText);

        return decodedList.map((item) {
          return {
            'title_vi': (item['title_vi'] ?? '').toString(),
            'title_en': (item['title_en'] ?? '').toString(),
            'reason': (item['reason'] ?? '').toString(),
          };
        }).toList();
      } catch (e) {
        final errorStr = e.toString();
        
        // Nếu bị lỗi quá tải (503), lỗi quota (429) hoặc tạm thời không khả dụng
        if (errorStr.contains('503') || 
            errorStr.contains('429') || 
            errorStr.contains('RESOURCE_EXHAUSTED') || 
            errorStr.contains('UNAVAILABLE') || 
            errorStr.contains('busy') || 
            errorStr.contains('demand')) {
          
          retryCount++;
          if (retryCount < maxRetriesPerModel) {
            debugPrint('Model $currentModel error, retrying in ${delay.inSeconds} seconds... (Lần $retryCount/$maxRetriesPerModel)');
            await Future.delayed(delay);
            delay = delay * 2;
            continue;
          }
        }
        
        // Nếu đã thử lại hết số lần cho model hiện tại hoặc gặp các lỗi khác (ví dụ: 404, 403), chuyển sang model tiếp theo
        debugPrint('Model $currentModel failed: $e. Trying next model if available...');
        modelIndex++;
        retryCount = 0; // Reset số lần thử lại cho model mới
        delay = const Duration(seconds: 1); // Reset delay
      }
    }

    throw Exception('Tất cả các mô hình Gemini hiện tại đều đang quá tải hoặc không khả dụng. Vui lòng thử lại sau ít phút.');
  }
}
