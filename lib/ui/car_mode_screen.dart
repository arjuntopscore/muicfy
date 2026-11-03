import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import 'theme.dart';
import 'album_art.dart';

class CarModeScreen extends StatefulWidget {
  CarModeScreen({super.key});

  @override
  State<CarModeScreen> createState() => _CarModeScreenState();
}

class _CarModeScreenState extends State<CarModeScreen> {
  @override
  void initState() {
    super.initState();
    // Force landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Restore system UI
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
      backgroundColor: Color(0xFF000000), // Pure black for AMOLED
      body: SafeArea(
        child: Stack(
          children: [
            if (song != null)
              Row(
                children: [
                  // Left: Album Art
                  Padding(
                    padding: const EdgeInsets.only(left: 32.0, top: 16.0, bottom: 16.0, right: 24.0),
                    child: AlbumArt(
                      song: song,
                      width: 200,
                      height: 200,
                      borderRadius: BorderRadius.circular(20),
                      iconSize: 80,
                    ),
                  ),
                  
                  // Center: Title, Artist, Progress
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Text(
                            song.artist,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacer(),
                          // Progress Bar
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
                                      trackHeight: 12, // Extra large for car mode
                                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                                      overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
                                      activeTrackColor: AppTheme.accentColor1,
                                      inactiveTrackColor: Theme.of(context).cardColor,
                                      thumbColor: AppTheme.accentColor1,
                                    ),
                                    child: Slider(
                                      value: progress,
                                      onChanged: (value) {
                                        final newPosition = Duration(
                                            milliseconds: (value * duration.inMilliseconds).round());
                                        provider.audioPlayer.seek(newPosition);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_formatDuration(position),
                                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.54), fontSize: 16)),
                                        Text(_formatDuration(duration),
                                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.54), fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right: Controls
                  Container(
                    width: 160, // Wide enough for big buttons
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.skip_previous, color: Theme.of(context).textTheme.bodyLarge?.color),
                            iconSize: 48,
                            constraints: BoxConstraints(minWidth: 72, minHeight: 72),
                            onPressed: () => provider.playPrevious(),
                          ),
                          SizedBox(height: 8),
                          StreamBuilder<PlayerState>(
                            stream: provider.audioPlayer.playerStateStream,
                            builder: (context, snapshot) {
                              final playerState = snapshot.data;
                              final processingState = playerState?.processingState;
                              final playing = playerState?.playing;
                              
                              bool isLoading = processingState == ProcessingState.loading ||
                                               processingState == ProcessingState.buffering ||
                                               provider.isResolvingAudio;
                              
                              if (isLoading) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor1,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: CircularProgressIndicator(color: Colors.black),
                                  ),
                                );
                              } else if (playing == true) {
                                return InkWell(
                                  onTap: () => provider.audioPlayer.pause(),
                                  customBorder: CircleBorder(),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor1,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.pause, size: 64, color: Colors.black),
                                  ),
                                );
                              } else {
                                return InkWell(
                                  onTap: () => provider.audioPlayer.play(),
                                  customBorder: CircleBorder(),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor1,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.play_arrow, size: 64, color: Colors.black),
                                  ),
                                );
                              }
                            }
                          ),
                          SizedBox(height: 8),
                          IconButton(
                            icon: Icon(Icons.skip_next, color: Theme.of(context).textTheme.bodyLarge?.color),
                            iconSize: 48,
                            constraints: BoxConstraints(minWidth: 72, minHeight: 72),
                            onPressed: () => provider.playNext(),
                          ),
                          SizedBox(height: 8),
                          IconButton(
                            icon: Icon(
                              provider.isFavorite(song) ? Icons.favorite : Icons.favorite_border,
                              color: provider.isFavorite(song) ? AppTheme.accentColor1 : Colors.white,
                            ),
                            iconSize: 48,
                            constraints: BoxConstraints(minWidth: 72, minHeight: 72),
                            onPressed: () => provider.toggleFavorite(song),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            if (song == null)
              Center(
                child: Text(
                  "No song playing",
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 24)
                ),
              ),
              
            // Close Button (Top-Right)
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge?.color, size: 40),
                constraints: BoxConstraints(minWidth: 72, minHeight: 72), // extra large touch target
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






