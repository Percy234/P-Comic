import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/comic_genre_model.dart';
import '../models/comic_response_model.dart';
import '../providers/comic_provider.dart';
import '../widgets/comic_card.dart';
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

  Future<void> _clearGenres() async {
    if (_selectedGenreSlugs.isEmpty) return;
    setState(() {
      _selectedGenreSlugs.clear();
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

  Future<void> _clearStatuses() async {
    if (_selectedStatusValues.isEmpty) return;
    setState(() {
      _selectedStatusValues.clear();
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.showBottomNav,
        title: Text(widget.filterTitle),
      ),
      body: _loadingLocal && localComics.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Bộ lọc',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Chọn thể loại',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: _toggleGenrePanel,
                              icon: AnimatedRotation(
                                turns: _genresExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 180),
                                child: const Icon(Icons.keyboard_arrow_down),
                              ),
                            ),
                          ],
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              if (_genres.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text('Đang tải danh sách thể loại...'),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _genres.map((genre) {
                                    final selected = _selectedGenreSlugs.contains(genre.slug);
                                    return FilterChip(
                                      selected: selected,
                                      showCheckmark: false,
                                      label: Text(genre.name),
                                      onSelected: (_) => _toggleGenre(genre.slug),
                                      selectedColor: const Color(0xFFF57C00).withOpacity(0.22),
                                      labelStyle: TextStyle(
                                        color: selected ? const Color(0xFFC62828) : Colors.black87,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Chọn trạng thái truyện',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: _statusOptions.map((status) {
                            final selected = _selectedStatusValues.contains(status.value);
                            final colors = _statusChipColors(status.value);
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilterChip(
                                    selected: selected,
                                    showCheckmark: false,
                                    label: Center(child: Text(status.label, textAlign: TextAlign.center)),
                                    onSelected: (_) => _toggleStatus(status.value),
                                    selectedColor: colors.selectedBackground,
                                    backgroundColor: colors.background,
                                    side: BorderSide(color: colors.border),
                                    labelStyle: TextStyle(
                                      color: selected ? colors.selectedText : colors.text,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
                  const SizedBox(height: 16),
                  Text(
                    'Tất cả truyện',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _localPage > 1 ? () => _loadLocalPage(_localPage - 1) : null,
                        child: const Text('Prev'),
                      ),
                      const SizedBox(width: 20),
                      Text('Page $_localPage'),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () => _loadLocalPage(_localPage + 1),
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
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

class _StatusChipColors {
  final Color background;
  final Color selectedBackground;
  final Color border;
  final Color text;
  final Color selectedText;

  const _StatusChipColors({
    required this.background,
    required this.selectedBackground,
    required this.border,
    required this.text,
    required this.selectedText,
  });
}

extension _StatusChipStyle on _FilterScreenState {
  _StatusChipColors _statusChipColors(String status) {
    switch (status) {
      case 'ongoing':
        return const _StatusChipColors(
          background: Color(0xFFE3F2FD),
          selectedBackground: Color(0xFF1565C0),
          border: Color(0xFF1565C0),
          text: Color(0xFF0D47A1),
          selectedText: Colors.white,
        );
      case 'coming_soon':
        return const _StatusChipColors(
          background: Color(0xFFE8F5E9),
          selectedBackground: Color(0xFF1B5E20),
          border: Color(0xFF1B5E20),
          text: Color(0xFF1B5E20),
          selectedText: Colors.white,
        );
      case 'completed':
        return const _StatusChipColors(
          background: Color(0xFFFFF3E0),
          selectedBackground: Color(0xFFF57C00),
          border: Color(0xFFF57C00),
          text: Color(0xFFE65100),
          selectedText: Colors.white,
        );
      default:
        return const _StatusChipColors(
          background: Color(0xFFF5F5F5),
          selectedBackground: Color(0xFF424242),
          border: Color(0xFF9E9E9E),
          text: Color(0xFF424242),
          selectedText: Colors.white,
        );
    }
  }
}
