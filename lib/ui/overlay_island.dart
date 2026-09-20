import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayIslandApp extends StatelessWidget {
  const OverlayIslandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayIslandWidget(),
    );
  }
}

class OverlayIslandWidget extends StatefulWidget {
  const OverlayIslandWidget({super.key});

  @override
  State<OverlayIslandWidget> createState() => _OverlayIslandWidgetState();
}

class _OverlayIslandWidgetState extends State<OverlayIslandWidget> with SingleTickerProviderStateMixin {
  String _title = "NexTune Music";
  String _imageUrl = "";
  bool _isPlaying = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event != null && event is String) {
        try {
          final data = jsonDecode(event);
          if (mounted) {
            setState(() {
              if (data['title'] != null) _title = data['title'];
              if (data['imageUrl'] != null) _imageUrl = data['imageUrl'];
              if (data['isPlaying'] != null) _isPlaying = data['isPlaying'];
            });
          }
        } catch (e) {
          debugPrint("Overlay parsing error: $e");
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () {
            FlutterOverlayWindow.shareData('open_app');
          },
          child: Container(
            height: 46,
            width: 250, // Fixed width for the island overlay
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(right: 6, left: 4),
            decoration: BoxDecoration(
              color: Colors.black, // True black for the island
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular album art mimicking the dynamic island's left icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: _imageUrl.isNotEmpty && _imageUrl.startsWith('http')
                        ? DecorationImage(
                            image: NetworkImage(_imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[800],
                  ),
                  child: _imageUrl.isEmpty || !_imageUrl.startsWith('http')
                      ? Icon(Icons.music_note, color: Colors.white54, size: 20)
                      : null,
                ),
                SizedBox(width: 10),
                // Song Title
                Expanded(
                  child: Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Right side - Animated bars or play/pause
                _isPlaying 
                    ? AnimatedBuilder(
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
                      )
                    : GestureDetector(
                        onTap: () {
                           FlutterOverlayWindow.shareData('toggle_play');
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

