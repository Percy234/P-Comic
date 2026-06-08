import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/background_decorations.dart';

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class LicenseData {
  final String package;
  final String text;

  LicenseData({required this.package, required this.text});
}

class _LicensesScreenState extends State<LicensesScreen> {
  final List<LicenseData> _licenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    try {
      final Map<String, List<String>> packageLicenses = {};

      // Đọc các license đã đăng ký trong Flutter Registry
      await for (final license in LicenseRegistry.licenses) {
        final licenseText = license.paragraphs.map((p) => p.text).join('\n');
        for (final package in license.packages) {
          packageLicenses.putIfAbsent(package, () => []).add(licenseText);
        }
      }

      packageLicenses.forEach((package, texts) {
        _licenses.add(LicenseData(package: package, text: texts.join('\n\n')));
      });

      // Sắp xếp theo thứ tự bảng chữ cái của tên Package
      _licenses.sort((a, b) =>
          a.package.toLowerCase().compareTo(b.package.toLowerCase()));
    } catch (e) {
      debugPrint('Lỗi tải giấy phép: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundDecorations(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thanh tiêu đề tùy chỉnh (Custom AppBar)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          ),
                        ),
                        child: IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFFF57C00),
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Giấy Phép Ứng Dụng',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Tạo khoảng cân bằng với nút back
                    ],
                  ),
                ),
                // Nội dung danh sách giấy phép
                Expanded(
                  child: _isLoading
                      ? _buildShimmerLoading()
                      : _licenses.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _licenses.length,
                              itemBuilder: (context, index) {
                                final license = _licenses[index];
                                return _buildLicenseCard(license, theme, isDark);
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

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ShimmerPlaceholder(
            height: 70,
            borderRadius: BorderRadius.circular(16),
            icon: Icons.article_outlined,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Không tìm thấy giấy phép nào.',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }

  Widget _buildLicenseCard(LicenseData license, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFF57C00).withOpacity(0.1),
              radius: 20,
              child: const Icon(
                Icons.folder_zip_outlined,
                color: Color(0xFFF57C00),
                size: 20,
              ),
            ),
            title: Text(
              license.package,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Xem thông tin giấy phép mã nguồn mở',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  license.text,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
