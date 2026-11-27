import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../song_model.dart';
import '../youtube_video_service.dart';
import 'album_art.dart';
import 'apple_music_widgets.dart';
import 'theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final YouTubeVideoResult videoResult;
  final Song song;

  const VideoPlayerScreen({
    super.key,
    required this.videoResult,
    required this.song,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoResult.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        enableCaption: false,
      ),
    );

    // Allow auto-rotation between portrait and landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void deactivate() {
    _controller.pauseVideo();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.close();

    // Always restore portrait orientation and system UI edge-to-edge
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Ambient Cinema Glow Backdrop (Apple TV / YouTube Ambient Mode) ──
            Positioned.fill(
              child: AlbumArt(
                song: widget.song,
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
                iconSize: 120,
              ),
            ),

            // Deep blur backdrop filter with obsidian vignette
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.84),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Center Video Player (Official Player with 1080p, 720p & Full Audio) ──
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isLandscape ? 0 : 16),
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                  autoFullScreen: true,
                  enableFullScreenOnVerticalDrag: true,
                ),
              ),
            ),

            // ── Top Bar Controls (Back, Title, HD Badge, Rotate Button) ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 24 : 16,
                    vertical: isLandscape ? 8 : 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Frosted Dismiss Circle Button
                      FrostedCircleButton(
                        icon: CupertinoIcons.chevron_down,
                        iconSize: 20,
                        size: 40,
                        iconColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        onPressed: () {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                            DeviceOrientation.portraitDown,
                          ]);
                          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                          Navigator.pop(context);
                        },
                      ),

                      const SizedBox(width: 12),

                      // Song & Video Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                if (widget.song.isExplicit) const ExplicitBadge(size: 14),
                                Expanded(
                                  child: Text(
                                    widget.song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isLandscape ? 15 : 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B30).withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFFF3B30).withValues(alpha: 0.45),
                                      width: 0.7,
                                    ),
                                  ),
                                  child: const Text(
                                    'OFFICIAL VIDEO',
                                    style: TextStyle(
                                      color: Color(0xFFFF453A),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.70),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Full HD Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor1.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentColor1.withValues(alpha: 0.60),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.sparkles,
                              size: 12,
                              color: AppTheme.accentColor1,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '1080p HD',
                              style: TextStyle(
                                color: AppTheme.accentColor1,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Rotate / Fullscreen Toggle Button
                      FrostedCircleButton(
                        icon: isLandscape
                            ? CupertinoIcons.device_phone_portrait
                            : CupertinoIcons.device_phone_landscape,
                        iconSize: 18,
                        size: 38,
                        iconColor: isLandscape ? AppTheme.accentColor1 : Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        onPressed: () {
                          _controller.toggleFullScreen();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
