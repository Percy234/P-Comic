import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../providers/favorite_provider.dart';
import '../providers/history_provider.dart';
import '../models/comic_model.dart';
import '../providers/detail_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/shimmer_placeholder.dart';
import 'reading_screen.dart';
import 'login_screen.dart';

class DetailScreen extends StatefulWidget {
  final Comic comic;
  const DetailScreen({super.key, required this.comic});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DetailProvider>().loadDetail(widget.comic.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Consumer<DetailProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final comic = provider.comicDetail;
          if (comic == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }
          final statusLabel = _formatStatus(comic.status);
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                        : [const Color(0xFFF6FFF6), const Color(0xFFF4F1E7)],
                  ),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        // Blurred Background Cover Image
                        Positioned.fill(
                          child: Image.network(
                            comic.imageUrl,
                            fit: BoxFit.cover,
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: child,
                              );
                            },
                          ),
                        ),
                        Positioned.fill(
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.35),
                                      Colors.black.withOpacity(0.85),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Foreground Content
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SafeArea(
                                bottom: false,
                                child: SizedBox(height: 48),
                              ),
                              // Sharp Cover Image (60% of screen width)
                              Builder(
                                builder: (context) {
                                  final screenWidth = MediaQuery.of(context).size.width;
                                  final coverWidth = screenWidth * 0.60;
                                  final coverHeight = coverWidth * 1.45;
                                  return Container(
                                    width: coverWidth,
                                    height: coverHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        comic.imageUrl,
                                        width: coverWidth,
                                        height: coverHeight,
                                        fit: BoxFit.cover,
                                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                          if (wasSynchronouslyLoaded) return child;
                                          final isLoaded = frame != null;
                                          return AnimatedCrossFade(
                                            firstChild: SizedBox(
                                              width: coverWidth,
                                              height: coverHeight,
                                              child: ShimmerPlaceholder(
                                                borderRadius: const BorderRadius.all(Radius.circular(12)),
                                                enabled: !isLoaded,
                                              ),
                                            ),
                                            secondChild: child,
                                            crossFadeState: !isLoaded
                                                ? CrossFadeState.showFirst
                                                : CrossFadeState.showSecond,
                                            duration: const Duration(milliseconds: 300),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey,
                                            child: const Icon(
                                              Icons.broken_image,
                                              size: 48,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              // Comic Title
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  comic.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Comic Metadata Chips
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _MetaChip(
                                      icon: Icons.person_outline,
                                      label: comic.author,
                                    ),
                                    _MetaChip(
                                      icon: Icons.circle,
                                      label: statusLabel,
                                      iconColor: _statusColor(comic.status),
                                    ),
                                    _MetaChip(
                                      icon: Icons.menu_book,
                                      label: '${comic.chapters.length} chương',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Đọc ngay',
                              icon: Icons.play_arrow,
                              background: const Color(0xFF1B5E20),
                              onPressed: comic.chapters.isEmpty
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReadingScreen(
                                            apiUrl: comic.chapters.first.apiData,
                                            comicId: widget.comic.id,
                                            name: comic.name,
                                            slug: widget.comic.slug,
                                            thumbUrl: comic.thumbUrl,
                                            chapterName: comic.chapters.first.name,
                                            chapters: comic.chapters,
                                            currentIndex: 0,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'Chương mới',
                              icon: Icons.flash_on,
                              background: const Color(0xFF0E3B2E),
                              onPressed: comic.chapters.isEmpty
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReadingScreen(
                                            apiUrl: comic.chapters.last.apiData,
                                            comicId: widget.comic.id,
                                            name: comic.name,
                                            slug: widget.comic.slug,
                                            thumbUrl: comic.thumbUrl,
                                            chapterName: comic.chapters.last.name,
                                            chapters: comic.chapters,
                                            currentIndex: comic.chapters.length - 1,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Center(
                        child: SizedBox(
                          width: 180,
                          child: Builder(
                            builder: (context) {
                              final favoriteProvider = context.watch<FavoriteProvider>();
                              final isFavorite = favoriteProvider.isFavoriteComic(widget.comic.id);
                              return _ActionButton(
                                label: isFavorite
                                    ? 'Đã thích'
                                    : 'Thích',

                                icon: isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,

                                background: isFavorite
                                    ? const Color(0xFFC62828)
                                    : const Color(0xFFFF9EBE),

                                onPressed: () async {
                                  final auth = context.read<AuthProvider>();
                                  if (!auth.isLoggedIn) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        elevation: 10,
                                        backgroundColor: Theme.of(context).cardColor,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Beautiful icon container with gradient ring and shadow
                                              Container(
                                                width: 76,
                                                height: 76,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFFFE0B2), Color(0xFFFFF3E0)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFFF57C00).withOpacity(0.12),
                                                      blurRadius: 16,
                                                      offset: const Offset(0, 6),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    width: 52,
                                                    height: 52,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.favorite_rounded,
                                                      color: Colors.white,
                                                      size: 28,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              // Title
                                              Text(
                                                'Yêu cầu đăng nhập',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              // Description
                                              Text(
                                                'Vui lòng đăng nhập tài khoản để lưu lại truyện yêu thích và đồng bộ hóa tủ sách của bạn.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  height: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              // Action Buttons
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () => Navigator.pop(context),
                                                      hoverColor: const Color(0xFFFFCDD2), // Đỏ nhạt đậm hơn chút khi hover
                                                      borderRadius: BorderRadius.circular(14),
                                                        child: Ink(
                                                          decoration: BoxDecoration(
                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.grey[800]
                                                                : Colors.grey[50],
                                                            borderRadius: BorderRadius.circular(14),
                                                            border: Border.all(
                                                              color: Theme.of(context).brightness == Brightness.dark
                                                                  ? Colors.grey[700]!
                                                                  : Colors.grey[200]!,
                                                            ),
                                                          ),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          alignment: Alignment.center,
                                                          child: Text(
                                                            'Để sau',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: InkWell(
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) => const LoginScreen(),
                                                          ),
                                                        );
                                                      },
                                                      borderRadius: BorderRadius.circular(14),
                                                      child: Ink(
                                                        decoration: BoxDecoration(
                                                          gradient: const LinearGradient(
                                                            colors: [Color(0xFFF57C00), Color(0xFFE65100)],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          ),
                                                          borderRadius: BorderRadius.circular(14),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: const Color(0xFFE65100).withOpacity(0.25),
                                                              blurRadius: 10,
                                                              offset: const Offset(0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          alignment: Alignment.center,
                                                          child: const Text(
                                                            'Đăng nhập',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.w700,
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await favoriteProvider.toggleFavorite(
                                    comicId: widget.comic.id,
                                    name: widget.comic.name,
                                    slug: widget.comic.slug,
                                    thumbUrl: widget.comic.thumbUrl,
                                    author: comic.author,
                                    genres: comic.categories.map((c) => c.name).join(', '),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giới thiệu',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DefaultTextStyle(
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                              child: Html(
                                data: comic.content,
                                style: {
                                  'body': Style(
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                  ),
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
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
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Danh sách chương',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  '${comic.chapters.length} chương',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (comic.chapters.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF1B5E20).withOpacity(0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Đang cập nhật',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        child: Container(
                          height: 320,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFF1B5E20).withOpacity(0.08),
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: comic.chapters.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.04),
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final chapter = comic.chapters[comic.chapters.length - 1 - index];
                                final rawName = chapter.name;
                                final displayChapterName = rawName.toLowerCase().startsWith('chương') || 
                                                           rawName.toLowerCase().startsWith('chap')
                                    ? rawName
                                    : 'Chương $rawName';
                                
                                final formattedDate = _formatDate(widget.comic.updatedAt);

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  title: Text(
                                    displayChapterName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  trailing: Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  onTap: () {
                                    final originalIndex = comic.chapters.length - 1 - index;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReadingScreen(
                                          apiUrl: chapter.apiData,
                                          comicId: widget.comic.id,
                                          name: comic.name,
                                          slug: widget.comic.slug,
                                          thumbUrl: comic.thumbUrl,
                                          chapterName: chapter.name,
                                          chapters: comic.chapters,
                                          currentIndex: originalIndex,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _HeaderIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(raw);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      return '$day/$month/$year';
    } catch (_) {
      return '';
    }
  }

  static String _formatStatus(String raw) {
    if (raw.isEmpty) return 'Đang cập nhật';
    switch (raw.toLowerCase()) {
      case 'completed':
        return 'Đã hoàn thành';
      case 'ongoing':
        return 'Đang phát hành';
      case 'coming_soon':
        return 'Sắp ra mắt';
      default:
        return raw;
    }
  }

  static Color _statusColor(String raw) {
    switch (raw.toLowerCase()) {
      case 'completed':
        return const Color(0xFFFFB300);
      case 'ongoing':
        return const Color(0xFF66BB6A);
      case 'coming_soon':
        return const Color(0xFF42A5F5);
      default:
        return Colors.white;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _MetaChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF57C00),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: const Color(0xFFF57C00).withOpacity(0.3),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}
