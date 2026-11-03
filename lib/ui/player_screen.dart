import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';
import 'queue_screen.dart';
import 'lyrics_sheet.dart';
import 'car_mode_screen.dart';

class PlayerScreen extends StatelessWidget {
  PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;

    if (song == null) {
      return Scaffold(body: Center(child: Text("No song playing")));
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
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.2),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    stops: [0.0, 0.3, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              _buildAppBar(context),
                              SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Hero(
                                    tag: 'album_art_${song.id}',
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
                              Spacer(),
                              _buildSongInfo(context, song),
                              _buildProgressBar(context, provider.audioPlayer),
                              _buildControls(context, provider),
                              SizedBox(height: 8),
                              _buildExtraActions(context, provider, song),
                              SizedBox(height: 20),
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

  Widget _buildAppBar(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 36),
            onPressed: () => Navigator.pop(context),
          ),
          Text('Now Playing', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
          IconButton(
            icon: Icon(
              song != null && song.isLocal ? Icons.offline_pin_rounded : CupertinoIcons.arrow_down_circle,
              color: song != null && song.isLocal ? AppTheme.accentColor1 : Theme.of(context).iconTheme.color,
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
                SizedBox(height: 4),
                Text(
                  song.artist,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Color(0xFFB3B3B3),
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
              duration: Duration(milliseconds: 250),
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
                    style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: Color(0xFF282828),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, AudioPlayer player) {
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
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                  
                  
                  
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
                    Text(_formatDuration(position), style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                    Text(_formatDuration(duration), style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
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
            size: 28
          ),
          onPressed: provider.toggleShuffle,
        ),
        SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, color: Theme.of(context).iconTheme.color, size: 38),
          onPressed: provider.playPrevious,
        ),
        SizedBox(width: 16),
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
              centerButton = CircularProgressIndicator(color: AppTheme.accentColor1);
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
        SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.skip_next_rounded, color: Theme.of(context).iconTheme.color, size: 38),
          onPressed: provider.playNext,
        ),
        SizedBox(width: 16),
        IconButton(
          icon: Icon(
            provider.repeatMode == PlaybackRepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded, 
            color: provider.repeatMode != PlaybackRepeatMode.off ? AppTheme.accentColor1 : Theme.of(context).iconTheme.color, 
            size: 28
          ),
          onPressed: provider.toggleRepeat,
        ),
      ],
    );
  }

  /// Extra action buttons row: Lyrics, Queue, Sleep Timer, Car Mode
  Widget _buildExtraActions(BuildContext context, MusicProvider provider, Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Lyrics
          _buildActionButton(context,
            icon: Icons.lyrics_rounded,
            label: 'Lyrics',
            onTap: () => LyricsSheet.show(context, song),
          ),
          // Queue
          _buildActionButton(context,
            icon: Icons.queue_music_rounded,
            label: 'Queue',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QueueScreen()),
              );
            },
          ),
          // Sleep Timer
          _buildActionButton(context,
            icon: provider.isSleepTimerActive ? CupertinoIcons.timer_fill : CupertinoIcons.timer,
            label: provider.isSleepTimerActive
                ? '${provider.sleepTimerRemaining!.inMinutes}m'
                : 'Timer',
            isActive: provider.isSleepTimerActive,
            onTap: () => _showSleepTimerSheet(context, provider),
          ),
          // Car Mode
          _buildActionButton(context,
            icon: CupertinoIcons.car_detailed,
            label: 'Car',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CarModeScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppTheme.accentColor1 : Theme.of(context).iconTheme.color?.withValues(alpha: 0.54), size: 22),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppTheme.accentColor1 : Theme.of(context).iconTheme.color?.withValues(alpha: 0.54),
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
      backgroundColor: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(height: 20),
              Text('Sleep Timer', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(
                provider.isSleepTimerActive
                    ? 'Music will stop in ${provider.sleepTimerRemaining!.inMinutes} min ${provider.sleepTimerRemaining!.inSeconds % 60} sec'
                    : 'Stop music after a set time',
                style: TextStyle(color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.54), fontSize: 13),
              ),
              SizedBox(height: 20),

              // Timer options
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _timerOption(ctx, provider, '15 min', Duration(minutes: 15)),
                  _timerOption(ctx, provider, '30 min', Duration(minutes: 30)),
                  _timerOption(ctx, provider, '45 min', Duration(minutes: 45)),
                  _timerOption(ctx, provider, '1 hour', Duration(hours: 1)),
                  _timerOption(ctx, provider, '1.5 hours', Duration(minutes: 90)),
                  _timerOption(ctx, provider, '2 hours', Duration(hours: 2)),
                ],
              ),

              if (provider.isSleepTimerActive) ...[
                SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    provider.cancelSleepTimer();
                    Navigator.pop(ctx);
                  },
                  icon: Icon(Icons.cancel, color: Colors.redAccent),
                  label: Text('Cancel Timer', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                ),
              ],
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _timerOption(BuildContext ctx, MusicProvider provider, String label, Duration duration) {
    return GestureDetector(
      onTap: () {
        provider.setSleepTimer(duration);
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Sleep timer set for $label 🌙'),
            backgroundColor: Color(0xFF282828),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFF282828),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(ctx).dividerColor.withValues(alpha: 0.12)),
        ),
        child: Text(label, style: TextStyle(color: Theme.of(ctx).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildPlayButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
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








