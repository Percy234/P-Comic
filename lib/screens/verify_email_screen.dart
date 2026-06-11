import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/background_decorations.dart';
import 'main_shell.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _verificationTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo timer tự động kiểm tra trạng thái xác thực mỗi 3 giây
    _startAutoVerificationCheck();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startAutoVerificationCheck() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final auth = context.read<AuthProvider>();
      await auth.reloadUser();
      
      if (auth.user != null && auth.user!.emailVerified) {
        timer.cancel();
        if (mounted) {
          _navigateToHome(showSuccess: true);
        }
      }
    });
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }



  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0 || _isResending) return;
    setState(() {
      _isResending = true;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.sendVerificationEmail();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lại email xác thực. Vui lòng kiểm tra hộp thư.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _startCooldown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Không thể gửi lại email xác thực. Vui lòng thử lại sau.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _isResending = false;
      });
    }
  }

  void _navigateToHome({required bool showSuccess}) {
    if (showSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực email thành công! Chào mừng bạn.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final userEmail = auth.user?.email ?? '';

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundDecorations(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 6,
                  color: isDark
                      ? theme.cardColor.withOpacity(0.9)
                      : Colors.white.withOpacity(0.92),
                  shadowColor: Colors.black.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Icon Container
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF57C00).withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF57C00).withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_rounded,
                              size: 40,
                              color: Color(0xFFF57C00),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Title
                        Text(
                          'Xác Thực Email Của Bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Description
                        Text(
                          'Chúng tôi đã gửi một liên kết xác nhận đăng ký đến địa chỉ email:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Email display card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            userEmail,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF57C00),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          'Vui lòng nhấp vào liên kết trong hộp thư (kiểm tra cả hộp thư rác/spam) để kích hoạt tài khoản của bạn. Ứng dụng sẽ tự động tiếp tục sau khi bạn xác thực.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 28),
                        

                        
                        // "Gửi lại email" Button
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: _cooldownSeconds > 0
                                  ? Colors.grey.withOpacity(0.3)
                                  : const Color(0xFFF57C00),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: (_cooldownSeconds > 0 || _isResending)
                              ? null
                              : _resendVerificationEmail,
                          child: _isResending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF57C00),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _cooldownSeconds > 0
                                      ? 'GỬI LẠI EMAIL CHỜ ($_cooldownSeconds s)'
                                      : 'GỬI LẠI EMAIL XÁC THỰC',
                                  style: TextStyle(
                                    color: _cooldownSeconds > 0
                                        ? Colors.grey
                                        : const Color(0xFFF57C00),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: isDark ? Colors.grey[800] : Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'HOẶC',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: isDark ? Colors.grey[800] : Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // "Đăng xuất" Button
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _logout,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.exit_to_app_rounded,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Đăng xuất / Đổi tài khoản khác',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
