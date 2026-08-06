import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import 'player_screen.dart';
import 'theme.dart';
import 'album_art.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final song = provider.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutQuart;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        );
      },
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Hero(
                  tag: 'album_art_${song.id}',
                  child: AlbumArt(
                    song: song,
                    width: 56,
                    height: 56,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Favorite button in mini player
                IconButton(
                  icon: Icon(
                    provider.isFavorite(song) ? Icons.favorite : Icons.favorite_border,
                    color: provider.isFavorite(song) ? AppTheme.accentColor1 : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => provider.toggleFavorite(song),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                StreamBuilder<PlayerState>(
                  stream: provider.audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;
                    Widget centerButton;
                    if (provider.isResolvingAudio || 
                        processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering) {
                      centerButton = const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor1),
                      );
                    } else if (playing != true) {
                      centerButton = IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: provider.audioPlayer.play,
                      );
                    } else if (processingState != ProcessingState.completed) {
                      centerButton = IconButton(
                        icon: const Icon(Icons.pause, color: Colors.white),
                        onPressed: provider.audioPlayer.pause,
                      );
                    } else {
                      centerButton = IconButton(
                        icon: const Icon(Icons.replay, color: Colors.white),
                        onPressed: () => provider.audioPlayer.seek(Duration.zero),
                      );
                    }

                    return SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(child: centerButton),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            Positioned(
              top: 0, left: 0, right: 0,
              child: StreamBuilder<Duration>(
                stream: provider.audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = provider.audioPlayer.duration ?? const Duration(milliseconds: 1);
                  final progress = total.inMilliseconds > 0 ? (position.inMilliseconds / total.inMilliseconds) : 0.0;
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.transparent,
                      color: AppTheme.accentColor1,
                      minHeight: 2,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
