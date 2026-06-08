import 'chapter_model.dart';
import 'comic_genre_model.dart';

class ComicDetail {
  final String name;
  final String author;
  final String content;
  final String status;
  final String thumbUrl;
  final List<Chapter> chapters;
  final List<ComicGenre> categories;

  ComicDetail({
    required this.name,
    required this.author,
    required this.content,
    required this.status,
    required this.thumbUrl,
    required this.chapters,
    required this.categories,
  });

  factory ComicDetail.fromJson(Map<String, dynamic> json) {
    List<Chapter> chapterList = [];
    if (json['chapters'] != null && json['chapters'].isNotEmpty) {
      final serverData = json['chapters'][0]['server_data'];
      chapterList = (serverData as List).map((e) => Chapter.fromJson(e)).toList();
    }

    final rawCategories = json['category'];
    final categoryList = rawCategories is List
        ? rawCategories
            .whereType<Map<String, dynamic>>()
            .map(ComicGenre.fromJson)
            .toList()
        : <ComicGenre>[];

    return ComicDetail(
      name: json['name'] ?? '',
      author: (json['author'] != null && json['author'].isNotEmpty) ? json['author'][0] : 'Đang cập nhật',
      content: json['content'] ?? '',
      status: json['status'] ?? '',
      thumbUrl: json['thumb_url'] ?? '',
      chapters: chapterList,
      categories: categoryList,
    );
  }
  String get imageUrl => 'https://img.otruyenapi.com/uploads/comics/$thumbUrl';
}