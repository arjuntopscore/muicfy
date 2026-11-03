import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
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
      title: 'NexTune',
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

    final isDesktop = MediaQuery.of(context).size.width > 600;

    Widget body = Row(
      children: [
        if (isDesktop)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onTabTapped,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(CupertinoIcons.home), selectedIcon: Icon(CupertinoIcons.house_fill), label: Text('Home')),
              NavigationRailDestination(icon: Icon(CupertinoIcons.search), selectedIcon: Icon(CupertinoIcons.search), label: Text('Search')),
              NavigationRailDestination(icon: Icon(CupertinoIcons.music_albums), selectedIcon: Icon(CupertinoIcons.music_albums_fill), label: Text('Library')),
            ],
          ),
        if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Column(
            children: [
              Expanded(child: pages[_selectedIndex]),
              const MiniPlayer(),
            ],
          ),
        ),
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

    return Scaffold(
      backgroundColor: bgPath != null ? Colors.transparent : null,
      body: body,
      bottomNavigationBar: isDesktop 
        ? null 
        : BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
            backgroundColor: bgPath != null ? Colors.transparent : null,
            elevation: bgPath != null ? 0 : 8,
            items: const [
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), activeIcon: Icon(CupertinoIcons.house_fill), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), activeIcon: Icon(CupertinoIcons.search), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.music_albums), activeIcon: Icon(CupertinoIcons.music_albums_fill), label: 'Library'),
            ],
          ),
    );
  }
}
