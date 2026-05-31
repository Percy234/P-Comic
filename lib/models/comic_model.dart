import 'package:timeago/timeago.dart' as timeago;

import 'comic_genre_model.dart';

class Comic {
  final String id;
  final String name;
  final String slug;
  final String thumbUrl;
  final String status;
  final String updatedAt;
  final List<ComicGenre> categories;

  Comic({
    required this.id,
    required this.name,
    required this.slug,
    required this.thumbUrl,
    required this.status,
    required this.updatedAt,
    required this.categories,
  });

  factory Comic.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['category'];
    final categoryList = rawCategories is List
        ? rawCategories
            .whereType<Map<String, dynamic>>()
            .map(ComicGenre.fromJson)
            .toList()
        : <ComicGenre>[];

    return Comic(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      thumbUrl: json['thumb_url'] ?? '',
      status: json['status'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      categories: categoryList,
    );
  }

  String get imageUrl => 'https://img.otruyenapi.com/uploads/comics/$thumbUrl';
  String get timeAgo {
    final dateTime = DateTime.parse(updatedAt);
    return timeago.format(dateTime, locale: 'vi');
  }

  bool hasAnyCategory(Set<String> selectedSlugs) {
    if (selectedSlugs.isEmpty) return true;
    return categories.any((category) => selectedSlugs.contains(category.slug));
  }
}