import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/history_provider.dart';
import '../widgets/shimmer_placeholder.dart';
import '../providers/auth_provider.dart';
import '../widgets/background_decorations.dart';
import '../widgets/common_header.dart';
import '../widgets/require_login_placeholder.dart';
import '../models/comic_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'reading_screen.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isNavigating = false;

  void _resumeReading(BuildContext context, Map<String, dynamic> historyItem) async {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    // Hiển thị loading spinner dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFF57C00),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Đang tải chương...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final slug = historyItem['slug'] ?? '';
      final comicDetail = await ApiService().fetchComicDetail(slug);
      
      // Đóng loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (comicDetail.chapters.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy chương truyện này.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() {
          _isNavigating = false;
        });
        return;
      }

      // Tìm kiếm chương tương ứng với historyItem['chapterName']
      final targetChapterName = historyItem['chapterName'] ?? '';
      int matchedIndex = -1;
      
      for (int i = 0; i < comicDetail.chapters.length; i++) {
        if (comicDetail.chapters[i].name == targetChapterName) {
          matchedIndex = i;
          break;
        }
      }
      
      if (matchedIndex == -1) {
        for (int i = 0; i < comicDetail.chapters.length; i++) {
          final chName = comicDetail.chapters[i].name.toLowerCase();
          final target = targetChapterName.toLowerCase();
          if (chName.contains(target) || target.contains(chName)) {
            matchedIndex = i;
            break;
          }
        }
      }

      if (matchedIndex == -1) {
        matchedIndex = 0;
      }

      final chapter = comicDetail.chapters[matchedIndex];

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReadingScreen(
              apiUrl: chapter.apiData,
              comicId: comicDetail.id,
              name: comicDetail.name,
              slug: slug,
              thumbUrl: comicDetail.thumbUrl,
              chapterName: chapter.name,
              chapters: comicDetail.chapters,
              currentIndex: matchedIndex,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<HistoryProvider>().loadHistories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundDecorations(),
          SafeArea(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
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
                    Padding(
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
                            'Lịch sử đọc truyện',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Consumer<HistoryProvider>(
                        builder: (context, provider, child) {
                          if (!auth.isLoggedIn) {
                            return const RequireLoginPlaceholder(
                              icon: Icons.history_rounded,
                              title: 'Lịch Sử Đọc Truyện',
                              description: 'Đăng nhập tài khoản để đồng bộ và lưu trữ lịch sử đọc truyện của bạn trên mọi thiết bị.',
                            );
                          }

                          if (provider.histories.isEmpty) {
                            final theme = Theme.of(context);
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.history_rounded,
                                        size: 36,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Chưa có lịch sử đọc',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Những bộ truyện bạn đã đọc sẽ xuất hiện ở đây để bạn dễ dàng theo dõi tiếp.',
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
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: provider.histories.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final comic = provider.histories[index];
                              final rawChapterName = comic['chapterName'] ?? '1';
                              final displayChapterName = rawChapterName.toLowerCase().startsWith('chương') ||
                                                         rawChapterName.toLowerCase().startsWith('chap')
                                  ? rawChapterName
                                  : 'Chương $rawChapterName';

                              final comicModel = Comic(
                                id: comic['comicId'] ?? '',
                                name: comic['name'] ?? '',
                                slug: comic['slug'] ?? '',
                                thumbUrl: comic['thumbUrl'] ?? '',
                                status: '',
                                updatedAt: '',
                                categories: [],
                              );

                              String timeStr = '';
                              try {
                                if (comic['visitedAt'] != null) {
                                  timeStr = timeago.format(DateTime.parse(comic['visitedAt']), locale: 'vi');
                                }
                              } catch (e) {
                                timeStr = comic['visitedAt'] ?? '';
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
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
                                  onTap: () => _resumeReading(context, comic),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Comic Cover Image - Nhấn để vào chi tiết truyện
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => DetailScreen(comic: comicModel),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              'https://img.otruyenapi.com/uploads/comics/${comic['thumbUrl'] ?? ''}',
                                              width: 70,
                                              height: 95,
                                              fit: BoxFit.cover,
                                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                                if (wasSynchronouslyLoaded) return child;
                                                final isLoaded = frame != null;
                                                return AnimatedCrossFade(
                                                  firstChild: ShimmerPlaceholder(
                                                    width: 70,
                                                    height: 95,
                                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                                    enabled: !isLoaded,
                                                  ),
                                                  secondChild: child,
                                                  crossFadeState: !isLoaded
                                                      ? CrossFadeState.showFirst
                                                      : CrossFadeState.showSecond,
                                                  duration: const Duration(milliseconds: 300),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 70,
                                                height: 95,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey[900]
                                                    : Colors.grey[200],
                                                child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 2),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      comic['name'] ?? '',
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        height: 1.25,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) => DetailScreen(comic: comicModel),
                                                        ),
                                                      );
                                                    },
                                                    child: Icon(
                                                      Icons.info_outline_rounded,
                                                      size: 20,
                                                      color: Theme.of(context).brightness == Brightness.dark
                                                          ? Colors.white54
                                                          : Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final name = comic['name'] ?? '';
                                                      await context.read<HistoryProvider>().removeHistory(comic['comicId'] ?? '');
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).clearSnackBars();
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('Đã xóa "$name" khỏi lịch sử'),
                                                            duration: const Duration(seconds: 2),
                                                            behavior: SnackBarBehavior.floating,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: Icon(
                                                      Icons.delete_outline_rounded,
                                                      size: 20,
                                                      color: Colors.redAccent.withOpacity(0.8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Chapter Info Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF57C00).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(0xFFF57C00).withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.play_circle_outline_rounded,
                                                      color: Color(0xFFF57C00),
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Đã đọc $displayChapterName',
                                                      style: const TextStyle(
                                                        color: Color(0xFFF57C00),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              // Timeago Icon + Label
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    timeStr,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
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
                            },
                          );
                        },
                      ),
                    ),
                  ],
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
}
