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

  String _formatSubtitle(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Sắp ra';
    final match = RegExp(r'(\d+)').firstMatch(raw);
    if (match != null) return 'Chương ${match.group(1)}';
    return raw;
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(width: 6, color: Color(0xFF1B5E20)),
                      top: BorderSide(width: 1, color: Color(0xFF1B5E20)),
                      right: BorderSide(width: 1, color: Color(0xFF1B5E20)),
                      bottom: BorderSide(width: 1, color: Color(0xFF1B5E20)),
                    ),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Lưu ý: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              'Nội dung truyện trên ứng dụng được tổng hợp từ nhiều nguồn công khai trên Internet, chỉ nhằm mục đích giải trí. Mọi bản quyền thuộc về tác giả và nhà phát hành.',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment(0.4, 0.4),
                            colors: [Color(0xFFFF8A80), Color(0xFFC62828)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('Thể loại', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment(0.4, 0.4),
                            colors: [Color(0xFF82B1FF), Color(0xFF1565C0)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('Sắp ra mắt', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment(0.4, 0.4),
                            colors: [Color(0xFFA5D6A7), Color(0xFF2E7D32)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('Đang phát hành', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF57C00),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment(0.4, 0.4),
                            colors: [Color(0xFFFFCC80), Color(0xFFF57C00)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('Đã hoàn thành', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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

                  final firstIndex = _featuredStartIndex % featured.length;
                  final secondIndex = (firstIndex + 1) % featured.length;
                  final thirdIndex = (firstIndex + 2) % featured.length;
                  final firstComic = featured[firstIndex];
                  final secondComic = featured[secondIndex];
                  final thirdComic = featured[thirdIndex];

                  // ensure we have latest chapter info cached for visible cards
                  if (!provider.latestChapterNames.containsKey(firstComic.slug)) {
                    // fire and forget
                    Future.microtask(() => context.read<ComicProvider>().loadLatestChapter(firstComic.slug));
                  }
                  if (!provider.latestChapterNames.containsKey(secondComic.slug)) {
                    Future.microtask(() => context.read<ComicProvider>().loadLatestChapter(secondComic.slug));
                  }
                  if (!provider.latestChapterNames.containsKey(thirdComic.slug)) {
                    Future.microtask(() => context.read<ComicProvider>().loadLatestChapter(thirdComic.slug));
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const horizontalPadding = 16.0;
                      const cardGap = 12.0;
                      const verticalPadding = 8.0;
                      // make cards taller by using a smaller childAspectRatio
                      const gridAspectRatio = 0.5;

                      final cardWidth = (constraints.maxWidth - horizontalPadding - (cardGap * 2)) / 3;
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
                                          comic: firstComic,
                                          subtitle: _formatSubtitle(provider.latestChapterNames[firstComic.slug]),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: SizedBox(
                                        height: cardHeight,
                                        child: ComicCard(
                                          comic: secondComic,
                                          subtitle: _formatSubtitle(provider.latestChapterNames[secondComic.slug]),
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
                                          comic: thirdComic,
                                          subtitle: _formatSubtitle(provider.latestChapterNames[thirdComic.slug]),
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
                const SizedBox(height: 12),
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
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.5,
                  ),
                  itemBuilder: (context, index) {
                    final comic = provider.pagedComics[index];
                    // ensure latest chapter cached for this grid item
                    if (!provider.latestChapterNames.containsKey(comic.slug)) {
                      Future.microtask(() => context.read<ComicProvider>().loadLatestChapter(comic.slug));
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