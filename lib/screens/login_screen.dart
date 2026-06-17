import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/background_decorations.dart';
import '../widgets/common_header.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _obscurePassword = true;
  bool _agreeToPolicy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AuthProvider>().clearError();
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _searchController.dispose();
    super.dispose();
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
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Row containing Home Button + CommonHeader
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? theme.cardColor : Colors.white,
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
                                Icons.home_rounded,
                                color: Color(0xFFF57C00),
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MainShell()),
                                  (route) => false,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CommonHeader(
                              controller: _searchController,
                              showAuthButtons: false,
                              onSearchChanged: (query) {
                                setState(() {
                                  _searchQuery = query;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Main Login Card Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            return Card(
                              elevation: 4,
                              color: isDark
                                  ? theme.cardColor.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.92),
                              shadowColor: Colors.black.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Đăng Nhập Tài Khoản',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Đăng nhập để tiếp tục theo dõi bộ truyện yêu thích của bạn',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Email or Username input
                                    Text(
                                      'Email hoặc Tên đăng nhập',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.black.withOpacity(0.25) : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: emailController,
                                        keyboardType: TextInputType.text,
                                        cursorColor: const Color(0xFFF57C00),
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.person_rounded,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          hintText: 'Nhập email hoặc tên đăng nhập',
                                          hintStyle: TextStyle(
                                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Password input
                                    Text(
                                      'Mật khẩu',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.black.withOpacity(0.25) : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: passwordController,
                                        obscureText: _obscurePassword,
                                        cursorColor: const Color(0xFFF57C00),
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.lock_rounded,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword 
                                                  ? Icons.visibility_off_rounded 
                                                  : Icons.visibility_rounded,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                          hintText: 'Nhập mật khẩu',
                                          hintStyle: TextStyle(
                                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    
                                    // Error message
                                    if (auth.errorMessage != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFFC62828).withOpacity(0.15)
                                              : Colors.red[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFFC62828).withOpacity(0.3)
                                                : Colors.red[100]!,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                auth.errorMessage!,
                                                style: TextStyle(
                                                  color: isDark ? const Color(0xFFE57373) : Colors.red,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Checkbox điều khoản
                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: Checkbox(
                                              value: _agreeToPolicy,
                                              activeColor: const Color(0xFFF57C00),
                                              onChanged: (value) {
                                                setState(() {
                                                  _agreeToPolicy = value ?? false;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _showPrivacyPolicyDialog(context),
                                              child: RichText(
                                                text: TextSpan(
                                                  text: 'Tôi đồng ý với ',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                  ),
                                                  children: const [
                                                    TextSpan(
                                                      text: 'Điều khoản & Chính sách quyền riêng tư',
                                                      style: TextStyle(
                                                        color: Color(0xFFF57C00),
                                                        fontWeight: FontWeight.bold,
                                                        decoration: TextDecoration.underline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Gradient Login button
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFF57C00), Color(0xFFFF9800)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFF57C00).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          minimumSize: const Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                         onPressed: auth.isLoading ? () {} : () async {
                                           final performLogin = () async {
                                             if (emailController.text.trim().isEmpty) {
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                 const SnackBar(content: Text('Vui lòng nhập email hoặc tên đăng nhập')),
                                               );
                                               return;
                                             }
                                             if (passwordController.text.trim().isEmpty) {
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                 const SnackBar(content: Text('Vui lòng nhập mật khẩu')),
                                               );
                                               return;
                                             }
                                             final success = await auth.login(
                                               emailOrUsername: emailController.text.trim(),
                                               password: passwordController.text.trim(),
                                             );
                                             if (success && context.mounted) {
                                               Navigator.pushReplacement(
                                                 context,
                                                 MaterialPageRoute(
                                                   builder: (_) => const MainShell(),
                                                 ),
                                               );
                                             }
                                           };

                                           if (!_agreeToPolicy) {
                                             _showPrivacyPolicyDialog(
                                               context,
                                               onAgree: () async {
                                                 setState(() {
                                                   _agreeToPolicy = true;
                                                 });
                                                 await performLogin();
                                               },
                                             );
                                             return;
                                           }
                                           await performLogin();
                                         },
                                        child: auth.isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'ĐĂNG NHẬP',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Divider "Hoặc"
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            'HOẶC',
                                            style: TextStyle(
                                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Google Sign In button
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                        ),
                                        backgroundColor: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                                        elevation: 1,
                                        shadowColor: Colors.black.withOpacity(0.05),
                                      ),
                                       onPressed: auth.isLoading
                                           ? null
                                           : () async {
                                               final performSignIn = () async {
                                                 final success = await auth.signInWithGoogle();
                                                 if (success && context.mounted) {
                                                   Navigator.pushReplacement(
                                                     context,
                                                     MaterialPageRoute(
                                                       builder: (_) => const MainShell(),
                                                     ),
                                                   );
                                                 }
                                               };

                                               if (!_agreeToPolicy) {
                                                 _showPrivacyPolicyDialog(
                                                   context,
                                                   onAgree: () async {
                                                     setState(() {
                                                       _agreeToPolicy = true;
                                                     });
                                                     await performSignIn();
                                                   },
                                                 );
                                                 return;
                                               }
                                               await performSignIn();
                                             },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/google_logo.png',
                                            height: 22,
                                            width: 22,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.account_circle,
                                                color: Colors.red,
                                                size: 22,
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Sử dụng tài khoản Google trên máy',
                                            style: TextStyle(
                                              color: isDark ? Colors.white : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Switch to Register link
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Chưa có tài khoản? ',
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const RegisterScreen(),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Đăng ký ngay',
                                            style: TextStyle(
                                              color: Color(0xFFF57C00),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
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
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Positioned Search dropdown overlay
                if (_searchQuery.trim().isNotEmpty)
                  Positioned(
                    top: 56,
                    left: 64,
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

  void _showPrivacyPolicyDialog(BuildContext context, {VoidCallback? onAgree}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: onAgree == null,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.privacy_tip_rounded, color: Color(0xFFF57C00)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  onAgree != null ? 'Điều khoản & Chính sách' : 'Chính sách quyền riêng tư',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onAgree != null) ...[
                    Text(
                      'Để tiếp tục, vui lòng đọc và đồng ý với Điều khoản & Chính sách quyền riêng tư của P-Comic:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.orange[300] : Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Text(
                      'Chào mừng bạn đến với P-Comic. Quyền riêng tư của bạn là ưu tiên hàng đầu của chúng tôi. Dưới đây là các thông tin thu thập và bảo mật:',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.black87),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildPolicySection(
                    '1. Thu thập thông tin cá nhân',
                    'Chúng tôi thu thập email, tên đăng nhập và biệt danh của bạn nhằm mục đích xác thực tài khoản và lưu lịch sử đọc truyện cá nhân.',
                    isDark,
                  ),
                  _buildPolicySection(
                    '2. Sử dụng thông tin',
                    'Thông tin thu thập được chỉ sử dụng để vận hành các tính năng lưu truyện thích, lịch sử đọc và trợ lý AI tìm truyện. Chúng tôi cam kết KHÔNG chia sẻ thông tin của bạn cho bên thứ ba.',
                    isDark,
                  ),
                  _buildPolicySection(
                    '3. Bảo mật thông tin',
                    'Dữ liệu của bạn được lưu trữ và mã hóa an toàn thông qua nền tảng đám mây Firebase Auth và Firestore của Google.',
                    isDark,
                  ),
                  _buildPolicySection(
                    '4. Quyền kiểm soát tài khoản',
                    'Bạn có toàn quyền chỉnh sửa biệt danh, đổi mật khẩu hoặc xóa tài khoản vĩnh viễn trực tiếp ngay tại trang Cài đặt cá nhân.',
                    isDark,
                  ),
                ],
              ),
            ),
          ),
          actions: onAgree != null
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF57C00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onAgree();
                    },
                    child: const Text(
                      'Đồng ý & Tiếp tục',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Đã hiểu',
                      style: TextStyle(
                        color: Color(0xFFF57C00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
        );
      },
    );
  }

  Widget _buildPolicySection(String title, String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
