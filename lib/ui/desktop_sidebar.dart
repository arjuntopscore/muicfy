import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../admin_service.dart';
import '../gemini/gemini_music_screen.dart';
import '../gemini/gemini_config.dart';
import 'theme.dart';
import 'favorites_screen.dart';
import 'stats_screen.dart';
import 'admin_pin_dialog.dart';
import 'admin_upload_screen.dart';

class DesktopFrostedSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onOfflineFolderTapped;

  const DesktopFrostedSidebar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onOfflineFolderTapped,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final adminService = context.watch<AdminService>();
    final isDark = themeProvider.isDarkMode;

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF64748B);
    final sectionHeaderColor = isDark ? Colors.white.withValues(alpha: 0.40) : const Color(0xFF94A3B8);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F1420).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.74),
            border: Border(
              right: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.90),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App Header: Logo + Title + Sun/Moon Switcher ──
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 14, 20),
                child: Row(
                  children: [
                    // Glowing Squircle App Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFA2D48), Color(0xFFFF375F), Color(0xFF5E5CE6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFA2D48).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pattufy',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Desktop Player',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Instant Theme Mode Switcher (Sun / Moon)
                    IconButton(
                      icon: Icon(
                        isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
                        color: isDark ? const Color(0xFFFFD60A) : const Color(0xFF5856D6),
                        size: 20,
                      ),
                      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      onPressed: () {
                        context.read<ThemeProvider>().toggleTheme();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // ── Navigation Section: DISCOVER ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  'DISCOVER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: sectionHeaderColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              _buildNavItem(
                icon: Icons.radio_rounded,
                label: 'Radio',
                isSelected: selectedIndex == 0,
                isDark: isDark,
                onTap: () => onTabSelected(0),
              ),
              _buildNavItem(
                icon: CupertinoIcons.search,
                label: 'Search',
                isSelected: selectedIndex == 1,
                isDark: isDark,
                onTap: () => onTabSelected(1),
              ),
              _buildNavItem(
                icon: CupertinoIcons.music_albums,
                label: 'Library',
                isSelected: selectedIndex == 2,
                isDark: isDark,
                onTap: () => onTabSelected(2),
              ),

              const SizedBox(height: 14),

              // ── Navigation Section: COLLECTION ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  'COLLECTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: sectionHeaderColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              _buildNavItem(
                icon: CupertinoIcons.star_fill,
                label: 'Favorites',
                isSelected: false,
                isDark: isDark,
                iconColor: const Color(0xFFFFB800),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  );
                },
              ),
              _buildNavItem(
                icon: CupertinoIcons.folder_fill,
                label: 'Offline Storage',
                isSelected: false,
                isDark: isDark,
                iconColor: const Color(0xFF0A84FF),
                onTap: onOfflineFolderTapped,
              ),
              _buildNavItem(
                icon: CupertinoIcons.chart_bar_alt_fill,
                label: 'Music Stats',
                isSelected: false,
                isDark: isDark,
                iconColor: AppTheme.accentColor1,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  );
                },
              ),
              _buildNavItem(
                icon: CupertinoIcons.sparkles,
                label: 'Gemini AI Vibe',
                isSelected: false,
                isDark: isDark,
                iconColor: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GeminiMusicScreen(
                        geminiApiKey: geminiApiKey,
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              // ── User Profile / Admin Footer ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () {
                    if (adminService.isAdminLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
                      );
                    } else {
                      showAdminPinDialog(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: adminService.isAdminLoggedIn
                              ? const Color(0xFFFF3B30)
                              : AppTheme.accentColor1.withValues(alpha: 0.2),
                          child: Icon(
                            adminService.isAdminLoggedIn
                                ? Icons.admin_panel_settings
                                : CupertinoIcons.person_fill,
                            size: 16,
                            color: adminService.isAdminLoggedIn ? Colors.white : AppTheme.accentColor1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                adminService.isAdminLoggedIn ? 'Admin Panel' : 'User Library',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                adminService.isAdminLoggedIn ? 'Catalog Manager' : 'Tap for options',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          size: 14,
                          color: subtextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final activeBg = isDark
        ? AppTheme.accentColor1.withValues(alpha: 0.20)
        : AppTheme.accentColor1.withValues(alpha: 0.12);
    final activeBorder = isDark
        ? AppTheme.accentColor1.withValues(alpha: 0.5)
        : AppTheme.accentColor1.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: activeBorder, width: 0.8)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppTheme.accentColor1
                      : (iconColor ?? (isDark ? Colors.white70 : const Color(0xFF475569))),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.accentColor1
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
