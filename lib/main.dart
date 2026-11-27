import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import 'dart:io';

import 'music_provider.dart';
import 'admin_service.dart';
import 'hidden_photo_service.dart';
import 'ui/theme.dart';
import 'ui/home_tab.dart';
import 'ui/search_tab.dart';
import 'ui/library_tab.dart';
import 'ui/offline_folder_screen.dart';
import 'ui/mini_player.dart';
import 'ui/desktop_sidebar.dart';
import 'ui/desktop_player_bar.dart';
import 'ui/welcome_screen.dart';

import 'theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request notification permission for Android 13+
  await Permission.notification.request();

  // Check onboarding status before running the app
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => HiddenPhotoService()),
      ],
      child: MusicApp(showOnboarding: !onboardingComplete),
    ),
  );
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MusicApp extends StatefulWidget {
  final bool showOnboarding;

  const MusicApp({super.key, required this.showOnboarding});

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  void _onOnboardingComplete() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return MaterialApp(
      title: 'Pattufy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      scaffoldMessengerKey: scaffoldMessengerKey,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.trackpad},
      ),
      home: _showOnboarding
          ? WelcomeScreen(onComplete: _onOnboardingComplete)
          : const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToOfflineFolder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OfflineFolderScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    final pages = [
      HomeTab(
        onSearchTapped: () => _onTabTapped(1),
        onLocalLibraryTapped: _goToOfflineFolder,
      ),
      const SearchTab(),
      LibraryTab(onOfflineFolderTapped: _goToOfflineFolder),
    ];

    final isDesktop = MediaQuery.of(context).size.width > 768;

    Widget body = isDesktop
        ? Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    DesktopFrostedSidebar(
                      selectedIndex: _selectedIndex,
                      onTabSelected: _onTabTapped,
                      onOfflineFolderTapped: _goToOfflineFolder,
                    ),
                    Expanded(child: pages[_selectedIndex]),
                  ],
                ),
              ),
              const DesktopPlayerBar(),
            ],
          )
        : Column(
            children: [
              Expanded(child: pages[_selectedIndex]),
              const MiniPlayer(),
            ],
          );

    final bgPath = themeProvider.getBackgroundImageForTab(_selectedIndex);

    if (bgPath != null) {
      body = Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              File(bgPath),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          body,
        ],
      );
    }

    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: bgPath != null ? Colors.transparent : (isDark ? Colors.black : const Color(0xFFF2F2F7)),
      body: body,
      bottomNavigationBar: isDesktop 
        ? null 
        : ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: bgPath != null
                      ? Colors.transparent
                      : (isDark
                          ? const Color(0xFF0D1017).withValues(alpha: 0.90)
                          : Colors.white.withValues(alpha: 0.74)),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.90),
                      width: 0.8,
                    ),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _onTabTapped,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: AppTheme.accentColor1,
                  unselectedItemColor: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.radio_rounded),
                      activeIcon: Icon(Icons.radio_rounded),
                      label: 'Radio',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.search),
                      activeIcon: Icon(CupertinoIcons.search),
                      label: 'Search',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.music_albums),
                      activeIcon: Icon(CupertinoIcons.music_albums_fill),
                      label: 'Library',
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
