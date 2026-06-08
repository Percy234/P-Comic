import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/comic_provider.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Thiết lập hoạt ảnh phóng to nhẹ và mờ dần trong 1.8 giây đầu
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    // Khởi chạy việc tải trước dữ liệu song song với thời lượng tối thiểu 5 giây sau khi khung giao diện đầu tiên được vẽ xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataAndNavigate();
    });
  }

  Future<void> _loadDataAndNavigate() async {
    final comicProvider = context.read<ComicProvider>();

    try {
      // Đợi song song việc tải dữ liệu Home, Paged và đảm bảo chạy đủ 5 giây
      await Future.wait([
        comicProvider.loadHomeComics(),
        comicProvider.loadPagedComics(1),
        Future.delayed(const Duration(seconds: 5)),
      ]);
    } catch (e) {
      debugPrint('Lỗi tải trước dữ liệu: $e');
    }

    _navigateToHome();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F11),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Nội dung chính nằm ở trung tâm
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chữ P_Comic được tạo kiểu cao cấp với độ bóng nhẹ màu cam
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 48.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontFamily: 'Cabin',
                        ),
                        children: [
                          TextSpan(
                            text: 'P',
                            style: TextStyle(
                              color: const Color(0xFFF57C00),
                              shadows: [
                                Shadow(
                                  blurRadius: 20.0,
                                  color: const Color(0xFFF57C00)
                                      .withOpacity(0.6),
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          const TextSpan(
                            text: '_Comic',
                            style: TextStyle(
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.white10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    // Slogan nhỏ tinh tế
                    const Text(
                      'Đọc Truyện Tranh Đỉnh Cao',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.0,
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Cabin',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Trạng thái tải mượt mà ở phía dưới màn hình
            Positioned(
              bottom: 60.0,
              left: 40.0,
              right: 40.0,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 120.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2.0),
                        child: const LinearProgressIndicator(
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFF57C00),
                          ),
                          minHeight: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    const Text(
                      'Đang tải dữ liệu...',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11.0,
                        letterSpacing: 1.0,
                        fontFamily: 'Cabin',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
