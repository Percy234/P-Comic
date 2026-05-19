import 'comic_model.dart';

class ComicResponse {
  final List<Comic> comics;
  final int currentPage;
  final int totalItems;
  final int totalPerPage;

  ComicResponse({
    required this.comics,
    required this.currentPage,
    required this.totalItems,
    required this.totalPerPage,
  });

  factory ComicResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final pagination = data['params']['pagination'];
    return ComicResponse(
      comics: (data['items'] as List).map((e) => Comic.fromJson(e),).toList(),
      currentPage: pagination['currentPage'] ?? 1,
      totalItems: pagination['totalItems'] ?? 0,
      totalPerPage: pagination['totalItemsPerPage'] ?? 24,
    );
  }
}