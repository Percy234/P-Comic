import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/background_decorations.dart';
import '../widgets/common_header.dart';
import '../widgets/require_login_placeholder.dart';
import '../config/app_config.dart';
import 'licenses_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onChangeTab;
  const ProfileScreen({super.key, this.onChangeTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isLoggedIn = authProvider.isLoggedIn;
    
    // Watch other providers for real-time stats
    final favoriteProvider = context.watch<FavoriteProvider>();
    final historyProvider = context.watch<HistoryProvider>();

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundDecorations(),
          SafeArea(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    if (!isLoggedIn)
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
                              'Trang cá nhân',
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
                      child: isLoggedIn && user != null
                          ? SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              child: _buildMemberContent(context, user, favoriteProvider, historyProvider),
                            )
                          : _buildGuestContent(context),
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

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Xóa tài khoản?'),
            ],
          ),
          content: const Text(
            'Hành động này sẽ xóa vĩnh viễn tài khoản của bạn và không thể khôi phục lại. Bạn có chắc chắn muốn tiếp tục?',
            style: TextStyle(height: 1.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Hủy',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Đóng dialog
                
                // Hiển thị loading spinner dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF57C00),
                    ),
                  ),
                );

                final auth = context.read<AuthProvider>();
                final success = await auth.deleteAccount();

                if (context.mounted) {
                  Navigator.pop(context); // Đóng loading dialog
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tài khoản của bạn đã được xóa thành công.'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (errorContext) => AlertDialog(
                        title: const Text('Lỗi khi xóa tài khoản'),
                        content: Text(auth.errorMessage ?? 'Không thể xóa tài khoản lúc này. Vui lòng thử lại sau.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(errorContext),
                            child: const Text('Đồng ý', style: TextStyle(color: Color(0xFFF57C00))),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Xóa vĩnh viễn',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuestContent(BuildContext context) {
    return const RequireLoginPlaceholder(
      icon: Icons.account_circle_rounded,
      title: 'Tài Khoản Cá Nhân',
      description: 'Đăng nhập tài khoản để đồng bộ hóa danh sách truyện yêu thích, lưu lịch sử đọc truyện và nhận các thông báo mới nhất.',
    );
  }

  Widget _buildMemberContent(
    BuildContext context,
    User user,
    FavoriteProvider favoriteProvider,
    HistoryProvider historyProvider,
  ) {
    final displayName = user.displayName ?? '';
    final parts = displayName.split(' | ');
    final username = parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0]
        : (user.email != null && user.email!.contains('@') ? user.email!.split('@')[0] : 'user');
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    final nickname = parts.length > 1 ? parts[1] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Member Header Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF57C00), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE65100).withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: user.photoURL != null && user.photoURL!.isNotEmpty
                          ? (user.photoURL!.startsWith('assets/')
                              ? Image.asset(
                                  user.photoURL!,
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE65100),
                                      ),
                                    ),
                                  ),
                                )
                              : Image.network(
                                  user.photoURL!,
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE65100),
                                      ),
                                    ),
                                  ),
                                ))
                          : Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // User Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email ?? 'Chưa cập nhật email',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            nickname.isNotEmpty ? 'Biệt danh: $nickname' : 'Biệt danh: Chưa đặt',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Divider
              Divider(color: Colors.white.withOpacity(0.3), height: 1),
              const SizedBox(height: 16),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    title: 'Yêu thích',
                    count: '${favoriteProvider.favorites.length}',
                    icon: Icons.favorite_rounded,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStatItem(
                    title: 'Lịch sử đọc',
                    count: '${historyProvider.histories.length}',
                    icon: Icons.history_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Settings / Options Menu
        _buildMenuTile(
          icon: Icons.settings_rounded,
          iconColor: const Color(0xFFF57C00),
          title: 'Cài đặt cá nhân',
          subtitle: 'Thiết lập ảnh đại diện và biệt danh bình luận',
          onTap: () {
            _showPersonalSettingsBottomSheet(context, user);
          },
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          icon: Icons.lock_outline_rounded,
          iconColor: const Color(0xFFE040FB),
          title: 'Đổi mật khẩu',
          subtitle: 'Thay đổi mật khẩu đăng nhập của bạn',
          onTap: () {
            _showChangePasswordBottomSheet(context, user);
          },
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          icon: Icons.favorite_outline_rounded,
          iconColor: const Color(0xFFE53935),
          title: 'Danh sách yêu thích',
          subtitle: 'Xem các bộ truyện bạn đã lưu thích',
          onTap: () {
            widget.onChangeTab?.call(2);
          },
        ),
        const SizedBox(height: 12),
        _buildMenuTile(
          icon: Icons.history_rounded,
          iconColor: const Color(0xFF1E88E5),
          title: 'Lịch sử đọc truyện',
          subtitle: 'Theo dõi tiến trình đọc của bạn',
          onTap: () {
            widget.onChangeTab?.call(3);
          },
        ),

        const SizedBox(height: 12),
        _buildMenuTile(
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFF43A047),
          title: 'Về ứng dụng P-Comic',
          subtitle: 'Thông tin phiên bản v${AppConfig.version}',
          onTap: () {
            _showCustomAboutDialog(context);
          },
        ),
        const SizedBox(height: 32),

        // Logout Button
        InkWell(
          onTap: () async {
            await context.read<AuthProvider>().logout();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đăng xuất thành công'),
                  backgroundColor: Color(0xFFF57C00),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFC62828).withOpacity(0.15)
                  : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFC62828).withOpacity(0.3)
                    : const Color(0xFFFFCDD2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE57373)
                      : const Color(0xFFC62828),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE57373)
                        : const Color(0xFFC62828),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Delete Account Button
        InkWell(
          onTap: () => _confirmDeleteAccount(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD32F2F).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Xóa tài khoản',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String title,
    required String count,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).cardColor.withOpacity(0.85)
          : Colors.white.withOpacity(0.85),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          backgroundColor: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Icon Container
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
                        Icons.menu_book,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                const Text(
                  'P-Comic',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phiên bản ${AppConfig.version}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'Ứng dụng đọc truyện tranh trực tuyến P-Comic phiên bản premium với các tính năng lưu yêu thích, lưu lịch sử đọc cá nhân hóa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
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
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Đóng',
                            style: TextStyle(
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context); // Close the dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LicensesScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF57C00), Color(0xFFE65100)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE65100).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Giấy phép',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
        );
      },
    );
  }

  void _showPersonalSettingsBottomSheet(BuildContext context, User user) {
    final TextEditingController nicknameController = TextEditingController();
    
    final displayName = user.displayName ?? '';
    final parts = displayName.split(' | ');
    final username = parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0]
        : (user.email != null && user.email!.contains('@') ? user.email!.split('@')[0] : 'user');
    final currentNickname = parts.length > 1 ? parts[1] : '';
    nicknameController.text = currentNickname;

    String selectedAvatarUrl = user.photoURL ?? '';
    bool isSaving = false;

    final List<String> defaultAvatars = [
      'assets/images/arlecchino.jpg',
      'assets/images/ayaka.jpg',
      'assets/images/ayato.jpg',
      'assets/images/childe.jpg',
      'assets/images/cyno.jpg',
      'assets/images/diluc.jpg',
      'assets/images/durin.jpg',
      'assets/images/furina.jpg',
      'assets/images/kazuha.jpg',
      'assets/images/killua.jpg',
      'assets/images/wanderer.jpg',
      'assets/images/zhongli.jpg',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, setSheetState) {
            final theme = Theme.of(stateContext);
            final isDark = theme.brightness == Brightness.dark;

            Future<void> saveSettings() async {
              setSheetState(() {
                isSaving = true;
              });

              try {
                // Cập nhật photoURL của Firebase Auth trực tiếp với link avatar được chọn
                if (selectedAvatarUrl != user.photoURL) {
                  await user.updatePhotoURL(selectedAvatarUrl.isNotEmpty ? selectedAvatarUrl : null);
                }

                final nickname = nicknameController.text.trim();
                String newDisplayName = username;
                if (nickname.isNotEmpty) {
                  newDisplayName = '$username | $nickname';
                }
                await user.updateDisplayName(newDisplayName);

                if (context.mounted) {
                  await context.read<AuthProvider>().reloadUser();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cập nhật thông tin cá nhân thành công!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }

                if (stateContext.mounted) {
                  Navigator.pop(stateContext);
                }
              } catch (e) {
                if (stateContext.mounted) {
                  showDialog(
                    context: stateContext,
                    builder: (errContext) => AlertDialog(
                      title: const Text('Lỗi cập nhật'),
                      content: Text(e.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(errContext),
                          child: const Text('Đồng ý'),
                        ),
                      ],
                    ),
                  );
                }
              } finally {
                setSheetState(() {
                  isSaving = false;
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(stateContext).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Cài đặt cá nhân',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Preview Avatar được chọn
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF57C00),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: selectedAvatarUrl.isNotEmpty
                            ? (selectedAvatarUrl.startsWith('assets/')
                                ? Image.asset(
                                    selectedAvatarUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        _buildInitialAvatar(username.isNotEmpty ? username[0].toUpperCase() : 'U', 100),
                                  )
                                : Image.network(
                                    selectedAvatarUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        _buildInitialAvatar(username.isNotEmpty ? username[0].toUpperCase() : 'U', 100),
                                  ))
                            : _buildInitialAvatar(username.isNotEmpty ? username[0].toUpperCase() : 'U', 100),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Chọn ảnh đại diện mặc định',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grid danh sách avatar mặc định dạng cuộn ngang
                    SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: defaultAvatars.length,
                        itemBuilder: (context, index) {
                          final avatarUrl = defaultAvatars[index];
                          final isSelected = selectedAvatarUrl == avatarUrl;

                          return GestureDetector(
                            onTap: isSaving
                                ? null
                                : () {
                                    setSheetState(() {
                                      selectedAvatarUrl = avatarUrl;
                                    });
                                  },
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFF57C00) : Colors.grey[300]!,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: ClipOval(
                                    child: Image.asset(
                                      avatarUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Biệt danh hiển thị bình luận',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nicknameController,
                      enabled: !isSaving,
                      maxLength: 15,
                      decoration: InputDecoration(
                        hintText: 'Nhập biệt danh của bạn...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black38,
                          fontSize: 14,
                        ),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSaving ? null : () => Navigator.pop(stateContext),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Hủy',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF57C00), Color(0xFFE65100)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE65100).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isSaving ? null : saveSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Lưu thay đổi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
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
            );
          },
        );
      },
    );
  }

  void _showChangePasswordBottomSheet(BuildContext context, User user) {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    bool isSaving = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, setSheetState) {
            final theme = Theme.of(stateContext);
            final isDark = theme.brightness == Brightness.dark;
            final isGoogleUser = user.providerData.any((info) => info.providerId == 'google.com');

            Future<void> changePassword() async {
              final oldPassword = oldPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                ScaffoldMessenger.of(stateContext).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng điền đầy đủ các thông tin!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(stateContext).showSnackBar(
                  const SnackBar(
                    content: Text('Mật khẩu mới phải có ít nhất 6 ký tự!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(stateContext).showSnackBar(
                  const SnackBar(
                    content: Text('Mật khẩu xác nhận không trùng khớp!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              setSheetState(() {
                isSaving = true;
              });

              try {
                final email = user.email;
                if (email == null) throw Exception('Không tìm thấy email của bạn.');

                final credential = EmailAuthProvider.credential(
                  email: email,
                  password: oldPassword,
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đổi mật khẩu thành công!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }

                if (stateContext.mounted) {
                  Navigator.pop(stateContext);
                }
              } catch (e) {
                String errorMsg = e.toString();
                if (errorMsg.contains('wrong-password')) {
                  errorMsg = 'Mật khẩu hiện tại không chính xác.';
                } else if (errorMsg.contains('weak-password')) {
                  errorMsg = 'Mật khẩu quá yếu.';
                }
                
                if (stateContext.mounted) {
                  showDialog(
                    context: stateContext,
                    builder: (errContext) => AlertDialog(
                      title: const Text('Lỗi cập nhật'),
                      content: Text(errorMsg),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(errContext),
                          child: const Text('Đồng ý'),
                        ),
                      ],
                    ),
                  );
                }
              } finally {
                setSheetState(() {
                  isSaving = false;
                });
              }
            }

            if (isGoogleUser) {
              return Container(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Icon(
                        Icons.g_mobiledata_rounded,
                        size: 64,
                        color: Color(0xFFF57C00),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tài khoản liên kết Google',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF57C00),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tài khoản của bạn được đăng nhập trực tiếp thông qua Google trên thiết bị. Vì vậy, hệ thống không hỗ trợ đổi mật khẩu thủ công cho tài khoản này.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF57C00), Color(0xFFE65100)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(stateContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Đóng',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(stateContext).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Đổi mật khẩu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: oldPasswordController,
                      enabled: !isSaving,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu hiện tại',
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOld ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setSheetState(() {
                              obscureOld = !obscureOld;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: newPasswordController,
                      enabled: !isSaving,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setSheetState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: confirmPasswordController,
                      enabled: !isSaving,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setSheetState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSaving ? null : () => Navigator.pop(stateContext),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Hủy',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF57C00), Color(0xFFE65100)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE65100).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isSaving ? null : changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Cập nhật',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
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
            );
          },
        );
      },
    );
  }

  Widget _buildInitialAvatar(String text, double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE65100),
          ),
        ),
      ),
    );
  }
}
