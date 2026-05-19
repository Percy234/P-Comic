import 'chapter_model.dart';

class ComicDetail {
  final String name;
  final String author;
  final String content;
  final String status;
  final String thumbUrl;
  final List<Chapter> chapters;

  ComicDetail({
    required this.name,
    required this.author,
    required this.content,
    required this.status,
    required this.thumbUrl,
    required this.chapters,
  });

  factory ComicDetail.fromJson(Map<String, dynamic> json) {
    List<Chapter> chapterList = [];
    if (json['chapters'] != null && json['chapters'].isNotEmpty) {
      final serverData = json['chapters'][0]['server_data'];
      chapterList = (serverData as List).map((e) => Chapter.fromJson(e)).toList();
    }
    return ComicDetail(
      name: json['name'] ?? '',
      author: (json['author'] != null && json['author'].isNotEmpty) ? json['author'][0] : 'Đang cập nhật',
      content: json['content'] ?? '',
      status: json['status'] ?? '',
      thumbUrl: json['thumb_url'] ?? '',
      chapters: chapterList,
    );
  }
  String get imageUrl => 'https://img.otruyenapi.com/uploads/comics/$thumbUrl';
}