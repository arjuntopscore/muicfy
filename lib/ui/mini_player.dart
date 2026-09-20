import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import 'player_screen.dart';
import 'album_art.dart';

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
      duration: const Duration(milliseconds: 1500),
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
    final song = provider.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const curve = Curves.easeInOutCubicEmphasized;
              var curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
              
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
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFF282828), // Surface color
          border: Border(
            bottom: BorderSide(color: Colors.black, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Hero(
                tag: 'album_art_${song.id}',
                child: AlbumArt(
                  song: song,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            // Play/Pause button and Animation
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
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  );
                } else if (playing == true) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The animation
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 3,
                                height: 8 + (8 * _pulseController.value),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1DB954),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(width: 3),
                              Container(
                                width: 3,
                                height: 16 - (8 * _pulseController.value),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1DB954),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(width: 3),
                              Container(
                                width: 3,
                                height: 10 + (4 * _pulseController.value),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1DB954),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(width: 12),
                      IconButton(
                        icon: Icon(Icons.pause_rounded, color: Theme.of(context).textTheme.bodyLarge?.color, size: 30),
                        onPressed: () => provider.audioPlayer.pause(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  );
                } else {
                  return IconButton(
                    icon: Icon(Icons.play_arrow_rounded, color: Theme.of(context).textTheme.bodyLarge?.color, size: 30),
                    onPressed: () => provider.audioPlayer.play(),
                    padding: EdgeInsets.zero,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}




