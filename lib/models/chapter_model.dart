class Chapter {
  final String name;
  final String apiData;

  Chapter({
    required this.name,
    required this.apiData,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      name: json['chapter_name'] ?? '',
      apiData: json['chapter_api_data'] ?? '',
    );
  }
}