import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../hidden_photo_service.dart';
import 'package:provider/provider.dart';

/// Full-screen photo viewer with swipe between photos.
class HiddenPhotoViewer extends StatefulWidget {
  final List<String> photoPaths;
  final int initialIndex;

  const HiddenPhotoViewer({
    super.key,
    required this.photoPaths,
    required this.initialIndex,
  });

  @override
  State<HiddenPhotoViewer> createState() => _HiddenPhotoViewerState();
}

class _HiddenPhotoViewerState extends State<HiddenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<HiddenPhotoService>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo page view
          GestureDetector(
            onTap: _toggleControls,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photoPaths.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final path = widget.photoPaths[index];
                if (service.isVideo(path)) {
                  return _VideoViewer(
                    videoPath: path,
                    showControls: _showControls,
                  );
                }
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white24,
                        size: 60,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Top bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentIndex + 1} / ${widget.photoPaths.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom indicator dots
          if (widget.photoPaths.length > 1)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              bottom: _showControls ? MediaQuery.of(context).padding.bottom + 20 : -50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photoPaths.length.clamp(0, 20),
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentIndex ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? const Color(0xFFFF4081)
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoViewer extends StatefulWidget {
  final String videoPath;
  final bool showControls;
  const _VideoViewer({required this.videoPath, this.showControls = true});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(
      File(widget.videoPath),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
          _controller.setLooping(true);
          
          // Add listener to update UI when playing state changes (for pause/play icons)
          _controller.addListener(() {
            if (mounted) setState(() {});
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4081)));
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            
            // Only show central play icon if paused and controls are visible
            if (widget.showControls && !_controller.value.isPlaying)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                ),
              ),

            // Video Controls Bottom Bar
            if (widget.showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10, color: Colors.white),
                            onPressed: () {
                              final currentPosition = _controller.value.position;
                              final newPosition = currentPosition - const Duration(seconds: 10);
                              _controller.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                            },
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: Icon(
                              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.forward_10, color: Colors.white),
                            onPressed: () {
                              final currentPosition = _controller.value.position;
                              final duration = _controller.value.duration;
                              final newPosition = currentPosition + const Duration(seconds: 10);
                              _controller.seekTo(newPosition > duration ? duration : newPosition);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 20,
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFFFF4081),
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
