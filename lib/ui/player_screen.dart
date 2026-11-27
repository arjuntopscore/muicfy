import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../music_provider.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';
import 'queue_screen.dart';
import 'lyrics_sheet.dart';
import 'car_mode_screen.dart';
import '../youtube_video_service.dart';
import 'video_player_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  /// Check whether Canvas mode is currently active and initialized for a given song.
  /// Used by MiniPlayer to avoid triggering a Hero flight of the album art when
  /// expanding directly into Canvas mode.
  static bool isCanvasActiveForSong(String? songId) {
    return _PlayerScreenState.isCanvasActiveForSong(songId);
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const Duration _autoCanvasRevealAt = Duration(seconds: 10);

  // Persistent canvas session across PlayerScreen open/close navigation
  static VideoPlayerController? _cachedController;
  static String? _cachedSongId;
  static bool _persistedShowCanvas = false;
  static bool _persistedUserDisabled = false;

  static bool isCanvasActiveForSong(String? songId) {
    if (songId == null) return false;
    return _persistedShowCanvas &&
        !_persistedUserDisabled &&
        _cachedSongId == songId &&
        _cachedController != null &&
        _cachedController!.value.isInitialized;
  }

  bool _showCanvas = _persistedShowCanvas;
  VideoPlayerController? _canvasController = _cachedController;
  String? _loadedSongId = _cachedSongId;
  bool _isLoadingCanvas = false;
  bool _userDisabledCanvas = _persistedUserDisabled;
  bool _autoShowPending = false;
  bool _animateCanvasTransition = false;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;

  @override
  void initState() {
    super.initState();

    final provider = Provider.of<MusicProvider>(context, listen: false);
    final song = provider.currentSong;

    // Immediately restore Canvas state if this track was already playing in canvas mode
    if (song != null && _cachedSongId == song.id && _cachedController != null) {
      final cached = _cachedController;
      if (cached != null && cached.value.isInitialized) {
        _canvasController = cached;
        _loadedSongId = song.id;
        _showCanvas = _persistedShowCanvas;
        _userDisabledCanvas = _persistedUserDisabled;
        if (_showCanvas && provider.audioPlayer.playing) {
          cached.play();
        }
      } else {
        _canvasController = null;
        _showCanvas = false;
        _loadedSongId = null;
      }
    } else {
      _canvasController = null;
      _showCanvas = false;
      _loadedSongId = null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Sync play/pause with canvas loop (only while canvas is visible)
      _playerStateSub = provider.audioPlayer.playerStateStream.listen((state) {
        final controller = _canvasController;
        if (controller != null && controller.value.isInitialized && _showCanvas) {
          if (state.playing) {
            controller.play();
          } else {
            controller.pause();
          }
        }
      });

      // Auto-reveal canvas once 10s of the track has played
      _positionSub = provider.audioPlayer.positionStream.listen((position) {
        if (!mounted) return;
        if (_showCanvas || _userDisabledCanvas) return;
        if (position >= _autoCanvasRevealAt) {
          _revealCanvas(provider);
        }
      });
    });
  }

  void _revealCanvas(MusicProvider provider) {
    final controller = _canvasController;
    if (controller != null && controller.value.isInitialized) {
      setState(() {
        _animateCanvasTransition = true;
        _showCanvas = true;
      });
      _persistedShowCanvas = true;
      if (provider.audioPlayer.playing) {
        controller.play();
      }
    } else {
      // Canvas still downloading — queue the transition until it finishes
      _autoShowPending = true;
    }
  }

  Future<void> _loadCanvasForSong(Song song, MusicProvider provider) async {
    if (_loadedSongId == song.id && _canvasController != null) {
      return;
    }

    if (_cachedSongId != song.id) {
      final old = _cachedController;
      if (old != null) {
        _cachedController = null;
        await old.dispose();
      }
      _cachedSongId = null;
      _persistedShowCanvas = false;
      _persistedUserDisabled = false;
    }

    final oldController = _canvasController;
    if (oldController != null && oldController != _cachedController) {
      _canvasController = null;
      await oldController.dispose();
    }

    _isLoadingCanvas = true;
    _loadedSongId = song.id;

    try {
      // 1. Download or load cached 1080p Full HD Canvas loop (~10s chorus clip)
      final canvasFile = await YoutubeVideoService().get1080pCanvasClip(song);

      if (canvasFile == null || !await canvasFile.exists()) {
        if (mounted) {
          setState(() {
            _isLoadingCanvas = false;
            _loadedSongId = null;
          });
        }
        return;
      }

      final controller = VideoPlayerController.file(
        canvasFile,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      await controller.setVolume(0.0); // Muted: audio streams cleanly from MusicProvider
      await controller.setLooping(true); // Seamless loop like Spotify Canvas!

      if (mounted && _loadedSongId == song.id) {
        _canvasController = controller;
        _cachedController = controller;
        _cachedSongId = song.id;
        _isLoadingCanvas = false;

        // If the 10s auto-reveal fired before the clip finished downloading,
        // or if canvas was previously active for this song, honor it.
        final shouldShow = (_autoShowPending || _persistedShowCanvas) && !_userDisabledCanvas;
        if (shouldShow) {
          _autoShowPending = false;
          _persistedShowCanvas = true;
          setState(() {
            _animateCanvasTransition = true;
            _showCanvas = true;
          });
          if (provider.audioPlayer.playing) {
            controller.play();
          }
        } else if (_showCanvas) {
          setState(() {});
          if (provider.audioPlayer.playing) {
            controller.play();
          }
        }
      } else {
        await controller.dispose();
      }
    } catch (e) {
      debugPrint("Canvas load error: $e");
      if (mounted) {
        setState(() {
          _isLoadingCanvas = false;
          _loadedSongId = null;
        });
      }
    }
  }

  void _toggleCanvas(Song song, MusicProvider provider) {
    final nextState = !_showCanvas;
    setState(() {
      _animateCanvasTransition = true;
      _showCanvas = nextState;
      _userDisabledCanvas = !nextState;
      _autoShowPending = false;
    });

    _persistedShowCanvas = nextState;
    _persistedUserDisabled = !nextState;

    if (nextState) {
      final controller = _canvasController;
      if (controller == null || _loadedSongId != song.id) {
        _loadCanvasForSong(song, provider);
      } else if (provider.audioPlayer.playing) {
        controller.play();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('1080p Video Canvas Enabled 🎬'),
          backgroundColor: Color(0xFF282828),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final controller = _canvasController;
      if (controller != null) {
        controller.pause();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video Canvas Disabled'),
          backgroundColor: Color(0xFF282828),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    final playerStateSub = _playerStateSub;
    if (playerStateSub != null) {
      playerStateSub.cancel();
    }
    final positionSub = _positionSub;
    if (positionSub != null) {
      positionSub.cancel();
    }
    // Pause video to conserve battery/GPU when leaving player screen,
    // but keep cached so returning to this song instantly resumes canvas mode!
    final canvasController = _canvasController;
    if (canvasController != null && canvasController.value.isInitialized) {
      canvasController.pause();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;

    if (song == null) {
      return const Scaffold(body: Center(child: Text("No song playing")));
    }

    // Silently preload the canvas clip in the background whenever the song
    // changes. When the song actually changes, clear the prior song's canvas cache.
    if (_loadedSongId != song.id && !_isLoadingCanvas) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_cachedSongId != song.id) {
          final old = _cachedController;
          if (old != null) {
            _cachedController = null;
            old.dispose();
          }
          _cachedSongId = null;
          _persistedShowCanvas = false;
          _persistedUserDisabled = false;
        }
        setState(() {
          _canvasController = null;
          _showCanvas = false;
          _userDisabledCanvas = false;
          _autoShowPending = false;
        });
        _loadCanvasForSong(song, provider);
      });
    }

    final canvasController = _canvasController;
    final isCanvasReady = _showCanvas && canvasController != null && canvasController.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Layer 1A: Blurred Album Art (Base Background with Smooth Opacity Crossfade) ──
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: isCanvasReady ? 0.0 : 1.0,
              duration: _animateCanvasTransition
                  ? const Duration(milliseconds: 700)
                  : Duration.zero,
              curve: Curves.easeInOut,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AlbumArt(
                      song: song,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.zero,
                      iconSize: 100,
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.black.withValues(alpha: 0.2),
                              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                            stops: const [0.0, 0.3, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Layer 1B: Full-Bleed 1080p Video Canvas with Pure Opacity Crossfade ──
          if (canvasController != null && canvasController.value.isInitialized)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: isCanvasReady ? 1.0 : 0.0,
                duration: _animateCanvasTransition
                    ? const Duration(milliseconds: 700)
                    : Duration.zero,
                curve: Curves.easeInOut,
                child: Stack(
                  children: [
                    // Full-bleed vertical video canvas (BoxFit.cover like Spotify Canvas)
                    Positioned.fill(
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: canvasController.value.size.width > 0 ? canvasController.value.size.width : 16,
                            height: canvasController.value.size.height > 0 ? canvasController.value.size.height : 9,
                            child: VideoPlayer(canvasController),
                          ),
                        ),
                      ),
                    ),

                    // Cinematic dark gradient overlay for crystal-clear readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.60),
                              Colors.black.withValues(alpha: 0.94),
                            ],
                            stops: const [0.0, 0.25, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Layer 2: Player Controls & Content ──
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              _buildAppBar(context, song, provider),
                              const SizedBox(height: 12),

                              // Big Center Album Art: pure opacity transition (lowers opacity as canvas comes in)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: AnimatedOpacity(
                                    opacity: isCanvasReady ? 0.0 : 1.0,
                                    duration: _animateCanvasTransition
                                        ? const Duration(milliseconds: 700)
                                        : Duration.zero,
                                    curve: Curves.easeInOut,
                                    child: IgnorePointer(
                                      ignoring: isCanvasReady,
                                      child: _buildCenterAlbumArt(song, isCanvasReady),
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              _buildSongInfo(context, song, provider),
                              _buildProgressBar(context, provider.audioPlayer),
                              _buildControls(context, provider),
                              const SizedBox(height: 8),
                              _buildExtraActions(context, provider, song),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildCenterAlbumArt(Song song, bool isCanvasReady) {
    final art = AlbumArt(
      song: song,
      width: double.infinity,
      height: double.infinity,
      borderRadius: BorderRadius.circular(16),
      iconSize: 80,
    );

    // Omit Hero flight when Canvas mode is active or ready, so normal mode album art
    // does not fly onto the screen during route transitions (reopening/minimizing).
    if (isCanvasReady || _showCanvas || _persistedShowCanvas) {
      return art;
    }

    return Hero(
      tag: 'album_art_${song.id}',
      child: art,
    );
  }

  Widget _buildAppBar(BuildContext context, Song song, MusicProvider provider) {
    final titleMediumStyle = Theme.of(context).textTheme.titleMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 36),
            onPressed: () => Navigator.pop(context),
          ),

          // Header Text
          AnimatedDefaultTextStyle(
            duration: _animateCanvasTransition
                ? const Duration(milliseconds: 350)
                : Duration.zero,
            curve: Curves.easeInOut,
            style: titleMediumStyle != null
                ? titleMediumStyle.copyWith(
                    fontSize: 14,
                    color: _showCanvas ? AppTheme.accentColor1 : null,
                  )
                : TextStyle(
                    fontSize: 14,
                    color: _showCanvas ? AppTheme.accentColor1 : Colors.white,
                  ),
            child: Text(
              _showCanvas ? 'Canvas Mode' : 'Now Playing',
            ),
          ),

          // Canvas Quick Toggle Pill in Top Bar with Smooth Color Transition
          GestureDetector(
            onTap: () => _toggleCanvas(song, provider),
            child: AnimatedContainer(
              duration: _animateCanvasTransition
                  ? const Duration(milliseconds: 350)
                  : Duration.zero,
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _showCanvas
                    ? AppTheme.accentColor1.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _showCanvas ? AppTheme.accentColor1 : Colors.white24,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.film,
                    size: 14,
                    color: _showCanvas ? AppTheme.accentColor1 : Colors.white70,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Canvas',
                    style: TextStyle(
                      color: _showCanvas ? AppTheme.accentColor1 : Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
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

  Widget _buildSongInfo(
    BuildContext context,
    Song song,
    MusicProvider provider,
  ) {
    final isFav = provider.isFavorite(song);
    final headlineStyle = Theme.of(context).textTheme.headlineMedium;
    final bodyLargeStyle = Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title
                      .replaceAll('&quot;', '"')
                      .replaceAll('&#039;', "'")
                      .replaceAll('&amp;', '&')
                      .replaceAll('&lt;', '<')
                      .replaceAll('&gt;', '>'),
                  style: headlineStyle != null
                      ? headlineStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        )
                      : const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  style: bodyLargeStyle != null
                      ? bodyLargeStyle.copyWith(
                          color: const Color(0xFFB3B3B3),
                          fontSize: 15,
                        )
                      : const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 15,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Favorite Heart Button
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                key: ValueKey<bool>(isFav),
                color: isFav ? AppTheme.accentColor1 : Theme.of(context).iconTheme.color,
                size: 28,
              ),
            ),
            onPressed: () {
              provider.toggleFavorite(song);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFav ? 'Removed from Favorites' : 'Added to Favorites',
                    style: const TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFF282828),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, AudioPlayer player) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data != null ? snapshot.data! : Duration.zero;
        final duration = player.duration != null ? player.duration! : Duration.zero;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: AppTheme.accentColor1,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: duration.inMilliseconds > 0
                      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0,
                  onChanged: (value) {
                    if (duration.inMilliseconds > 0) {
                      final target = Duration(milliseconds: (value * duration.inMilliseconds).round());
                      player.seek(target);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position), style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                    Text(_formatDuration(duration), style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildControls(BuildContext context, MusicProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: provider.isShuffleEnabled ? AppTheme.accentColor1 : Theme.of(context).iconTheme.color,
            size: 28,
          ),
          onPressed: provider.toggleShuffle,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, color: Theme.of(context).iconTheme.color, size: 38),
          onPressed: provider.playPrevious,
        ),
        const SizedBox(width: 16),
        StreamBuilder<PlayerState>(
          stream: provider.audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            ProcessingState? processingState;
            bool? playing;
            if (playerState != null) {
              processingState = playerState.processingState;
              playing = playerState.playing;
            }

            Widget centerButton;
            if (provider.isResolvingAudio ||
                processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              centerButton = const CircularProgressIndicator(color: AppTheme.accentColor1);
            } else if (playing != true) {
              centerButton = _buildPlayButton(Icons.play_arrow_rounded, provider.audioPlayer.play);
            } else if (processingState != ProcessingState.completed) {
              centerButton = _buildPlayButton(Icons.pause_rounded, provider.audioPlayer.pause);
            } else {
              centerButton = _buildPlayButton(Icons.replay_rounded, () => provider.audioPlayer.seek(Duration.zero));
            }

            return SizedBox(
              width: 72,
              height: 72,
              child: Center(child: centerButton),
            );
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.skip_next_rounded, color: Theme.of(context).iconTheme.color, size: 38),
          onPressed: provider.playNext,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            provider.repeatMode == PlaybackRepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            color: provider.repeatMode != PlaybackRepeatMode.off ? AppTheme.accentColor1 : Theme.of(context).iconTheme.color,
            size: 28,
          ),
          onPressed: provider.toggleRepeat,
        ),
      ],
    );
  }

  /// Extra action buttons row: Lyrics, Queue, Video, Sleep Timer, Car Mode
  Widget _buildExtraActions(BuildContext context, MusicProvider provider, Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Lyrics
          _buildActionButton(
            context,
            icon: Icons.lyrics_rounded,
            label: 'Lyrics',
            onTap: () => LyricsSheet.show(context, song),
          ),
          // Queue
          _buildActionButton(
            context,
            icon: Icons.queue_music_rounded,
            label: 'Queue',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QueueScreen()),
              );
            },
          ),
          // Watch Full Video Screen
          _buildActionButton(
            context,
            icon: Icons.smart_display_rounded,
            label: 'Watch',
            onTap: () => _watchVideo(context, provider, song),
          ),
          // Sleep Timer
          _buildActionButton(
            context,
            icon: provider.isSleepTimerActive ? CupertinoIcons.timer_fill : CupertinoIcons.timer,
            label: provider.isSleepTimerActive && provider.sleepTimerRemaining != null
                ? '${provider.sleepTimerRemaining!.inMinutes}m'
                : 'Timer',
            isActive: provider.isSleepTimerActive,
            onTap: () => _showSleepTimerSheet(context, provider),
          ),
          // Car Mode
          _buildActionButton(
            context,
            icon: CupertinoIcons.car_detailed,
            label: 'Car',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CarModeScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final themeColor = Theme.of(context).iconTheme.color;
    final fallbackColor = themeColor != null ? themeColor.withValues(alpha: 0.54) : Colors.white54;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppTheme.accentColor1 : fallbackColor, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppTheme.accentColor1 : fallbackColor,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, MusicProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bodyColor = Theme.of(context).textTheme.bodyLarge;
        final textColor = bodyColor != null ? bodyColor.color : Colors.white;
        final iconThemeColor = Theme.of(context).iconTheme.color;
        final subtextColor = iconThemeColor != null ? iconThemeColor.withValues(alpha: 0.54) : Colors.white54;

        String timerStatusText = 'Stop music after a set time';
        final remaining = provider.sleepTimerRemaining;
        if (provider.isSleepTimerActive && remaining != null) {
          timerStatusText = 'Music will stop in ${remaining.inMinutes} min ${remaining.inSeconds % 60} sec';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sleep Timer',
                style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                timerStatusText,
                style: TextStyle(color: subtextColor, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Timer options
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _timerOption(ctx, provider, '15 min', const Duration(minutes: 15)),
                  _timerOption(ctx, provider, '30 min', const Duration(minutes: 30)),
                  _timerOption(ctx, provider, '45 min', const Duration(minutes: 45)),
                  _timerOption(ctx, provider, '1 hour', const Duration(hours: 1)),
                  _timerOption(ctx, provider, '1.5 hours', const Duration(minutes: 90)),
                  _timerOption(ctx, provider, '2 hours', const Duration(hours: 2)),
                ],
              ),

              if (provider.isSleepTimerActive) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    provider.cancelSleepTimer();
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                  label: const Text('Cancel Timer', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _timerOption(BuildContext ctx, MusicProvider provider, String label, Duration duration) {
    final bodyLarge = Theme.of(ctx).textTheme.bodyLarge;
    final textColor = bodyLarge != null ? bodyLarge.color : Colors.white;

    return GestureDetector(
      onTap: () {
        provider.setSleepTimer(duration);
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Sleep timer set for $label 🌙'),
            backgroundColor: const Color(0xFF282828),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(ctx).dividerColor.withValues(alpha: 0.12)),
        ),
        child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildPlayButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.accentColor1,
      ),
      child: IconButton(
        icon: Icon(icon, size: 36, color: Colors.black),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _watchVideo(
    BuildContext context,
    MusicProvider provider,
    Song song,
  ) async {
    final bool wasPlaying = provider.audioPlayer.playing;

    // Pause canvas if active
    final canvas = _canvasController;
    if (canvas != null && canvas.value.isPlaying) {
      canvas.pause();
    }

    // 1. Pause audio playback before opening the video
    if (wasPlaying) {
      await provider.audioPlayer.pause();
    }

    // 2. Show a loading dialog while finding the video
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.accentColor1),
                SizedBox(height: 16),
                Text(
                  'Finding video...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Search and extract YouTube stream URL
    final videoService = YoutubeVideoService();
    final videoResult = await videoService.getVideoStream(song);

    // Dismiss the loading dialog
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // 4. If no video is found or an error occurred
    if (videoResult == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No video found for this song'),
            backgroundColor: Color(0xFF282828),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // Resume audio if it was playing before
      if (wasPlaying) {
        provider.audioPlayer.play();
      }
      if (_showCanvas && canvas != null) {
        canvas.play();
      }
      return;
    }

    // 5. Open VideoPlayerScreen and wait until user closes it
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => VideoPlayerScreen(
            videoResult: videoResult,
            song: song,
          ),
        ),
      );

      // 6. When the video screen is closed, resume audio from the same position!
      if (wasPlaying) {
        provider.audioPlayer.play();
      }
      if (_showCanvas && canvas != null && wasPlaying) {
        canvas.play();
      }
    }
  }
}
