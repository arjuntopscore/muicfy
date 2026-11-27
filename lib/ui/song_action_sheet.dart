import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../theme_provider.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';
import 'lyrics_sheet.dart';
import 'artist_screen.dart';

class SongActionSheet extends StatelessWidget {
  final Song song;

  const SongActionSheet({super.key, required this.song});

  static Future<void> show(BuildContext context, Song song) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => SongActionSheet(song: song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final isFav = provider.isFavorite(song);
    final isLocal = song.isLocal;

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.65) : const Color(0xFF6E6E73);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF141923) : Colors.white).withValues(alpha: isDark ? 0.90 : 0.78),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.90),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.10),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),

              // Song Info Header (Image 6 style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Hero(
                      tag: 'action_sheet_art_${song.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AlbumArt(
                          song: song,
                          width: 54,
                          height: 54,
                          iconSize: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (song.album.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              song.album,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtextColor.withValues(alpha: 0.7),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quick Actions Row: Like, Dislike, Share (Image 2 style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.90),
                    ),
                    boxShadow: !isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTopActionButton(
                        context,
                        icon: isFav ? CupertinoIcons.star_fill : CupertinoIcons.star,
                        label: isFav ? 'Favorited' : 'Like',
                        iconColor: isFav ? const Color(0xFFFFD60A) : textColor,
                        labelColor: subtextColor,
                        onTap: () {
                          provider.toggleFavorite(song);
                        },
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.90),
                      ),
                      _buildTopActionButton(
                        context,
                        icon: CupertinoIcons.heart_slash,
                        label: 'Dislike',
                        iconColor: subtextColor,
                        labelColor: subtextColor,
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tuned recommendation: Less like this'),
                              backgroundColor: Color(0xFF22242B),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                      ),
                      _buildTopActionButton(
                        context,
                        icon: CupertinoIcons.share,
                        label: 'Share',
                        iconColor: textColor,
                        labelColor: subtextColor,
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sharing "${song.title}" by ${song.artist}'),
                              backgroundColor: const Color(0xFF22242B),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Options Menu List (Image 2 & Image 6)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.radio_rounded,
                      title: 'Start radio',
                      subtitle: 'Generate station based on track',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        provider.playSong(song, playlist: [song, ...provider.topSongs]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Radio station started for ${song.title}'),
                            backgroundColor: const Color(0xFF22242B),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: CupertinoIcons.text_badge_plus,
                      title: 'Add to playlist',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                      onTap: () => _showPlaylistDialog(context, provider, isDark, textColor, subtextColor),
                    ),
                    _buildMenuItem(
                      context,
                      icon: CupertinoIcons.text_insert,
                      title: 'Play next',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        provider.playNextInQueue(song);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Will play next in queue'),
                            backgroundColor: Color(0xFF22242B),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: CupertinoIcons.text_append,
                      title: 'Add to queue',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        provider.addSongToQueue(song);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to queue'),
                            backgroundColor: Color(0xFF22242B),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: isLocal
                          ? CupertinoIcons.trash
                          : CupertinoIcons.arrow_down_circle,
                      title: isLocal ? 'Remove from cache' : 'Download',
                      titleColor: isLocal ? const Color(0xFFFF453A) : textColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        if (isLocal) {
                          provider.deleteLocalSong(song);
                        } else {
                          provider.downloadSong(song, context);
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: CupertinoIcons.quote_bubble,
                      title: 'View lyrics',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        LyricsSheet.show(context, song);
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: CupertinoIcons.mic,
                      title: 'Open artist',
                      subtitle: song.artist,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtistScreen(artistName: song.artist),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: CupertinoIcons.info_circle,
                      title: 'Song info',
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                      onTap: () => _showSongInfoDialog(context, isDark, textColor, subtextColor),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor ?? Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: labelColor ?? Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Icon(
            icon,
            color: titleColor ?? textColor,
            size: 20,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? textColor,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: subtextColor,
                fontSize: 12,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: subtextColor.withValues(alpha: 0.4),
        size: 18,
      ),
      onTap: onTap,
    );
  }

  void _showPlaylistDialog(BuildContext context, MusicProvider provider, bool isDark, Color textColor, Color subtextColor) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF161B24) : Colors.white).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Add to Playlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 12),
                if (provider.userPlaylists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No playlists created yet.\nGo to Library tab to create one!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtextColor),
                      ),
                    ),
                  )
                else
                  ...provider.userPlaylists.map((pl) {
                    return ListTile(
                      leading: const Icon(CupertinoIcons.music_albums, color: AppTheme.accentColor1),
                      title: Text(pl.name, style: TextStyle(color: textColor)),
                      subtitle: Text('${pl.songs.length} songs', style: TextStyle(color: subtextColor)),
                      onTap: () {
                        provider.addSongToPlaylist(pl.id, song);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to ${pl.name}'),
                            backgroundColor: const Color(0xFF22242B),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSongInfoDialog(BuildContext context, bool isDark, Color textColor, Color subtextColor) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: (isDark ? const Color(0xFF1A1F2B) : Colors.white).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          title: Text('Song Info', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Title', song.title, textColor, subtextColor),
              _infoRow('Artist', song.artist, textColor, subtextColor),
              _infoRow('Album', song.album.isNotEmpty ? song.album : 'Single', textColor, subtextColor),
              _infoRow('Language', song.language.toUpperCase(), textColor, subtextColor),
              _infoRow('Quality', 'Hi-Res Lossless (ALAC / AAC 320 kbps)', textColor, subtextColor),
              _infoRow('Type', song.isLocal ? 'Offline Storage' : 'Stream / Cloud', textColor, subtextColor),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color textColor, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: subtextColor, fontSize: 12.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
