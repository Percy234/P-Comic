import 'package:flutter/material.dart';
import 'filter_screen.dart';
import 'home_screen.dart';
import 'favorite_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../widgets/common_header.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      HomeScreen(
        onChangeTab: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      const FilterScreen(
        filterTitle: 'Thể loại',
        showBottomNav: false,
      ),
      const FavoriteScreen(),
      const HistoryScreen(),
      ProfileScreen(
        onChangeTab: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<TabSwitchNotification>(
        onNotification: (notification) {
          setState(() {
            currentIndex = notification.index;
          });
          return true;
        },
        child: IndexedStack(index: currentIndex, children: pages),
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final double tabWidth = totalWidth / 5;
          final double indicatorWidth = 56.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              BottomNavigationBar(
                currentIndex: currentIndex,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: const Color(0xFFF57C00),
                unselectedItemColor: Colors.grey,
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                  });
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
                  BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch Sử'),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Cá Nhân',
                  ),
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                top: 0,
                left: (tabWidth * currentIndex) + (tabWidth - indicatorWidth) / 2,
                child: Container(
                  width: indicatorWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57C00),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
