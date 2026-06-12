import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/comic_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/detail_screen.dart';

class TabSwitchNotification extends Notification {
  final int index;
  const TabSwitchNotification(this.index);
}

class CommonHeader extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final bool showAuthButtons;

  const CommonHeader({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    this.showAuthButtons = true,
  });

  @override
  State<CommonHeader> createState() => _CommonHeaderState();
}

class _CommonHeaderState extends State<CommonHeader> {
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.controller.text;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller.text != _query) {
      setState(() {
        _query = widget.controller.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]!
                    : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    onChanged: (value) {
                      if (value.trim().isEmpty) {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        widget.onSearchChanged('');
                        context.read<ComicProvider>().searchComics('');
                      } else {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          widget.onSearchChanged(value);
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
                if (_query.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                      widget.onSearchChanged('');
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
        IconButton(
          onPressed: () {
            themeProvider.toggleTheme();
          },
          icon: Icon(
            themeProvider.isDarkMode
                ? Icons.wb_sunny_rounded
                : Icons.dark_mode_rounded,
            color: themeProvider.isDarkMode ? Colors.amber : Colors.grey[700],
          ),
          iconSize: 28,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        if (auth.isLoggedIn) ...[
          Builder(
            builder: (context) {
              final user = auth.user;
              final photoUrl = user?.photoURL;
              final displayName = user?.displayName ?? '';
              final parts = displayName.split(' | ');
              final username = parts.isNotEmpty && parts[0].isNotEmpty
                  ? parts[0]
                  : (user?.email != null && user!.email!.contains('@')
                      ? user.email!.split('@')[0]
                      : 'user');
              final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

              return GestureDetector(
                onTap: () {
                  const TabSwitchNotification(4).dispatch(context);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF57C00),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? (photoUrl.startsWith('assets/')
                              ? Image.asset(
                                  photoUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : Image.network(
                                  photoUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ))
                          : Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ] else if (widget.showAuthButtons) ...[
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: Text(
              'Đăng ký',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SearchResultsBox extends StatelessWidget {
  final String searchQuery;
  final VoidCallback onTapResult;

  const SearchResultsBox({
    super.key,
    required this.searchQuery,
    required this.onTapResult,
  });

  String _formatSubtitle(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Sắp ra';
    final match = RegExp(r'(\d+)').firstMatch(raw);
    if (match != null) return 'Chương ${match.group(1)}';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComicProvider>();
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]!.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[200]!,
        ),
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
                        onTapResult();
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
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 70,
                                    height: 100,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[900]
                                        : Colors.grey[100],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFC62828),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 70,
                                  height: 100,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[900]
                                      : Colors.grey[200],
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
