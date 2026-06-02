import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../providers/favorite_provider.dart';
import '../providers/history_provider.dart';
import '../models/comic_model.dart';
import '../providers/detail_provider.dart';
import 'reading_screen.dart';

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
    Future.microtask(() {
      context.read<HistoryProvider>().recordHistory(
        comicId: widget.comic.id,
        name: widget.comic.name,
        slug: widget.comic.slug,
        thumbUrl: widget.comic.thumbUrl,
      );
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF6FFF6), Color(0xFFF4F1E7)],
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Top Navigation
                            SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _HeaderIconButton(
                                    icon: Icons.arrow_back,
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Sharp Cover Image (70% of screen width)
                            Builder(
                              builder: (context) {
                                final screenWidth = MediaQuery.of(context).size.width;
                                final coverWidth = screenWidth * 0.70;
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
                                      fit: BoxFit.cover,
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
                                            apiUrl:
                                                comic.chapters.first.apiData,
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
                                  await favoriteProvider.toggleFavorite(
                                    comicId: widget.comic.id,
                                    name: widget.comic.name,
                                    slug: widget.comic.slug,
                                    thumbUrl: widget.comic.thumbUrl,
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
                          color: Colors.white,
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
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Colors.black87,
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
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Danh sách chương',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${comic.chapters.length} chương',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
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
                            color: Colors.white,
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
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final chapter = comic.chapters[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                              title: Text(
                                chapter.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReadingScreen(apiUrl: chapter.apiData),
                                  ),
                                );
                              },
                            ),
                          );
                        }, childCount: comic.chapters.length),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
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
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}
