import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../theme_provider.dart';
import 'theme.dart';
import 'album_art.dart';
import 'apple_music_widgets.dart';
import 'song_action_sheet.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6E6E73);
    final songs = provider.favorites;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar with Apple Music Hero Design ──
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            backgroundColor: isDark ? const Color(0xFF0F1420) : Colors.white,
            elevation: 0,
            leading: FrostedCircleButton(
              icon: CupertinoIcons.chevron_back,
              size: 38,
              iconSize: 20,
              iconColor: textColor,
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? const [Color(0xFF4A1020), Color(0xFF181524), Colors.black]
                        : const [Color(0xFFFFDDE3), Color(0xFFF0F3F9), Color(0xFFF2F2F7)],
                    stops: const [0.0, 0.60, 1.0],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2A54), Color(0xFFFF9500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A54).withValues(alpha: 0.4),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(CupertinoIcons.star_fill, color: Colors.white, size: 48),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Favorites',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${songs.length} favorite track${songs.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Action Bar: Play & Shuffle ──
          if (songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: AppTheme.accentGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor1.withValues(alpha: 0.38),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (songs.isNotEmpty) {
                              provider.playSong(songs.first, playlist: songs);
                            }
                          },
                          icon: const Icon(CupertinoIcons.play_fill, size: 18, color: Colors.white),
                          label: const Text(
                            'Play All',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.85),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.95),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            if (songs.isNotEmpty) {
                              final shuffled = List.of(songs)..shuffle();
                              provider.playSong(shuffled.first, playlist: shuffled);
                            }
                          },
                          icon: const Icon(CupertinoIcons.shuffle, size: 18, color: AppTheme.accentColor1),
                          label: const Text(
                            'Shuffle',
                            style: TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Song List ──
          if (songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentColor1.withValues(alpha: 0.25),
                              AppTheme.accentColor2.withValues(alpha: 0.10),
                            ],
                          ),
                        ),
                        child: const Icon(CupertinoIcons.star, size: 54, color: AppTheme.accentColor1),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Favorites Yet',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the star on any song to add it\nto your favorites collection',
                        style: TextStyle(color: subtextColor, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 110, top: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    final isPlaying = provider.currentSong?.id == song.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? AppTheme.accentColor1.withValues(alpha: isDark ? 0.16 : 0.08)
                            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.70)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isPlaying
                              ? AppTheme.accentColor1.withValues(alpha: 0.3)
                              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                          width: 0.8,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: AlbumArt(
                              song: song,
                              width: 48,
                              height: 48,
                              iconSize: 24,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            if (song.isExplicit) const ExplicitBadge(size: 11),
                            Expanded(
                              child: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isPlaying ? AppTheme.accentColor1 : textColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subtextColor, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(CupertinoIcons.star_fill, color: Color(0xFFFFD60A), size: 20),
                              tooltip: 'Remove from favorites',
                              onPressed: () => provider.toggleFavorite(song),
                            ),
                            IconButton(
                              icon: Icon(CupertinoIcons.ellipsis, color: subtextColor, size: 18),
                              onPressed: () => SongActionSheet.show(context, song),
                            ),
                          ],
                        ),
                        onTap: () => provider.playSong(song, playlist: songs),
                      ),
                    );
                  },
                  childCount: songs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
