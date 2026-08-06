import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'music_provider.dart';
import 'ui/theme.dart';
import 'ui/home_tab.dart';
import 'ui/search_tab.dart';
import 'ui/library_tab.dart';
import 'ui/offline_folder_screen.dart';
import 'ui/mini_player.dart';
import 'ui/welcome_screen.dart';

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
        ChangeNotifierProvider(create: (_) => MusicProvider()),
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
    return MaterialApp(
      title: 'musicfy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      scaffoldMessengerKey: scaffoldMessengerKey,
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
    final pages = [
      HomeTab(
        onSearchTapped: () => _onTabTapped(1),
        onLocalLibraryTapped: _goToOfflineFolder,
      ),
      const SearchTab(),
      LibraryTab(onOfflineFolderTapped: _goToOfflineFolder),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          pages[_selectedIndex],
          
          // Persistent Mini Player overlay
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music_outlined), activeIcon: Icon(Icons.library_music), label: 'Library'),
        ],
      ),
    );
  }
}
