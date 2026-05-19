class RedingImage {
  final String imageFile;

  RedingImage({
    required this.imageFile,
  });
  factory RedingImage.fromJson(Map<String, dynamic> json) {
    return RedingImage(
      imageFile: json['image_file'] ?? '',
    );
  }
}

class ReadingChapter {
  final String domainCdn;
  final String chapterPath;
  final List<RedingImage> images;

  ReadingChapter({
    required this.domainCdn,
    required this.chapterPath,
    required this.images,
  });

  factory ReadingChapter.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final item = data['item'];
    return ReadingChapter(
      domainCdn: data['domain_cdn'] ?? '',
      chapterPath: item['chapter_path'] ?? '',
      images: (item['chapter_image'] as List)
          .map((e) => RedingImage.fromJson(e))
          .toList(),
    );
  }
}