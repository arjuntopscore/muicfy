import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;

    if (song == null) {
      return const Scaffold(body: Center(child: Text("No song playing")));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
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
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.2),
                      AppTheme.bgColor.withOpacity(0.8),
                      AppTheme.bgColor,
                    ],
                    stops: const [0.0, 0.3, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildAppBar(context),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Hero(
                              tag: 'album_art_${song.id}',
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: AlbumArt(
                                  song: song,
                                  width: double.infinity,
                                  height: double.infinity,
                                  borderRadius: BorderRadius.circular(12),
                                  iconSize: 80,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          _buildSongInfo(context, song),
                          _buildProgressBar(provider.audioPlayer),
                          _buildControls(provider),
                          const SizedBox(height: 30),
                        ],
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

  Widget _buildAppBar(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          Text('Now Playing', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
          IconButton(
            icon: Icon(
              song != null && song.isLocal ? Icons.offline_pin : Icons.download,
              color: song != null && song.isLocal ? AppTheme.accentColor1 : Colors.white,
            ),
            onPressed: song != null && !song.isLocal ? () => provider.downloadSong(song, context) : null,
          ),
        ],
      ),
    );
  }



  Widget _buildSongInfo(BuildContext context, Song song) {
    final provider = context.watch<MusicProvider>();
    final isFav = provider.isFavorite(song);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFB3B3B3),
                        fontSize: 16,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                key: ValueKey<bool>(isFav),
                color: isFav ? AppTheme.accentColor1 : Colors.white,
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
          )
        ],
      ),
    );
  }

  Widget _buildProgressBar(AudioPlayer player) {
    return StreamBuilder<Duration?>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.duration ?? Duration.zero;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: duration.inMilliseconds > 0 
                    ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0,
                  onChanged: (value) {
                    if (duration.inMilliseconds > 0) {
                      player.seek(Duration(milliseconds: (value * duration.inMilliseconds).round()));
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

  Widget _buildControls(MusicProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle, 
            color: provider.isShuffleEnabled ? AppTheme.accentColor1 : Colors.white, 
            size: 28
          ),
          onPressed: provider.toggleShuffle,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
          onPressed: provider.playPrevious,
        ),
        const SizedBox(width: 16),
        StreamBuilder<PlayerState>(
          stream: provider.audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final provider = context.watch<MusicProvider>();
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            
            Widget centerButton;
            if (provider.isResolvingAudio || 
                processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              centerButton = const CircularProgressIndicator(color: AppTheme.accentColor1);
            } else if (playing != true) {
              centerButton = _buildPlayButton(Icons.play_arrow, provider.audioPlayer.play);
            } else if (processingState != ProcessingState.completed) {
              centerButton = _buildPlayButton(Icons.pause, provider.audioPlayer.pause);
            } else {
              centerButton = _buildPlayButton(Icons.replay, () => provider.audioPlayer.seek(Duration.zero));
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
          icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
          onPressed: provider.playNext,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            provider.repeatMode == PlaybackRepeatMode.one ? Icons.repeat_one : Icons.repeat, 
            color: provider.repeatMode != PlaybackRepeatMode.off ? AppTheme.accentColor1 : Colors.white, 
            size: 28
          ),
          onPressed: provider.toggleRepeat,
        ),
      ],
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
}
