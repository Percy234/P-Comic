import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'database/database_helper.dart';

import 'providers/comic_provider.dart';
import 'providers/detail_provider.dart';
import 'providers/reading_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/history_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/filter_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo cơ sở dữ liệu Hive
  await DatabaseHelper.instance.initHive();

  timeago.setLocaleMessages('vi', timeago.ViMessages());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ComicProvider()),
        ChangeNotifierProvider(create: (_) => DetailProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()..loadFavorites()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'P Comic',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Cabin',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFEBEBEB),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFF57C00),
          secondary: Colors.blue,
          surface: Colors.white,
          background: Color(0xFFEBEBEB),
          onPrimary: Colors.white,
          onSurface: Colors.black87,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Cabin',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF57C00),
          secondary: Colors.blue,
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      home: const MainShell(),
    );
  }
}
