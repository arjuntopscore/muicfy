import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../theme_provider.dart';
import '../api_service.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';
import 'apple_music_widgets.dart';
import 'song_action_sheet.dart';

class ArtistScreen extends StatefulWidget {
  final String artistName;
  final String artistImageUrl;

  const ArtistScreen({
    super.key,
    required this.artistName,
    this.artistImageUrl = '',
  });

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  final ApiService _apiService = ApiService();
  List<Song> _artistSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistSongs();
  }

  Future<void> _loadArtistSongs() async {
    final songs = await _apiService.searchSongs(widget.artistName, limit: 30);
    if (mounted) {
      setState(() {
        _artistSongs = songs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF6E6E73);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
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
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                widget.artistName,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: textColor,
                  letterSpacing: -0.4,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.artistImageUrl.isNotEmpty
                      ? Image.network(
                          widget.artistImageUrl
                              .replaceAll('150x150', '1000x1000')
                              .replaceAll('500x500', '1000x1000'),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: isDark ? const Color(0xFF161B24) : Colors.grey.shade300);
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [Color(0xFF2C3E50), Color(0xFF131722)]
                                  : const [Color(0xFFBDC3C7), Color(0xFFF2F2F7)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Icon(CupertinoIcons.mic_fill, size: 72, color: subtextColor.withValues(alpha: 0.3)),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark ? Colors.black : const Color(0xFFF2F2F7)).withValues(alpha: 0.5),
                          isDark ? Colors.black : const Color(0xFFF2F2F7),
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons: Play All & Shuffle
          if (!_isLoading && _artistSongs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                              color: AppTheme.accentColor1.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            provider.playSong(_artistSongs.first, playlist: _artistSongs);
                          },
                          icon: const Icon(CupertinoIcons.play_fill, size: 18, color: Colors.white),
                          label: const Text('Play All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                          ),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            final shuffled = List<Song>.from(_artistSongs)..shuffle();
                            provider.playSong(shuffled.first, playlist: shuffled);
                          },
                          icon: const Icon(CupertinoIcons.shuffle, size: 18, color: AppTheme.accentColor1),
                          label: const Text('Shuffle', style: TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.w700)),
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

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor1),
              ),
            )
          else if (_artistSongs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No songs found for this artist',
                  style: TextStyle(color: subtextColor, fontSize: 16),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = _artistSongs[index];
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
                              icon: Icon(
                                provider.isFavorite(song) ? CupertinoIcons.star_fill : CupertinoIcons.star,
                                color: provider.isFavorite(song) ? const Color(0xFFFFD60A) : subtextColor,
                                size: 20,
                              ),
                              onPressed: () => provider.toggleFavorite(song),
                            ),
                            IconButton(
                              icon: Icon(CupertinoIcons.ellipsis, color: subtextColor, size: 18),
                              onPressed: () => SongActionSheet.show(context, song),
                            ),
                          ],
                        ),
                        onTap: () => provider.playSong(song, playlist: _artistSongs),
                      ),
                    );
                  },
                  childCount: _artistSongs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
