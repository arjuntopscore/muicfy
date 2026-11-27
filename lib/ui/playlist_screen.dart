import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../theme_provider.dart';
import '../playlist_model.dart';
import '../song_model.dart';
import '../api_service.dart';
import 'theme.dart';
import 'album_art.dart';
import 'apple_music_widgets.dart';
import 'song_action_sheet.dart';

class PlaylistScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final playlist = provider.userPlaylists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => Playlist(id: '', name: 'Not Found'),
    );

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6E6E73);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: isDark ? const Color(0xFF0F1420) : Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            leading: FrostedCircleButton(
              icon: CupertinoIcons.chevron_back,
              size: 38,
              iconSize: 20,
              iconColor: textColor,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              FrostedCircleButton(
                icon: CupertinoIcons.pencil,
                size: 38,
                iconSize: 18,
                iconColor: textColor,
                onPressed: () => _showRenameDialog(context, provider, playlist, isDark),
              ),
              const SizedBox(width: 8),
              FrostedCircleButton(
                icon: CupertinoIcons.plus,
                size: 38,
                iconSize: 18,
                iconColor: AppTheme.accentColor1,
                onPressed: () => _showAddSongsDialog(context, provider, playlist, isDark),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHeroCover(context, playlist, isDark, textColor, subtextColor),
            ),
          ),

          // ── Action Buttons: Play All & Shuffle ──
          if (playlist.songs.isNotEmpty)
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
                            if (playlist.songs.isNotEmpty) {
                              provider.playSong(playlist.songs.first, playlist: playlist.songs);
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
                            if (playlist.songs.isNotEmpty) {
                              final shuffled = List<Song>.from(playlist.songs)..shuffle();
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

          // ── Song Count & Track List Header ──
          if (playlist.songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${playlist.songs.length} TRACK${playlist.songs.length == 1 ? '' : 'S'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: subtextColor,
                      ),
                    ),
                    Text(
                      'Drag handle to reorder',
                      style: TextStyle(fontSize: 11, color: subtextColor.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Reorderable Song List ──
          if (playlist.songs.isEmpty)
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
                        child: const Icon(CupertinoIcons.music_albums, size: 54, color: AppTheme.accentColor1),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Empty Playlist',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add songs to build your dream music collection',
                        style: TextStyle(color: subtextColor, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: AppTheme.accentGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor1.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddSongsDialog(context, provider, playlist, isDark),
                          icon: const Icon(CupertinoIcons.plus_circle_fill, color: Colors.white, size: 20),
                          label: const Text(
                            'Add Songs',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 110),
              sliver: SliverReorderableList(
                itemCount: playlist.songs.length,
                onReorder: (oldIndex, newIndex) {
                  provider.reorderPlaylistSong(playlist.id, oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final song = playlist.songs[index];
                  final isPlaying = provider.currentSong?.id == song.id;

                  return ReorderableDelayedDragStartListener(
                    key: ValueKey('${playlist.id}_${song.id}_$index'),
                    index: index,
                    child: Container(
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
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isPlaying ? AppTheme.accentColor1 : subtextColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: AlbumArt(
                                  song: song,
                                  width: 44,
                                  height: 44,
                                  iconSize: 22,
                                ),
                              ),
                            ),
                          ],
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
                              icon: const Icon(CupertinoIcons.minus_circle, color: Color(0xFFFF453A), size: 18),
                              tooltip: 'Remove from playlist',
                              onPressed: () {
                                provider.removeSongFromPlaylist(playlist.id, song);
                              },
                            ),
                            IconButton(
                              icon: Icon(CupertinoIcons.ellipsis, color: subtextColor, size: 18),
                              onPressed: () => SongActionSheet.show(context, song),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                CupertinoIcons.bars,
                                color: subtextColor.withValues(alpha: 0.6),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => provider.playSong(song, playlist: playlist.songs),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCover(
    BuildContext context,
    Playlist playlist,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF2C142A), Color(0xFF141926), Colors.black]
              : const [Color(0xFFFFE5EC), Color(0xFFEFF2F8), Color(0xFFF2F2F7)],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Squircle Album Mosaic / Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFA2D48), Color(0xFF9013FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFA2D48).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(CupertinoIcons.music_albums_fill, color: Colors.white, size: 50),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                playlist.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Personalized Playlist • ${playlist.songs.length} items',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: subtextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, MusicProvider provider, Playlist playlist, bool isDark) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C2230) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Rename Playlist',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1E), fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1E)),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                provider.renamePlaylist(playlist.id, name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddSongsDialog(BuildContext context, MusicProvider provider, Playlist playlist, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddSongsSheet(playlistId: playlist.id, isDark: isDark),
    );
  }
}

/// Bottom sheet for searching and adding songs to a playlist
class _AddSongsSheet extends StatefulWidget {
  final String playlistId;
  final bool isDark;
  const _AddSongsSheet({required this.playlistId, required this.isDark});

  @override
  State<_AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends State<_AddSongsSheet> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Song> _results = [];
  bool _isSearching = false;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final results = await _apiService.searchSongs(query, limit: 25);
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final playlist = provider.userPlaylists.firstWhere(
      (p) => p.id == widget.playlistId,
      orElse: () => Playlist(id: '', name: ''),
    );
    final existingIds = playlist.songs.map((s) => s.id).toSet();
    final isDark = widget.isDark;

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6E6E73);

    List<Song> sourceSongs;
    String headerText;
    if (_results.isNotEmpty) {
      sourceSongs = _results;
      headerText = 'Search Results';
    } else {
      final suggestions = <Song>[];
      for (final s in provider.recentlyPlayed) {
        if (!suggestions.any((x) => x.id == s.id)) suggestions.add(s);
      }
      for (final s in provider.favorites) {
        if (!suggestions.any((x) => x.id == s.id)) suggestions.add(s);
      }
      sourceSongs = suggestions;
      headerText = 'Recommended Tracks';
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141926).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.9),
              width: 1,
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      'Add to "${playlist.name}"',
                      style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search songs to add...',
                          hintStyle: TextStyle(color: subtextColor),
                          prefixIcon: Icon(CupertinoIcons.search, color: subtextColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppTheme.accentColor1),
                    ),
                  if (!_isSearching && sourceSongs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          headerText.toUpperCase(),
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: sourceSongs.length,
                      itemBuilder: (context, index) {
                        final song = sourceSongs[index];
                        final alreadyAdded = existingIds.contains(song.id);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: AlbumArt(song: song, width: 46, height: 46, iconSize: 22),
                            ),
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: textColor),
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: subtextColor),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.accentColor1, size: 24)
                              : IconButton(
                                  icon: const Icon(CupertinoIcons.plus_circle, color: AppTheme.accentBlue, size: 24),
                                  onPressed: () {
                                    provider.addSongToPlaylist(widget.playlistId, song);
                                    setState(() {});
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
