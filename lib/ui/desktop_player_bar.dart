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
import 'player_screen.dart';
import 'queue_screen.dart';
import 'lyrics_sheet.dart';
import 'apple_music_widgets.dart';
import 'song_action_sheet.dart';

class DesktopPlayerBar extends StatelessWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final song = provider.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.60) : const Color(0xFF64748B);
    final iconColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0A0F1A).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.78),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.92),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Left: Track Info (Album art, Title, Artist, Star, More) ──
              SizedBox(
                width: 280,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const PlayerScreen(),
                            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: AlbumArt(
                            song: song,
                            width: 52,
                            height: 52,
                            iconSize: 26,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (song.isExplicit) const ExplicitBadge(size: 12),
                              Expanded(
                                child: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        provider.isFavorite(song) ? CupertinoIcons.star_fill : CupertinoIcons.star,
                        size: 20,
                        color: provider.isFavorite(song) ? const Color(0xFFFFB800) : subtextColor,
                      ),
                      tooltip: provider.isFavorite(song) ? 'Favorited' : 'Favorite',
                      onPressed: () => provider.toggleFavorite(song),
                    ),
                    IconButton(
                      icon: Icon(CupertinoIcons.ellipsis, size: 18, color: subtextColor),
                      tooltip: 'More actions',
                      onPressed: () => SongActionSheet.show(context, song),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ── Center: Main Playback Controls & Scrubber ──
              Expanded(
                child: StreamBuilder<Duration?>(
                  stream: provider.audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = provider.audioPlayer.duration ?? Duration.zero;
                    final remaining = duration > position ? duration - position : Duration.zero;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Control Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Shuffle
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.shuffle,
                                size: 18,
                                color: provider.isShuffleEnabled ? AppTheme.accentColor1 : subtextColor,
                              ),
                              tooltip: 'Shuffle',
                              onPressed: provider.toggleShuffle,
                            ),
                            const SizedBox(width: 8),

                            // Previous
                            IconButton(
                              icon: Icon(CupertinoIcons.backward_fill, color: iconColor, size: 22),
                              tooltip: 'Previous',
                              onPressed: provider.playPrevious,
                            ),
                            const SizedBox(width: 8),

                            // Play / Pause Big Center Button
                            StreamBuilder<PlayerState>(
                              stream: provider.audioPlayer.playerStateStream,
                              builder: (context, pStateSnap) {
                                final playerState = pStateSnap.data;
                                final playing = playerState?.playing;
                                final processing = playerState?.processingState;
                                final isPlaying = playing == true && processing != ProcessingState.completed;

                                return GestureDetector(
                                  onTap: () {
                                    if (isPlaying) {
                                      provider.audioPlayer.pause();
                                    } else {
                                      provider.audioPlayer.play();
                                    }
                                  },
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                                        size: 18,
                                        color: isDark ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),

                            // Next
                            IconButton(
                              icon: Icon(CupertinoIcons.forward_fill, color: iconColor, size: 22),
                              tooltip: 'Next',
                              onPressed: provider.playNext,
                            ),
                            const SizedBox(width: 8),

                            // Repeat
                            IconButton(
                              icon: Icon(
                                provider.repeatMode == PlaybackRepeatMode.one
                                    ? CupertinoIcons.repeat_1
                                    : CupertinoIcons.repeat,
                                size: 18,
                                color: provider.repeatMode != PlaybackRepeatMode.off
                                    ? AppTheme.accentColor1
                                    : subtextColor,
                              ),
                              tooltip: 'Repeat',
                              onPressed: provider.toggleRepeat,
                            ),
                          ],
                        ),

                        // Scrubber & Times Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                _formatDuration(position),
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                    activeTrackColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                    inactiveTrackColor: isDark
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : Colors.black.withValues(alpha: 0.10),
                                    thumbColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  child: Slider(
                                    value: duration.inMilliseconds > 0
                                        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                                        : 0.0,
                                    onChanged: (value) {
                                      if (duration.inMilliseconds > 0) {
                                        playerSeek(provider, value, duration);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const LosslessBadge(label: 'Hi-Res Lossless'),
                              const SizedBox(width: 10),
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
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(width: 16),

              // ── Right: Live Lyrics, Queue, Volume Slider & Fullscreen ──
              SizedBox(
                width: 290,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Lyrics
                    IconButton(
                      icon: Icon(CupertinoIcons.quote_bubble, size: 20, color: subtextColor),
                      tooltip: 'Lyrics',
                      onPressed: () => LyricsSheet.show(context, song),
                    ),

                    // Queue
                    IconButton(
                      icon: Icon(CupertinoIcons.list_bullet, size: 20, color: subtextColor),
                      tooltip: 'Playing Next / Queue',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QueueScreen()),
                        );
                      },
                    ),

                    // Volume Icon & Slider
                    StreamBuilder<double>(
                      stream: provider.audioPlayer.volumeStream,
                      builder: (context, volSnap) {
                        final vol = volSnap.data ?? provider.audioPlayer.volume;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                provider.audioPlayer.setVolume(vol > 0 ? 0 : 0.8);
                              },
                              child: Icon(
                                vol == 0
                                    ? CupertinoIcons.volume_off
                                    : (vol > 0.5 ? CupertinoIcons.volume_up : CupertinoIcons.volume_down),
                                size: 18,
                                color: subtextColor,
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                                  activeTrackColor: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                  inactiveTrackColor: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.10),
                                  thumbColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                child: Slider(
                                  value: vol.clamp(0.0, 1.0),
                                  onChanged: (val) {
                                    provider.audioPlayer.setVolume(val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // Fullscreen Expand to PlayerScreen
                    IconButton(
                      icon: Icon(CupertinoIcons.fullscreen, size: 19, color: subtextColor),
                      tooltip: 'Full Screen Player',
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const PlayerScreen(),
                            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void playerSeek(MusicProvider provider, double value, Duration duration) {
    provider.audioPlayer.seek(Duration(milliseconds: (value * duration.inMilliseconds).round()));
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
