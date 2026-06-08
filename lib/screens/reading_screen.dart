import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';
import '../providers/history_provider.dart';

class ReadingScreen extends StatefulWidget {
  final String apiUrl;
  final String comicId;
  final String name;
  final String slug;
  final String thumbUrl;
  final String chapterName;

  const ReadingScreen({
    super.key,
    required this.apiUrl,
    required this.comicId,
    required this.name,
    required this.slug,
    required this.thumbUrl,
    required this.chapterName,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context
          .read<ReadingProvider>()
          .loadChapter(widget.apiUrl);
    });
    Future.microtask(() {
      context.read<HistoryProvider>().recordHistory(
            comicId: widget.comicId,
            name: widget.name,
            slug: widget.slug,
            thumbUrl: widget.thumbUrl,
            chapterName: widget.chapterName,
          );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đọc truyện'), 
      ),
      body: Consumer<ReadingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final chapter = provider.chapter;
          if (chapter == null) {
            return const Center(
              child: Text('Không có dữ liệu'),
            );
          }
          return ListView.builder(
            itemCount: chapter.images.length,
            itemBuilder: (context, index) {
              final image = chapter.images[index];
              final imageUrl = '${chapter.domainCdn}/${chapter.chapterPath}/${image.imageFile}';
              return Image.network(
                imageUrl,
                fit: BoxFit.cover,
              );
            },
          );
        },
      ),
    );
  }
}