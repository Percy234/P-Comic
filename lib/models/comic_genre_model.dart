class ComicGenre {
  final String id;
  final String name;
  final String slug;

  ComicGenre({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ComicGenre.fromJson(Map<String, dynamic> json) {
    return ComicGenre(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}