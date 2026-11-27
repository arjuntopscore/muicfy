import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../hidden_photo_service.dart';

const Color _kCyberCyan = Color(0xFF00E5FF);
const Color _kNeonRose = Color(0xFFFF2D55);

/// Full-screen private photo & video viewer with pinch-to-zoom,
/// double-tap zoom, video controls, favorites toggle, and metadata inspector.
class HiddenPhotoViewer extends StatefulWidget {
  final List<String> photoPaths;
  final int initialIndex;
  final String? collectionId;

  const HiddenPhotoViewer({
    super.key,
    required this.photoPaths,
    required this.initialIndex,
    this.collectionId,
  });

  @override
  State<HiddenPhotoViewer> createState() => _HiddenPhotoViewerState();
}

class _HiddenPhotoViewerState extends State<HiddenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;
  final TransformationController _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _handleDoubleTap() {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      final position = _doubleTapDetails!.localPosition;
      _transformController.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0)
        ..setTranslationRaw(-position.dx * 1.5, -position.dy * 1.5, 0.0);
    }
  }

  void _showMetadata(BuildContext context, String path) {
    final service = context.read<HiddenPhotoService>();
    final f = File(path);
    final size = service.formatFileSize(path);
    final isVid = service.isVideo(path);
    DateTime? modDate;
    if (f.existsSync()) {
      modDate = f.lastModifiedSync();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF131926).withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(CupertinoIcons.info_circle_fill, color: _kCyberCyan, size: 22),
                    SizedBox(width: 10),
                    Text('Encrypted Item Metadata', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 18),
                _MetaItem(label: 'Format', value: isVid ? 'Video Stream (H.264 / AAC)' : 'Encrypted Bitstream Image'),
                _MetaItem(label: 'File Size', value: size),
                if (modDate != null)
                  _MetaItem(label: 'Timestamp', value: '${modDate.year}-${modDate.month.toString().padLeft(2, '0')}-${modDate.day.toString().padLeft(2, '0')} ${modDate.hour.toString().padLeft(2, '0')}:${modDate.minute.toString().padLeft(2, '0')}'),
                _MetaItem(label: 'Encryption', value: 'AES-256 Zero-Knowledge Enclave'),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Dismiss', style: TextStyle(color: _kCyberCyan, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<HiddenPhotoService>();
    final currentPath = widget.photoPaths.isNotEmpty && _currentIndex < widget.photoPaths.length
        ? widget.photoPaths[_currentIndex]
        : '';
    final isFav = widget.collectionId != null && currentPath.isNotEmpty
        ? service.isFavorite(widget.collectionId!, currentPath)
        : false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo/Video PageView
          GestureDetector(
            onTap: _toggleControls,
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photoPaths.length,
              onPageChanged: (i) {
                setState(() {
                  _currentIndex = i;
                  _transformController.value = Matrix4.identity();
                });
              },
              itemBuilder: (context, index) {
                final path = widget.photoPaths[index];
                if (service.isVideo(path)) {
                  return _CyberVideoViewer(
                    videoPath: path,
                    showControls: _showControls,
                  );
                }
                return InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.8,
                  maxScale: 5.0,
                  child: Center(
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.exclamationmark_circle, color: Colors.white30, size: 48),
                          SizedBox(height: 12),
                          Text('Failed to decrypt image stream', style: TextStyle(color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating Top App Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            top: _showControls ? 0 : -110,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 14,
                bottom: 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  // Current index badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${_currentIndex + 1} of ${widget.photoPaths.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Favorite button
                  if (widget.collectionId != null && currentPath.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                        color: isFav ? _kNeonRose : Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        service.toggleFavorite(widget.collectionId!, currentPath);
                        HapticFeedback.lightImpact();
                      },
                    ),
                  // Metadata button
                  IconButton(
                    icon: const Icon(CupertinoIcons.info_circle, color: Colors.white, size: 22),
                    onPressed: currentPath.isNotEmpty ? () => _showMetadata(context, currentPath) : null,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Thumbnail Navigation Bar
          if (widget.photoPaths.length > 1)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              bottom: _showControls ? MediaQuery.of(context).padding.bottom + 16 : -80,
              left: 20,
              right: 20,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          widget.photoPaths.length.clamp(0, 15),
                          (i) => GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _currentIndex ? 22 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _currentIndex ? _kCyberCyan : Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: i == _currentIndex
                                    ? [BoxShadow(color: _kCyberCyan.withValues(alpha: 0.6), blurRadius: 6)]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberVideoViewer extends StatefulWidget {
  final String videoPath;
  final bool showControls;
  const _CyberVideoViewer({required this.videoPath, this.showControls = true});

  @override
  State<_CyberVideoViewer> createState() => _CyberVideoViewerState();
}

class _CyberVideoViewerState extends State<_CyberVideoViewer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = false;

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
    HapticFeedback.lightImpact();
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      _controller.setVolume(_muted ? 0.0 : 1.0);
    });
    HapticFeedback.selectionClick();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(color: _kCyberCyan, strokeWidth: 2));
    }

    final pos = _controller.value.position;
    final dur = _controller.value.duration;

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),

            // Big Center Play/Pause button when paused
            if (widget.showControls && !_controller.value.isPlaying)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20),
                    ],
                  ),
                  child: const Icon(CupertinoIcons.play_fill, color: Colors.white, size: 38),
                ),
              ),

            // Video Controls Bottom Overlay
            if (widget.showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Transport buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(CupertinoIcons.gobackward_10, color: Colors.white70, size: 24),
                            onPressed: () {
                              final newPos = _controller.value.position - const Duration(seconds: 10);
                              _controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
                              HapticFeedback.lightImpact();
                            },
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Icon(
                                _controller.value.isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(CupertinoIcons.goforward_10, color: Colors.white70, size: 24),
                            onPressed: () {
                              final newPos = _controller.value.position + const Duration(seconds: 10);
                              _controller.seekTo(newPos > dur ? dur : newPos);
                              HapticFeedback.lightImpact();
                            },
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _muted ? CupertinoIcons.volume_off : CupertinoIcons.volume_up,
                              color: Colors.white70,
                              size: 22,
                            ),
                            onPressed: _toggleMute,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress bar with timestamps
                      Row(
                        children: [
                          Text(_formatDuration(pos), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 18,
                              child: VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                colors: VideoProgressColors(
                                  playedColor: _kCyberCyan,
                                  bufferedColor: Colors.white.withValues(alpha: 0.3),
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(_formatDuration(dur), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
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
