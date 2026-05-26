import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/comic_provider.dart';
import '../widgets/comic_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _featuredStartIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ComicProvider>().loadHomeComics();
      context.read<ComicProvider>().loadPagedComics(1);
    });
  }

  void _moveFeaturedPair(int delta, int itemCount) {
    if (itemCount <= 1) return;
    setState(() {
      _featuredStartIndex = (_featuredStartIndex + delta + itemCount) % itemCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P Comic'),
      ),
      body: Consumer<ComicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.pagedComics.isEmpty) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Truyện hay',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final featured = provider.randomComics;
                  if (featured.isEmpty) return const SizedBox.shrink();

                  final leftIndex = _featuredStartIndex % featured.length;
                  final rightIndex = (leftIndex + 1) % featured.length;
                  final leftComic = featured[leftIndex];
                  final rightComic = featured[rightIndex];

                  String _formatSubtitle(String? raw) {
                    if (raw == null || raw.trim().isEmpty) return 'Sắp ra';
                    final m = RegExp(r"(\d+)").firstMatch(raw);
                    if (m != null) return 'Chương ${m.group(1)}';
                    return raw;
                  }

                  // ensure we have latest chapter info cached for visible cards
                  if (!provider.latestChapterNames.containsKey(leftComic.slug)) {
                    // fire and forget
                    Future.microtask(() => context.read<ComicProvider>().loadLatestChapter(leftComic.slug));
                  }
                  if (!provider.latestChapterNames.containsKey(rightComic.slug)) {
                    Future.microtask(() => context.read<ComicProvider>().loadLatestChapter(rightComic.slug));
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const horizontalPadding = 16.0;
                      const cardGap = 12.0;
                      const verticalPadding = 12.0;
                      const gridAspectRatio = 0.62;

                      final cardWidth = (constraints.maxWidth - horizontalPadding - cardGap) / 2;
                      final cardHeight = cardWidth / gridAspectRatio;
                      final totalHeight = cardHeight + verticalPadding;

                      return SizedBox(
                        height: totalHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                        child: SizedBox(
                                        height: cardHeight,
                                        child: ComicCard(
                                          comic: leftComic,
                                          subtitle: _formatSubtitle(provider.latestChapterNames[leftComic.slug]),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: SizedBox(
                                        height: cardHeight,
                                        child: ComicCard(
                                          comic: rightComic,
                                          subtitle: _formatSubtitle(provider.latestChapterNames[rightComic.slug]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 10,
                              child: Center(
                                child: IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.85),
                                    foregroundColor: Colors.black,
                                    disabledBackgroundColor: Colors.white.withOpacity(0.70),
                                    disabledForegroundColor: Colors.black38,
                                    fixedSize: const Size(42, 42),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: featured.length > 1
                                      ? () => _moveFeaturedPair(-1, featured.length)
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              child: Center(
                                child: IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.85),
                                    foregroundColor: Colors.black,
                                    disabledBackgroundColor: Colors.white.withOpacity(0.70),
                                    disabledForegroundColor: Colors.black38,
                                    fixedSize: const Size(42, 42),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: featured.length > 1
                                      ? () => _moveFeaturedPair(1, featured.length)
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 24),
                const Text(
                  'Tất cả truyện',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.pagedComics.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    final comic = provider.pagedComics[index];
                    // ensure latest chapter cached for this grid item
                    if (!provider.latestChapterNames.containsKey(comic.slug)) {
                      Future.microtask(() => context.read<ComicProvider>().loadLatestChapter(comic.slug));
                    }
                    String _formatSubtitle(String? raw) {
                      if (raw == null || raw.trim().isEmpty) return 'Sắp ra';
                      final m = RegExp(r"(\d+)").firstMatch(raw);
                      if (m != null) return 'Chương ${m.group(1)}';
                      return raw;
                    }
                    return ComicCard(comic: comic, subtitle: _formatSubtitle(provider.latestChapterNames[comic.slug]));
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: provider.currentPage > 1 ? () {
                        provider.loadPagedComics(provider.currentPage - 1);
                      } : null,
                      child: const Text('Prev'),
                    ),
                    const SizedBox(width: 20),
                    Text('Page ${provider.currentPage}'),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        provider.loadPagedComics(provider.currentPage + 1);
                      },
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}