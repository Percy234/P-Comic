import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';
import '../providers/history_provider.dart';
import '../models/chapter_model.dart';

class ReadingScreen extends StatefulWidget {
  final String apiUrl;
  final String comicId;
  final String name;
  final String slug;
  final String thumbUrl;
  final String chapterName;
  final List<Chapter>? chapters;
  final int? currentIndex;

  const ReadingScreen({
    super.key,
    required this.apiUrl,
    required this.comicId,
    required this.name,
    required this.slug,
    required this.thumbUrl,
    required this.chapterName,
    this.chapters,
    this.currentIndex,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late String _currentApiUrl;
  late String _currentChapterName;
  late int _currentIndex;

  bool _showOverlays = true;
  Timer? _hideTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentApiUrl = widget.apiUrl;
    _currentChapterName = widget.chapterName;
    _currentIndex = widget.currentIndex ?? -1;

    _loadAndRecord();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadAndRecord() {
    Future.microtask(() {
      context.read<ReadingProvider>().loadChapter(_currentApiUrl);
    });
    Future.microtask(() {
      context.read<HistoryProvider>().recordHistory(
            comicId: widget.comicId,
            name: widget.name,
            slug: widget.slug,
            thumbUrl: widget.thumbUrl,
            chapterName: _currentChapterName,
          );
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showOverlays) {
        setState(() {
          _showOverlays = false;
        });
      }
    });
  }

  void _toggleOverlays() {
    setState(() {
      _showOverlays = !_showOverlays;
    });
    if (_showOverlays) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _navigateToChapter(int index) {
    if (widget.chapters == null || index < 0 || index >= widget.chapters!.length) return;

    setState(() {
      _currentIndex = index;
      final nextChapter = widget.chapters![index];
      _currentApiUrl = nextChapter.apiData;
      _currentChapterName = nextChapter.name;
      _showOverlays = true;
    });

    _loadAndRecord();

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    _startHideTimer();
  }

  void _showChapterList(BuildContext context) {
    if (widget.chapters == null || widget.chapters!.isEmpty) return;

    _hideTimer?.cancel();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final size = MediaQuery.of(context).size;
        
        return Container(
          height: size.height * 0.65,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Danh sách chương',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.chapters!.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                    indent: 24,
                    endIndent: 24,
                  ),
                  itemBuilder: (context, index) {
                    final originalIndex = widget.chapters!.length - 1 - index;
                    final chapter = widget.chapters![originalIndex];
                    final isCurrent = originalIndex == _currentIndex;
                    final rawName = chapter.name;
                    final displayChapterName = rawName.toLowerCase().startsWith('chương') ||
                                               rawName.toLowerCase().startsWith('chap')
                        ? rawName
                        : 'Chương $rawName';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                      title: Text(
                        displayChapterName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? const Color(0xFFF57C00)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      trailing: isCurrent
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFFF57C00),
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToChapter(originalIndex);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _startHideTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasNavigation = widget.chapters != null && _currentIndex != -1;
    final isFirstChapter = _currentIndex == 0;
    final isLastChapter = widget.chapters != null && _currentIndex == widget.chapters!.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content Layer (Tapping toggles overlays)
          GestureDetector(
            onTap: _toggleOverlays,
            behavior: HitTestBehavior.opaque,
            child: Consumer<ReadingProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFFF57C00),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Đang tải chương truyện...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final chapter = provider.chapter;
                if (chapter == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Không tải được dữ liệu chương',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF57C00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _loadAndRecord,
                          child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 50,
                    bottom: MediaQuery.of(context).padding.bottom + 60,
                  ),
                  itemCount: chapter.images.length,
                  itemBuilder: (context, index) {
                    final image = chapter.images[index];
                    final imageUrl = '${chapter.domainCdn}/${chapter.chapterPath}/${image.imageFile}';
                    return Image.network(
                      imageUrl,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.fitWidth,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 350,
                          color: Colors.black,
                          child: Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: const Color(0xFFF57C00),
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 250,
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Glassmorphic Top Bar Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _showOverlays ? 0 : -110,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      // Back Button
                      Material(
                        color: const Color(0xFFF57C00),
                        shape: const CircleBorder(),
                        elevation: 4,
                        shadowColor: const Color(0xFFF57C00).withOpacity(0.3),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Comic Details only
                      Expanded(
                        child: Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Glassmorphic Bottom Control Panel Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _showOverlays ? 0 : -90,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(
                    top: 10,
                    bottom: MediaQuery.of(context).padding.bottom + 10,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Chapter Button
                      Opacity(
                        opacity: (hasNavigation && !isFirstChapter) ? 1.0 : 0.4,
                        child: InkWell(
                          onTap: (hasNavigation && !isFirstChapter)
                              ? () => _navigateToChapter(_currentIndex - 1)
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  'Chương trước',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Center Chapter Name/Number
                      Expanded(
                        child: InkWell(
                          onTap: (widget.chapters != null && widget.chapters!.isNotEmpty)
                              ? () => _showChapterList(context)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Text(
                              _currentChapterName.toLowerCase().startsWith('chương') ||
                                      _currentChapterName.toLowerCase().startsWith('chap')
                                  ? _currentChapterName
                                  : 'Chương $_currentChapterName',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Next Chapter Button
                      Opacity(
                        opacity: (hasNavigation && !isLastChapter) ? 1.0 : 0.4,
                        child: InkWell(
                          onTap: (hasNavigation && !isLastChapter)
                              ? () => _navigateToChapter(_currentIndex + 1)
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  'Chương sau',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}