import 'package:timeago/timeago.dart' as timeago;

class Comic {
  final String id;
  final String name;
  final String slug;
  final String thumbUrl;
  final String status;
  final String updatedAt;

  Comic({
    required this.id,
    required this.name,
    required this.slug,
    required this.thumbUrl,
    required this.status,
    required this.updatedAt,
  });

  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      thumbUrl: json['thumb_url'] ?? '',
      status: json['status'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  String get imageUrl => 'https://img.otruyenapi.com/uploads/comics/$thumbUrl';
  String get timeAgo {
    final dateTime = DateTime.parse(updatedAt);
    return timeago.format(dateTime, locale: 'vi');
  }
}