import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../providers/favorite_provider.dart';
import '../models/comic_model.dart';
import '../providers/detail_provider.dart';
import 'reading_screen.dart';

class DetailScreen extends StatefulWidget {
  final Comic comic;
  const DetailScreen({
    super.key,
    required this.comic,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context
          .read<DetailProvider>()
          .loadDetail(widget.comic.slug);
    });
    Future.microtask(() {
      context
          .read<FavoriteProvider>()
          .checkFavorite(widget.comic.id);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.comic.name), 
        actions: [
          Consumer<FavoriteProvider>(
            builder: (context, favoriteProvider, _) {
              return IconButton(
                onPressed: () async {
                  await favoriteProvider.toggleFavorite(
                    comicId: widget.comic.id,
                    name: widget.comic.name,
                    slug: widget.comic.slug,
                    thumbUrl: widget.comic.thumbUrl,
                  );
                },
                icon: Icon(
                  favoriteProvider.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: favoriteProvider.isFavorite ? Colors.red : null,
                ),
              );
            }
          )
        ],
      ),
      body: Consumer<DetailProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final comic = provider.comicDetail;
          if (comic == null) {
            return const Center(
              child: Text('Không có dữ liệu'),
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  comic.imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comic.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Tác giả: ${comic.author}'),
                      const SizedBox(height: 12),
                      Text('Trạng thái: ${comic.status}'),
                      const SizedBox(height: 12),
                      Html(data: comic.content),
                      const SizedBox(height: 24),
                      const Text(
                        'Danh sách chương',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comic.chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = comic.chapters[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.menu_book),
                              title: Text(chapter.name),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReadingScreen(
                                      apiUrl: chapter.apiData,
                                    ),
                                  ),
                                );
                              },
                              trailing: const Icon(Icons.arrow_forward_ios) ,
                            ),
                          );
                        }
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }
}