import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../song_model.dart';
import '../theme_provider.dart';
import 'player_screen.dart';
import 'album_art.dart';
import 'theme.dart';
import 'apple_music_widgets.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final song = provider.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.65) : const Color(0xFF6E6E73);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 380),
              reverseTransitionDuration: const Duration(milliseconds: 320),
              pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const curve = Curves.easeOutCubic;
                final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: child,
                );
              },
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E2430).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.92),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        // Album Art
                        _buildAlbumArt(song),

                        const SizedBox(width: 12),

                        // Title & Artist
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  if (song.isExplicit) const ExplicitBadge(size: 13),
                                  Expanded(
                                    child: Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                        fontSize: 14,
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
                                  color: subtextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Animated playing waves indicator
                        StreamBuilder<PlayerState>(
                          stream: provider.audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final playing = snapshot.data?.playing == true;
                            if (!playing) return const SizedBox.shrink();

                            return AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildEqualizerBar(6 + (10 * _pulseController.value)),
                                    const SizedBox(width: 2.5),
                                    _buildEqualizerBar(16 - (10 * _pulseController.value)),
                                    const SizedBox(width: 2.5),
                                    _buildEqualizerBar(10 + (6 * _pulseController.value)),
                                  ],
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(width: 4),

                        // Play/Pause Button
                        StreamBuilder<PlayerState>(
                          stream: provider.audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final processingState = playerState?.processingState;
                            final playing = playerState?.playing;

                            if (provider.isResolvingAudio ||
                                processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: textColor,
                                  ),
                                ),
                              );
                            }

                            final isPlaying = playing == true && processingState != ProcessingState.completed;

                            return IconButton(
                              icon: Icon(
                                isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                                color: textColor,
                                size: 24,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  provider.audioPlayer.pause();
                                } else if (processingState == ProcessingState.completed) {
                                  provider.audioPlayer.seek(Duration.zero);
                                  provider.audioPlayer.play();
                                } else {
                                  provider.audioPlayer.play();
                                }
                              },
                            );
                          },
                        ),

                        // Next Track Button
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.forward_fill,
                            color: textColor,
                            size: 22,
                          ),
                          onPressed: provider.playNext,
                        ),
                      ],
                    ),
                  ),

                  // Bottom subtle progress bar indicator
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: StreamBuilder<Duration?>(
                      stream: provider.audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = provider.audioPlayer.duration ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0
                            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0;

                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 2.5,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(Song song) {
    final art = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 46,
        height: 46,
        child: AlbumArt(
          song: song,
          width: 46,
          height: 46,
          iconSize: 24,
        ),
      ),
    );

    // If canvas mode is active for this song, do not attach a Hero flight.
    // Otherwise, during route transition the normal album art flies to the center
    // and flashes for a fraction of a second before canvas mode takes over.
    if (PlayerScreen.isCanvasActiveForSong(song.id)) {
      return art;
    }

    return Hero(
      tag: 'album_art_${song.id}',
      child: art,
    );
  }

  Widget _buildEqualizerBar(double height) {
    return Container(
      width: 2.8,
      height: height.clamp(4.0, 18.0),
      decoration: BoxDecoration(
        color: AppTheme.accentColor1,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
