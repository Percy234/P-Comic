import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
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
      context.read<FavoriteProvider>().checkFavorite(widget.comic.id);
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
                    child: SizedBox(
                      height: 320,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(comic.imageUrl, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.2),
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            top: 12,
                            child: SafeArea(
                              bottom: false,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _HeaderIconButton(
                                    icon: Icons.arrow_back,
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final favoriteProvider = context
                                          .watch<FavoriteProvider>();
                                      return _HeaderIconButton(
                                        icon: favoriteProvider.isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        iconColor: favoriteProvider.isFavorite
                                            ? const Color(0xFFFF8A80)
                                            : Colors.white,
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
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comic.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
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
                              ],
                            ),
                          ),
                        ],
                      ),
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
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DefaultTextStyle(
                              style: GoogleFonts.sourceSans3(
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
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${comic.chapters.length} chương',
                            style: GoogleFonts.sourceSans3(
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                                style: GoogleFonts.sourceSans3(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                            title: Text(
                              chapter.name,
                              style: GoogleFonts.sourceSans3(
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
            style: GoogleFonts.sourceSans3(
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
        style: GoogleFonts.sourceSans3(fontWeight: FontWeight.w700),
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
