import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import 'theme.dart';
import 'album_art.dart';
import 'apple_music_widgets.dart';

class CarModeScreen extends StatefulWidget {
  const CarModeScreen({super.key});

  @override
  State<CarModeScreen> createState() => _CarModeScreenState();
}

class _CarModeScreenState extends State<CarModeScreen> {
  @override
  void initState() {
    super.initState();
    // Force landscape for automotive dashboard experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "0:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient blurred background from current song
          if (song != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.35,
                child: AlbumArt(
                  song: song,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.zero,
                  iconSize: 100,
                ),
              ),
            ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      const Color(0xFF070B14).withValues(alpha: 0.92),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: song == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.car_detailed, color: Colors.white38, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          "No song playing",
                          style: TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(CupertinoIcons.chevron_back),
                          label: const Text('Exit Car Mode'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor1,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Row(
                      children: [
                        // Left Column: Album Art with subtle glow
                        Padding(
                          padding: const EdgeInsets.only(right: 28.0),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentColor1.withValues(alpha: 0.35),
                                      blurRadius: 35,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: AlbumArt(
                                    song: song,
                                    width: double.infinity,
                                    height: double.infinity,
                                    iconSize: 72,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Center: Glanceable Title, Artist, and High-Contrast Scrubber
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Top HUD pill with Car Mode indicator & Exit Button
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(CupertinoIcons.car_detailed, color: AppTheme.accentColor1, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'CAR MODE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // Exit HUD Button
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(CupertinoIcons.xmark, color: Colors.white, size: 14),
                                          SizedBox(width: 6),
                                          Text(
                                            'EXIT',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // Track Title
                              Row(
                                children: [
                                  if (song.isExplicit) const ExplicitBadge(size: 16),
                                  Expanded(
                                    child: Text(
                                      song.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.6,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Artist
                              Text(
                                song.artist,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.70),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const Spacer(),

                              // Scrubber Section
                              StreamBuilder<Duration>(
                                stream: provider.audioPlayer.positionStream,
                                builder: (context, snapshot) {
                                  final position = snapshot.data ?? Duration.zero;
                                  final duration = provider.audioPlayer.duration ?? Duration.zero;

                                  double progress = 0.0;
                                  if (duration.inMilliseconds > 0) {
                                    progress = position.inMilliseconds / duration.inMilliseconds;
                                  }
                                  progress = progress.clamp(0.0, 1.0);

                                  return Column(
                                    children: [
                                      SliderTheme(
                                        data: SliderThemeData(
                                          trackHeight: 10,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                                          activeTrackColor: AppTheme.accentColor1,
                                          inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                                          thumbColor: Colors.white,
                                        ),
                                        child: Slider(
                                          value: progress,
                                          onChanged: (value) {
                                            final newPosition = Duration(
                                              milliseconds: (value * duration.inMilliseconds).round(),
                                            );
                                            provider.audioPlayer.seek(newPosition);
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDuration(position),
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.65),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                fontFeatures: const [FontFeature.tabularFigures()],
                                              ),
                                            ),
                                            Text(
                                              _formatDuration(duration),
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.65),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                fontFeatures: const [FontFeature.tabularFigures()],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Right Column: Big Tactile Controls
                        SizedBox(
                          width: 140,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Previous Track
                              _buildLargeCarButton(
                                icon: CupertinoIcons.backward_fill,
                                size: 64,
                                iconSize: 28,
                                onPressed: () => provider.playPrevious(),
                              ),

                              // Play / Pause / Buffering Indicator
                              StreamBuilder<PlayerState>(
                                stream: provider.audioPlayer.playerStateStream,
                                builder: (context, snapshot) {
                                  final playerState = snapshot.data;
                                  final processingState = playerState?.processingState;
                                  final playing = playerState?.playing;

                                  final isLoading = processingState == ProcessingState.loading ||
                                      processingState == ProcessingState.buffering ||
                                      provider.isResolvingAudio;

                                  if (isLoading) {
                                    return Container(
                                      width: 82,
                                      height: 82,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppTheme.accentGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accentColor1.withValues(alpha: 0.45),
                                            blurRadius: 20,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                        ),
                                      ),
                                    );
                                  }

                                  final isPlaying = playing == true && processingState != ProcessingState.completed;

                                  return GestureDetector(
                                    onTap: () {
                                      if (isPlaying) {
                                        provider.audioPlayer.pause();
                                      } else if (processingState == ProcessingState.completed) {
                                        provider.audioPlayer.seek(Duration.zero);
                                        provider.audioPlayer.play();
                                      } else {
                                        provider.audioPlayer.play();
                                      }
                                    },
                                    child: Container(
                                      width: 82,
                                      height: 82,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppTheme.accentGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accentColor1.withValues(alpha: 0.45),
                                            blurRadius: 22,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Next Track
                              _buildLargeCarButton(
                                icon: CupertinoIcons.forward_fill,
                                size: 64,
                                iconSize: 28,
                                onPressed: () => provider.playNext(),
                              ),

                              // Bottom action: Favorite
                              IconButton(
                                icon: Icon(
                                  provider.isFavorite(song) ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                                  color: provider.isFavorite(song) ? AppTheme.accentColor1 : Colors.white60,
                                  size: 32,
                                ),
                                onPressed: () => provider.toggleFavorite(song),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeCarButton({
    required IconData icon,
    required double size,
    required double iconSize,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}
