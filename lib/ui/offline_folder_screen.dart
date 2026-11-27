import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../theme_provider.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';
import 'apple_music_widgets.dart';
import 'song_action_sheet.dart';

class OfflineFolderScreen extends StatefulWidget {
  const OfflineFolderScreen({super.key});

  @override
  State<OfflineFolderScreen> createState() => _OfflineFolderScreenState();
}

class _OfflineFolderScreenState extends State<OfflineFolderScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final allSongs = provider.localLibrary;

    final filteredSongs = _searchQuery.isEmpty
        ? allSongs
        : allSongs.where((s) {
            final q = _searchQuery.toLowerCase();
            return s.title.toLowerCase().contains(q) ||
                s.artist.toLowerCase().contains(q) ||
                s.album.toLowerCase().contains(q);
          }).toList();

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.60) : const Color(0xFF64748B);
    final iconColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFFEDF2F7),
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF0D1527),
                  Color(0xFF070B14),
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.45, 0.90],
              )
            : const LinearGradient(
                colors: [
                  Color(0xFFE2EAF8),
                  Color(0xFFF1EEFB),
                  Color(0xFFEDF2F7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.45, 0.90],
              ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Top Navigation Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      FrostedCircleButton(
                        icon: CupertinoIcons.chevron_back,
                        size: 40,
                        iconSize: 20,
                        iconColor: iconColor,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Theme Toggle (Sun/Moon)
                      FrostedCircleButton(
                        icon: isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
                        size: 40,
                        iconSize: 18,
                        iconColor: isDark ? const Color(0xFFFFD60A) : const Color(0xFF5856D6),
                        onPressed: () {
                          context.read<ThemeProvider>().toggleTheme();
                        },
                      ),
                      const SizedBox(width: 8),
                      // Add / Upload Music button
                      FrostedCircleButton(
                        icon: CupertinoIcons.plus,
                        size: 40,
                        iconSize: 20,
                        iconColor: AppTheme.accentColor1,
                        onPressed: () => provider.pickLocalAudio(context),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Large Title Header & Track Count Badge ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(CupertinoIcons.folder_fill, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Offline Storage',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${allSongs.length} downloaded ${allSongs.length == 1 ? 'track' : 'tracks'}  •  Device Storage',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Play All & Shuffle Buttons ──
                      if (allSongs.isNotEmpty) ...[
                        Row(
                          children: [
                            // Play All
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (allSongs.isNotEmpty) {
                                    provider.playSong(allSongs.first, playlist: allSongs);
                                  }
                                },
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.95),
                                      width: 0.8,
                                    ),
                                    boxShadow: !isDark
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(CupertinoIcons.play_fill, color: AppTheme.accentColor1, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Play All',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Shuffle
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (allSongs.isNotEmpty) {
                                    final shuffled = List<Song>.from(allSongs)..shuffle();
                                    provider.playSong(shuffled.first, playlist: shuffled);
                                  }
                                },
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.95),
                                      width: 0.8,
                                    ),
                                    boxShadow: !isDark
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(CupertinoIcons.shuffle, color: AppTheme.accentColor1, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Shuffle',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── Search in Offline Songs ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.07)
                                    : Colors.white.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : Colors.white.withValues(alpha: 0.90),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.search, size: 16, color: subtextColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w500),
                                      decoration: InputDecoration(
                                        hintText: 'Filter offline tracks...',
                                        hintStyle: TextStyle(color: subtextColor, fontSize: 13),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (text) => setState(() => _searchQuery = text),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: Icon(CupertinoIcons.clear_circled_solid, size: 16, color: subtextColor),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Empty State ──
              if (allSongs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.white.withValues(alpha: 0.90),
                                width: 0.8,
                              ),
                              boxShadow: !isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.accentColor1.withValues(alpha: 0.12),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.music_note_list,
                                    size: 48,
                                    color: AppTheme.accentColor1,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'No Offline Songs',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Import audio files directly from your phone to listen without an internet connection.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: subtextColor,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => provider.pickLocalAudio(context),
                                  icon: const Icon(CupertinoIcons.arrow_up_doc_fill, size: 18),
                                  label: const Text('Import Audio Files', style: TextStyle(fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentColor1,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    shadowColor: AppTheme.accentColor1.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else if (filteredSongs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No songs match "$_searchQuery"',
                      style: TextStyle(color: subtextColor, fontSize: 14),
                    ),
                  ),
                )
              else
                // ── Song List ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = filteredSongs[index];
                        final isPlaying = provider.currentSong?.id == song.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isPlaying
                                      ? AppTheme.accentColor1.withValues(alpha: isDark ? 0.20 : 0.12)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.white.withValues(alpha: 0.60)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isPlaying
                                        ? AppTheme.accentColor1.withValues(alpha: 0.5)
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.white.withValues(alpha: 0.85)),
                                    width: 0.8,
                                  ),
                                  boxShadow: (!isPlaying && !isDark)
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 6,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Stack(
                                        children: [
                                          AlbumArt(
                                            song: song,
                                            width: 48,
                                            height: 48,
                                            iconSize: 24,
                                          ),
                                          if (isPlaying)
                                            Container(
                                              color: Colors.black.withValues(alpha: 0.45),
                                              child: const Center(
                                                child: Icon(
                                                  CupertinoIcons.waveform,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      if (song.isExplicit) const ExplicitBadge(size: 13),
                                      Expanded(
                                        child: Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isPlaying ? AppTheme.accentColor1 : textColor,
                                            fontSize: 15,
                                            fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      song.artist.isEmpty ? 'Offline Audio' : song.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // More actions
                                      IconButton(
                                        icon: Icon(CupertinoIcons.ellipsis, size: 18, color: subtextColor),
                                        onPressed: () => SongActionSheet.show(context, song),
                                      ),
                                      // Delete button
                                      IconButton(
                                        icon: const Icon(CupertinoIcons.trash, size: 17, color: Color(0xFFFF453A)),
                                        onPressed: () => _showDeleteDialog(context, provider, song, isDark),
                                      ),
                                    ],
                                  ),
                                  onTap: () => provider.playSong(song, playlist: filteredSongs),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredSongs.length,
                    ),
                  ),
                ),

              // Bottom spacing for floating MiniPlayer
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MusicProvider provider, Song song, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: (isDark ? const Color(0xFF161B24) : Colors.white).withValues(alpha: 0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.90),
              width: 0.8,
            ),
          ),
          title: Text(
            'Remove Offline Song?',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to remove "${song.title}" from your offline library?',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                provider.deleteLocalSong(song);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${song.title}"'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF22242B),
                  ),
                );
              },
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Color(0xFFFF453A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
