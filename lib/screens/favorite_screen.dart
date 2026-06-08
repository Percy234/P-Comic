import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/background_decorations.dart';
import '../widgets/shimmer_placeholder.dart';
import '../models/comic_genre_model.dart';
import '../models/comic_model.dart';
import '../providers/favorite_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_header.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FavoriteProvider>().loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundDecorations(),
          SafeArea(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => context.read<FavoriteProvider>().loadFavorites(),
                  child: Consumer<FavoriteProvider>(
                    builder: (context, provider, child) {
                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: CommonHeader(
                                controller: _searchController,
                                onSearchChanged: (query) {
                                  setState(() {
                                    _searchQuery = query;
                                  });
                                },
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                                    'Truyện yêu thích',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!auth.isLoggedIn)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.favorite_outline_rounded,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Vui lòng đăng nhập để xem danh sách yêu thích',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF57C00),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Đăng nhập ngay',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (auth.isLoggedIn) ...[
                            if (provider.favorites.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(
                                              0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.favorite_border,
                                            size: 36,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Chưa có truyện yêu thích',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Hãy lưu lại những bộ truyện bạn muốn theo dõi để xem nhanh ở đây.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((context, index) {
                                    final item = provider.favorites[index];
                                    final name = item['name'] ?? '';
                                    final thumbUrl = item['thumbUrl'] ?? '';
                                    final author = item['author'] ?? 'Đang cập nhật';
                                    final genres = item['genres'] ?? '';
                                    final addedAt = _formatAddedAt(item['addedAt']);
                                    return _FavoriteListCard(
                                      name: name,
                                      imageUrl:
                                          'https://img.otruyenapi.com/uploads/comics/$thumbUrl',
                                      author: author,
                                      genres: genres,
                                      addedAt: addedAt,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DetailScreen(comic: _mapToComic(item)),
                                          ),
                                        );
                                      },
                                      onRemove: () {
                                        final comicId = item['comicId'] ?? '';
                                        if (comicId.isEmpty) return;
                                        context.read<FavoriteProvider>().removeFavoriteById(
                                          comicId,
                                        );
                                      },
                                    );
                                  }, childCount: provider.favorites.length),
                                ),
                              ),
                          ],
                        ],
                      );
                    },
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
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAddedAt(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(raw);
      return timeago.format(dateTime, locale: 'vi');
    } catch (_) {
      return '';
    }
  }

  static Comic _mapToComic(Map<String, dynamic> data) {
    return Comic(
      id: data['comicId'] ?? '',
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      thumbUrl: data['thumbUrl'] ?? '',
      status: '',
      updatedAt: DateTime.now().toIso8601String(),
      categories: const <ComicGenre>[],
    );
  }
}

class _FavoriteListCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String author;
  final String genres;
  final String addedAt;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteListCard({
    required this.name,
    required this.imageUrl,
    required this.author,
    required this.genres,
    required this.addedAt,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 85,
                    height: 120,
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedCrossFade(
                        firstChild: const ShimmerPlaceholder(
                          width: 85,
                          height: 120,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        secondChild: child,
                        crossFadeState: frame == null
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 85,
                      height: 120,
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and unfavorite button in a row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: labelColor,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onRemove,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.favorite,
                                size: 22,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Author
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 15,
                          color: subtextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tác giả: $author',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: subtextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Genres
                    if (genres.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 15,
                            color: subtextColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Thể loại: $genres',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: subtextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Saved date
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: subtextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          addedAt.isEmpty ? 'Đã lưu' : 'Đã lưu $addedAt',
                          style: TextStyle(
                            fontSize: 13,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
