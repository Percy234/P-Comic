import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/comic_provider.dart';
import '../widgets/comic_card.dart';
import '../widgets/common_header.dart';
import '../widgets/background_decorations.dart';
import '../providers/filter_provider.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onChangeTab;
  const HomeScreen({super.key, this.onChangeTab});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final comicProvider = context.read<ComicProvider>();
      if (comicProvider.pagedComics.isEmpty) {
        comicProvider.loadHomeComics();
        comicProvider.loadPagedComics(1);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          const BackgroundDecorations(),
          // Nội dung giao diện chính
          SafeArea(
            child: Consumer<ComicProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.pagedComics.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CommonHeader(
                                  controller: _searchController,
                                  onSearchChanged: (query) {
                                    setState(() {
                                      _searchQuery = query;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF57C00),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Thế Giới Truyện Tranh',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildFilterCard(
                                            context: context,
                                            title: 'Thể loại',
                                            colors: [const Color(0xFFE53935), const Color(0xFFE35D5B)],
                                            icon: Icons.category_rounded,
                                            onTap: () {
                                              context.read<FilterProvider>().openGenres();
                                              widget.onChangeTab?.call(1);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildFilterCard(
                                            context: context,
                                            title: 'Đang phát hành',
                                            colors: [const Color(0xFF1E88E5), const Color(0xFF42A5F5)],
                                            icon: Icons.play_circle_fill_rounded,
                                            onTap: () {
                                              context.read<FilterProvider>().setStatus('ongoing');
                                              widget.onChangeTab?.call(1);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildFilterCard(
                                            context: context,
                                            title: 'Sắp ra mắt',
                                            colors: [const Color(0xFF43A047), const Color(0xFF66BB6A)],
                                            icon: Icons.upcoming_rounded,
                                            onTap: () {
                                              context.read<FilterProvider>().setStatus('coming_soon');
                                              widget.onChangeTab?.call(1);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildFilterCard(
                                            context: context,
                                            title: 'Đã hoàn thành',
                                            colors: [const Color(0xFFF4511E), const Color(0xFFFF7043)],
                                            icon: Icons.verified_rounded,
                                            onTap: () {
                                              context.read<FilterProvider>().setStatus('completed');
                                              widget.onChangeTab?.call(1);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF57C00),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Tất cả truyện',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: provider.pagedComics.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 24),
                                          child: Center(
                                            child: Text(
                                              'Đang tải danh sách truyện...',
                                              style: TextStyle(color: Colors.grey, fontSize: 14),
                                            ),
                                          ),
                                        )
                                      : GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: provider.pagedComics.length,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.52,
                                          ),
                                          itemBuilder: (context, index) {
                                            final comic = provider.pagedComics[index];
                                            if (!provider.latestChapterNames.containsKey(
                                              comic.slug,
                                            )) {
                                              Future.microtask(
                                                () => context.read<ComicProvider>().loadLatestChapter(
                                                  comic.slug,
                                                ),
                                              );
                                            }
                                            return ComicCard(
                                              comic: comic,
                                              subtitle: _formatSubtitle(
                                                provider.latestChapterNames[comic.slug],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF57C00).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24)),
                                      ),
                                      onPressed: () {
                                        context.read<FilterProvider>().clear();
                                        widget.onChangeTab?.call(1);
                                      },
                                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                      label: const Text(
                                        'Xem thêm',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(top: 24, bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.amber.shade900.withOpacity(0.15)
                                    : Colors.amber.shade50.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.amber.shade800.withOpacity(0.4)
                                      : Colors.amber.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.amber.shade200
                                        : Colors.amber.shade800,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Lưu ý: ',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.amber.shade200
                                                  : Colors.amber,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                'Nội dung truyện trên ứng dụng được tổng hợp từ nhiều nguồn công khai trên Internet, chỉ nhằm mục đích giải trí. Mọi bản quyền thuộc về tác giả và nhà phát hành.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_searchQuery.trim().isNotEmpty)
                      Positioned(
                        top: 56,
                        left: 16,
                        right: 16,
                        child: SearchResultsBox(
                          searchQuery: _searchQuery,
                          onTapResult: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard({
    required BuildContext context,
    required String title,
    required List<Color> colors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
