import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../theme_provider.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';
import 'apple_music_widgets.dart';
import 'song_action_sheet.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6E6E73);

    final queue = provider.currentPlaylist;
    final currentIndex = provider.currentPlaylistIndex;
    final currentSong = provider.currentSong;

    List<Song> previouslyPlayed = [];
    List<Song> upNext = [];

    if (queue.isNotEmpty && currentIndex >= 0) {
      previouslyPlayed = queue.sublist(0, currentIndex);
      if (currentIndex + 1 < queue.length) {
        upNext = queue.sublist(currentIndex + 1);
      }
    } else if (provider.recentlyPlayed.isNotEmpty) {
      previouslyPlayed = provider.recentlyPlayed;
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          // Deep Blue/Navy Gradient Background (Image 5)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF0F264A),
                          Color(0xFF0A1932),
                          Color(0xFF050D1A),
                          Colors.black,
                        ]
                      : const [
                          Color(0xFFD6E4F8),
                          Color(0xFFE9F0FA),
                          Color(0xFFF2F2F7),
                          Color(0xFFF2F2F7),
                        ],
                  stops: const [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header (Image 5)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FrostedCircleButton(
                        icon: CupertinoIcons.chevron_down,
                        size: 40,
                        iconSize: 20,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Playing Next',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      FrostedCircleButton(
                        icon: CupertinoIcons.ellipsis,
                        size: 40,
                        iconSize: 18,
                        onPressed: () {
                          if (currentSong != null) {
                            SongActionSheet.show(context, currentSong);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Currently Playing Track Card (Image 5)
                if (currentSong != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.90),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: AlbumArt(
                                song: currentSong,
                                width: 56,
                                height: 56,
                                iconSize: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (currentSong.isExplicit) const ExplicitBadge(size: 13),
                                    Expanded(
                                      child: Text(
                                        currentSong.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  currentSong.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FrostedCircleButton(
                            icon: provider.isFavorite(currentSong)
                                ? CupertinoIcons.star_fill
                                : CupertinoIcons.star,
                            iconColor: provider.isFavorite(currentSong)
                                ? const Color(0xFFFFD60A)
                                : (isDark ? Colors.white : Colors.black87),
                            size: 38,
                            iconSize: 18,
                            onPressed: () => provider.toggleFavorite(currentSong),
                          ),
                          const SizedBox(width: 8),
                          FrostedCircleButton(
                            icon: CupertinoIcons.ellipsis,
                            size: 38,
                            iconSize: 18,
                            onPressed: () => SongActionSheet.show(context, currentSong),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

                const SizedBox(height: 12),

                // Action Pills Row: Shuffle, Repeat, Infinite Autoplay (Image 5)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FrostedPillButton(
                        icon: CupertinoIcons.shuffle,
                        isActive: provider.isShuffleEnabled,
                        width: 90,
                        onPressed: provider.toggleShuffle,
                      ),
                      FrostedPillButton(
                        icon: provider.repeatMode == PlaybackRepeatMode.one
                            ? CupertinoIcons.repeat_1
                            : CupertinoIcons.repeat,
                        isActive: provider.repeatMode != PlaybackRepeatMode.off,
                        width: 90,
                        onPressed: provider.toggleRepeat,
                      ),
                      FrostedPillButton(
                        icon: CupertinoIcons.infinite,
                        isActive: true,
                        width: 90,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Autoplay / Infinite radio is active'),
                              backgroundColor: Color(0xFF22242B),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // History & Up Next Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'History',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          provider.clearHistory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Playback history cleared'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Queue / History Content (Image 5)
                Expanded(
                  child: upNext.isEmpty && previouslyPlayed.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.music_albums,
                                size: 50,
                                color: subtextColor.withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "There's no music in the queue",
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 20),
                          children: [
                            if (upNext.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                                child: Text(
                                  'Up Next (${upNext.length})',
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...upNext.asMap().entries.map((entry) {
                                final song = entry.value;
                                return _buildQueueTile(
                                  context,
                                  song: song,
                                  isPlaying: false,
                                  textColor: textColor,
                                  subtextColor: subtextColor,
                                  onTap: () => provider.playSong(song),
                                  onMore: () => SongActionSheet.show(context, song),
                                );
                              }),
                            ],
                            if (previouslyPlayed.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                                child: Text(
                                  'Previously Played',
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...previouslyPlayed.map((song) {
                                return _buildQueueTile(
                                  context,
                                  song: song,
                                  isPlaying: false,
                                  textColor: textColor,
                                  subtextColor: subtextColor,
                                  onTap: () => provider.playSong(song),
                                  onMore: () => SongActionSheet.show(context, song),
                                );
                              }),
                            ],
                          ],
                        ),
                ),

                // Bottom Scrubber & Mini Controls matching Image 5
                _buildBottomControlsBar(context, provider, textColor, subtextColor, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTile(
    BuildContext context, {
    required Song song,
    required bool isPlaying,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
    required VoidCallback onMore,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: ClipRRect(
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
      title: Row(
        children: [
          if (song.isExplicit) const ExplicitBadge(size: 11),
          Expanded(
            child: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: subtextColor,
          fontSize: 12,
        ),
      ),
      trailing: IconButton(
        icon: Icon(CupertinoIcons.ellipsis, color: subtextColor, size: 16),
        onPressed: onMore,
      ),
      onTap: onTap,
    );
  }

  /// Scrubber & Playback controls matching bottom of Image 5
  Widget _buildBottomControlsBar(BuildContext context, MusicProvider provider, Color textColor, Color subtextColor, bool isDark) {
    return StreamBuilder<Duration?>(
      stream: provider.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = provider.audioPlayer.duration ?? Duration.zero;
        final remaining = duration > position ? duration - position : Duration.zero;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.74),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.90),
                  ),
                ),
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: isDark ? Colors.white : AppTheme.accentColor1,
                  inactiveTrackColor: isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.1),
                  thumbColor: isDark ? Colors.white : AppTheme.accentColor1,
                ),
                child: Slider(
                  value: duration.inMilliseconds > 0
                      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0,
                  onChanged: (val) {
                    if (duration.inMilliseconds > 0) {
                      provider.audioPlayer.seek(
                        Duration(milliseconds: (val * duration.inMilliseconds).round()),
                      );
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const LosslessBadge(label: 'Lossless'),
                    Text(
                      '-${_formatDuration(remaining)}',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(CupertinoIcons.backward_fill, color: textColor, size: 28),
                    onPressed: provider.playPrevious,
                  ),
                  const SizedBox(width: 24),
                  StreamBuilder<PlayerState>(
                    stream: provider.audioPlayer.playerStateStream,
                    builder: (context, psSnap) {
                      final isPlaying = psSnap.data?.playing == true;
                      return GestureDetector(
                        onTap: () {
                          if (isPlaying) {
                            provider.audioPlayer.pause();
                          } else {
                            provider.audioPlayer.play();
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          child: Center(
                            child: Icon(
                              isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                              color: isDark ? Colors.black : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: Icon(CupertinoIcons.forward_fill, color: textColor, size: 28),
                    onPressed: provider.playNext,
                  ),
                ],
              ),
            ],
          ),
        ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}
