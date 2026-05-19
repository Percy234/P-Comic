import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';

class ReadingScreen extends StatefulWidget {
  final String apiUrl;
  const ReadingScreen({
    super.key,
    required this.apiUrl,
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