import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/comic_provider.dart';
import '../widgets/comic_card.dart';
import 'filter_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ComicProvider>().loadHomeComics();
      context.read<ComicProvider>().loadPagedComics(1);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
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
          // 3 hình tròn trang trí nền to hơn trải dài từ header đến footer (đậm hơn)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.16),
              ),
            ),
          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (value) {
                                        if (value.trim().isEmpty) {
                                          if (_debounce?.isActive ?? false) _debounce?.cancel();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                          context.read<ComicProvider>().searchComics('');
                                        } else {
                                          if (_debounce?.isActive ?? false) _debounce?.cancel();
                                          _debounce = Timer(const Duration(milliseconds: 500), () {
                                            setState(() {
                                              _searchQuery = value;
                                            });
                                            context.read<ComicProvider>().searchComics(value);
                                          });
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        hintText: 'Tìm kiếm...',
                                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                        context.read<ComicProvider>().searchComics('');
                                      },
                                      child: const Icon(Icons.close, color: Colors.grey, size: 18),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              // Xử lý đăng nhập
                            },
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFF57C00),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Text(
                            '|',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              // Xử lý đăng ký
                            },
                            child: const Text(
                              'Đăng ký',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FilterScreen(
                                        filterTitle: 'Thể loại',
                                        expandGenres: true,
                                        showBottomNav: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFilterCard(
                                  context: context,
                                  title: 'Đang phát hành',
                                  colors: [const Color(0xFF1E88E5), const Color(0xFF42A5F5)],
                                  icon: Icons.play_circle_fill_rounded,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FilterScreen(
                                        filterTitle: 'Thể loại',
                                        initialStatuses: ['ongoing'],
                                        showBottomNav: false,
                                      ),
                                    ),
                                  ),
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
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FilterScreen(
                                        filterTitle: 'Thể loại',
                                        initialStatuses: ['coming_soon'],
                                        showBottomNav: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFilterCard(
                                  context: context,
                                  title: 'Đã hoàn thành',
                                  colors: [const Color(0xFFF4511E), const Color(0xFFFF7043)],
                                  icon: Icons.verified_rounded,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FilterScreen(
                                        filterTitle: 'Thể loại',
                                        initialStatuses: ['completed'],
                                        showBottomNav: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  'Tất cả truyện',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            provider.pagedComics.isEmpty
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
                                      childAspectRatio: 0.5,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FilterScreen(
                                    filterTitle: 'Thể loại',
                                    startPage: 2,
                                    expandGenres: true,
                                    showBottomNav: true,
                                  ),
                                ),
                              );
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(top: 24, bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.amber.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Lưu ý: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          'Nội dung truyện trên ứng dụng được tổng hợp từ nhiều nguồn công khai trên Internet, chỉ nhằm mục đích giải trí. Mọi bản quyền thuộc về tác giả và nhà phát hành.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
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
                    ],
                  ),
                    ),
                    if (_searchQuery.trim().isNotEmpty)
                      Positioned(
                        top: 68,
                        left: 16,
                        right: 16,
                        child: _buildSearchResultsBox(provider),
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

  Widget _buildSearchResultsBox(ComicProvider provider) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: provider.isSearchLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ),
            )
          : provider.searchedComics.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Không tìm thấy truyện nào phù hợp',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  itemCount: provider.searchedComics.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final comic = provider.searchedComics[index];
                    if (!provider.latestChapterNames.containsKey(comic.slug)) {
                      Future.microtask(
                        () => provider.loadLatestChapter(comic.slug),
                      );
                    }
                    final latestChapter = provider.latestChapterNames[comic.slug] ?? '';
                    final genres = comic.categories.map((c) => c.name).join(', ');

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(comic: comic),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                comic.imageUrl,
                                width: 70,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 70,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    comic.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  if (latestChapter.isNotEmpty)
                                    Text(
                                      _formatSubtitle(latestChapter),
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    )
                                  else
                                    Text(
                                      comic.status == 'ongoing'
                                          ? 'Đang phát hành'
                                          : comic.status == 'completed'
                                              ? 'Đã hoàn thành'
                                              : 'Sắp ra mắt',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  if (genres.isNotEmpty)
                                    Text(
                                      genres,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
