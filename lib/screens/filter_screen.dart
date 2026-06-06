import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/background_decorations.dart';

import '../models/comic_genre_model.dart';
import '../models/comic_response_model.dart';
import '../providers/comic_provider.dart';
import '../widgets/comic_card.dart';
import '../widgets/common_header.dart';
import '../services/api_service.dart';

class FilterScreen extends StatefulWidget {
  final String filterTitle;
  final int startPage;
  final bool expandGenres;
  final List<String> initialStatuses;
  final bool showBottomNav;
  const FilterScreen({
    super.key,
    required this.filterTitle,
    this.startPage = 1,
    this.expandGenres = false,
    this.initialStatuses = const [],
    this.showBottomNav = true,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List localComics = <dynamic>[];
  List<ComicGenre> _genres = <ComicGenre>[];
  final Set<String> _selectedGenreSlugs = <String>{};
  final Set<String> _selectedStatusValues = <String>{};
  bool _genresExpanded = false;
  bool _loadingLocal = false;
  int _localPage = 1;

  static const int _statusPageBatchSize = 3;

  static const List<_StatusOption> _statusOptions = [
    _StatusOption(value: 'ongoing', label: 'Đang phát hành'),
    _StatusOption(value: 'coming_soon', label: 'Sắp ra mắt'),
    _StatusOption(value: 'completed', label: 'Đã hoàn thành'),
  ];

  @override
  void initState() {
    super.initState();
    _localPage = widget.startPage;
    _genresExpanded = widget.expandGenres;
    _selectedStatusValues.addAll(widget.initialStatuses);
    _loadGenres();
    _loadLocalPage(_localPage);
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _api.fetchGenres();
      if (!mounted) return;
      setState(() {
        _genres = genres;
      });
    } catch (e) {
      // keep the screen usable even if genre loading fails
    }
  }

  Future<void> _loadLocalPage(int page) async {
    setState(() => _loadingLocal = true);
    try {
      final selectedGenres = _selectedGenreSlugs.toList();
      final selectedStatuses = _selectedStatusValues.toList();
      List<dynamic> loadedComics;
      final responses = <ComicResponse>[];

      final useStatusBatch = selectedStatuses.isNotEmpty && selectedGenres.isEmpty;
      if (useStatusBatch) {
        final statusPageResponses = await Future.wait(
          List.generate(_statusPageBatchSize, (index) {
            final pageToLoad = page + index;
            if (selectedStatuses.length == 1 && selectedStatuses.contains('completed')) {
              return _api.fetchCompletedComics(pageToLoad);
            }
            return _api.fetchPagedComics(pageToLoad);
          }),
        );
        responses.addAll(statusPageResponses);
      } else if (selectedGenres.isEmpty) {
        responses.add(await _api.fetchPagedComics(page));
      } else {
        responses.addAll(
          await Future.wait(
            selectedGenres.map((genreSlug) => _api.fetchComicsByGenre(genreSlug, page)),
          ),
        );

        if (selectedStatuses.contains('completed')) {
          responses.add(await _api.fetchCompletedComics(page));
        }
      }

      final uniqueComics = <String, dynamic>{};
      for (final response in responses) {
        for (final comic in response.comics) {
          uniqueComics[comic.id] = comic;
        }
      }

      loadedComics = uniqueComics.values.toList();
      if (responses.isNotEmpty) {
        _localPage = page;
      }

      if (selectedGenres.isEmpty && selectedStatuses.isEmpty) {
        final resp = responses.first;
        loadedComics = resp.comics;
        _localPage = resp.currentPage;
      } else if (useStatusBatch) {
        _localPage = page;
      }

      localComics = _applyLocalFilters(loadedComics);
    } catch (e) {
      // keep localComics as-is
    }
    setState(() => _loadingLocal = false);
    if (!mounted || !_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _toggleGenre(String slug) async {
    setState(() {
      if (_selectedGenreSlugs.contains(slug)) {
        _selectedGenreSlugs.remove(slug);
      } else {
        _selectedGenreSlugs.add(slug);
      }
    });
    await _loadLocalPage(1);
  }

  Future<void> _toggleStatus(String value) async {
    setState(() {
      if (_selectedStatusValues.contains(value)) {
        _selectedStatusValues.remove(value);
      } else {
        _selectedStatusValues.add(value);
      }
    });
    await _loadLocalPage(1);
  }

  void _toggleGenrePanel() {
    setState(() {
      _genresExpanded = !_genresExpanded;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<dynamic> _applyLocalFilters(List<dynamic> comics) {
    return comics.where((comic) {
      final matchesGenre = _selectedGenreSlugs.isEmpty || comic.hasAnyCategory(_selectedGenreSlugs);
      final rawStatus = comic.status?.toString().trim() ?? '';
      final matchesStatus = _selectedStatusValues.isEmpty || _selectedStatusValues.contains(rawStatus);

      return matchesGenre && matchesStatus;
    }).toList();
  }


  String _formatSubtitle(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Sắp ra';
    final match = RegExp(r'(\d+)').firstMatch(raw);
    if (match != null) return 'Chương ${match.group(1)}';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComicProvider>();
    final hasActiveFilters = _selectedGenreSlugs.isNotEmpty || _selectedStatusValues.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundDecorations(),
          _loadingLocal && localComics.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  'Bộ lọc nâng cao',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            if (hasActiveFilters)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedGenreSlugs.clear();
                                    _selectedStatusValues.clear();
                                  });
                                  _loadLocalPage(1);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFC62828),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                                label: const Text(
                                  'Đặt lại',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _toggleGenrePanel,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        'Chọn thể loại',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey[800],
                                        ),
                                      ),
                                      if (_selectedGenreSlugs.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFC62828).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${_selectedGenreSlugs.length}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFC62828),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _genresExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 180),
                                  child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueGrey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              if (_genres.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12, top: 4),
                                  child: Text(
                                    'Đang tải danh sách thể loại...',
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _genres.map((genre) {
                                    final selected = _selectedGenreSlugs.contains(genre.slug);
                                    return GestureDetector(
                                      onTap: () => _toggleGenre(genre.slug),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: selected
                                              ? const LinearGradient(
                                                  colors: [Color(0xFFFF8A80), Color(0xFFC62828)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: selected ? null : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: selected ? Colors.transparent : Colors.black12,
                                            width: 1,
                                          ),
                                          boxShadow: selected
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFFC62828).withOpacity(0.25),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 3),
                                                  )
                                                ]
                                              : [],
                                        ),
                                        child: Text(
                                          genre.name,
                                          style: TextStyle(
                                            color: selected ? Colors.white : Colors.black87,
                                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                          crossFadeState: _genresExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 180),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Colors.black12),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Chọn trạng thái truyện',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[800],
                              ),
                            ),
                            if (_selectedStatusValues.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${_selectedStatusValues.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: _statusOptions.map((status) {
                            final selected = _selectedStatusValues.contains(status.value);
                            Color themeColor;
                            IconData iconData;

                            if (status.value == 'ongoing') {
                              themeColor = const Color(0xFF1565C0);
                              iconData = Icons.sync_rounded;
                            } else if (status.value == 'coming_soon') {
                              themeColor = const Color(0xFF2E7D32);
                              iconData = Icons.watch_later_outlined;
                            } else {
                              themeColor = const Color(0xFFF57C00);
                              iconData = Icons.check_circle_outline_rounded;
                            }

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => _toggleStatus(status.value),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? themeColor
                                          : themeColor.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected ? Colors.transparent : themeColor.withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: themeColor.withOpacity(0.25),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          iconData,
                                          color: selected ? Colors.white : themeColor,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          status.label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: selected ? Colors.white : themeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                Text(
                                  hasActiveFilters ? 'Kết quả lọc' : 'Tất cả truyện',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${localComics.length} truyện',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (localComics.isEmpty && !_loadingLocal)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Không tìm thấy truyện nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hãy thử thay đổi hoặc đặt lại bộ lọc của bạn',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedGenreSlugs.clear();
                                      _selectedStatusValues.clear();
                                    });
                                    _loadLocalPage(1);
                                  },
                                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                  label: const Text(
                                    'Đặt lại bộ lọc',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC62828),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: localComics.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.5,
                            ),
                            itemBuilder: (context, index) {
                              final comic = localComics[index];
                              if (!provider.latestChapterNames.containsKey(comic.slug)) {
                                Future.microtask(() => provider.loadLatestChapter(comic.slug));
                                return ComicCard(
                                  comic: comic,
                                  subtitle: 'Đang tải',
                                );
                              }
                              return ComicCard(
                                comic: comic,
                                subtitle: _formatSubtitle(provider.latestChapterNames[comic.slug]),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: _localPage > 1
                                        ? () => _loadLocalPage(_localPage - 1)
                                        : null,
                                    icon: const Icon(Icons.chevron_left_rounded),
                                    color: const Color(0xFFC62828),
                                    disabledColor: Colors.black26,
                                    style: IconButton.styleFrom(
                                      backgroundColor: _localPage > 1
                                          ? const Color(0xFFC62828).withOpacity(0.1)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC62828),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFC62828).withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Trang $_localPage',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () => _loadLocalPage(_localPage + 1),
                                    icon: const Icon(Icons.chevron_right_rounded),
                                    color: const Color(0xFFC62828),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFC62828).withOpacity(0.1),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
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
        ),
      ),
    ],
  ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              currentIndex: 1,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                if (index == 1) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Trang Chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.category_outlined),
                  activeIcon: Icon(Icons.category),
                  label: 'Thể loại',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.favorite),
                  label: 'Yêu Thích',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Lịch Sử',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Cá Nhân',
                ),
              ],
            )
          : null,
    );
  }
}

class _StatusOption {
  final String value;
  final String label;

  const _StatusOption({
    required this.value,
    required this.label,
  });
}

