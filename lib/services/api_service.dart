import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/comic_model.dart';
import '../models/comic_genre_model.dart';
import '../models/comic_detail_model.dart';
import '../models/reading_model.dart';
import '../models/comic_response_model.dart';

class ApiService {
  static const String baseUrl = 'https://otruyenapi.com/v1/api';

  Future<List<Comic>> fetchHomeComics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/home'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List items = 
          data['data']['items'];

      return items 
        .map((item) => Comic.fromJson(item))
        .toList();
    } else {
      throw Exception(
        'Lỗi khi tải dữ liệu',
      );
    }
  }

  Future<ComicResponse> fetchPagedComics(int page) async {
    final response = await http.get(
      Uri.parse('$baseUrl/danh-sach/truyen-moi?page=$page'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ComicResponse.fromJson(data);
    } else {
      throw Exception(
        'Lỗi khi tải dữ liệu',
      );
    }
  }

  Future<ComicResponse> fetchCompletedComics(int page) async {
    final response = await http.get(
      Uri.parse('$baseUrl/danh-sach/hoan-thanh?page=$page'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ComicResponse.fromJson(data);
    } else {
      throw Exception(
        'Lỗi khi tải dữ liệu truyện hoàn thành',
      );
    }
  }

  Future<ComicResponse> fetchComicsByGenre(String genreSlug, int page) async {
    final response = await http.get(
      Uri.parse('$baseUrl/the-loai/$genreSlug?page=$page'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ComicResponse.fromJson(data);
    } else {
      throw Exception(
        'Lỗi khi tải dữ liệu thể loại',
      );
    }
  }

  Future<List<ComicGenre>> fetchGenres() async {
    final response = await http.get(
      Uri.parse('$baseUrl/the-loai'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['data']['items'] as List<dynamic>? ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(ComicGenre.fromJson)
          .toList();
    } else {
      throw Exception(
        'Lỗi khi tải danh sách thể loại',
      );
    }
  }

  Future<ComicDetail> fetchComicDetail(String slug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/truyen-tranh/$slug'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final item = data['data']['item'];
      return ComicDetail.fromJson(item,);
    } else {
      throw Exception(
        'Lỗi khi tải dữ liệu chi tiết',
      );
    }
  }
  Future<ReadingChapter> fetchChapter(String apiUrl) async {
    final response = await http.get(
      Uri.parse(apiUrl),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ReadingChapter.fromJson(data);
    } else {
      throw Exception(
        'Lỗi khi tải dữ liệu chương',
      );
    }
  }

  Future<ComicResponse> searchComics(String keyword, int page) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tim-kiem?keyword=$keyword&page=$page'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ComicResponse.fromJson(data);
    } else {
      throw Exception(
        'Lỗi khi tìm kiếm truyện',
      );
    }
  }
}