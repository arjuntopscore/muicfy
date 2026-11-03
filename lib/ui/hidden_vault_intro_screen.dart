import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../hidden_photo_service.dart';
import 'hidden_gallery_screen.dart';

const Color _kAccent = Color(0xFFFF4081);
const Color _kAccent2 = Color(0xFF7A1FA2);

class HiddenVaultIntroScreen extends StatefulWidget {
  final String collectionId;
  final String title;
  final String? coverPath;

  const HiddenVaultIntroScreen({
    super.key,
    required this.collectionId,
    required this.title,
    required this.coverPath,
  });

  @override
  State<HiddenVaultIntroScreen> createState() => _HiddenVaultIntroScreenState();
}

class _HiddenVaultIntroScreenState extends State<HiddenVaultIntroScreen>
    with TickerProviderStateMixin {
  static const Duration _duration = Duration(seconds: 5);

  late final AnimationController _kenBurns;
  late final AnimationController _overlay;
  late final AnimationController _progress;

  VideoPlayerController? _video;
  bool _isVideo = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _kenBurns = AnimationController(vsync: this, duration: _duration)..forward();
    _overlay = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
      ..forward();
    _progress = AnimationController(vsync: this, duration: _duration)..forward();

    _setupCover();

    Future.delayed(_duration, _goToGallery);
  }

  void _setupCover() {
    final path = widget.coverPath;
    if (path == null || !File(path).existsSync()) return;
    final service = context.read<HiddenPhotoService>();
    if (service.isVideo(path)) {
      _isVideo = true;
      _video = VideoPlayerController.file(
        File(path),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )..initialize().then((_) {
          if (!mounted) return;
          _video!
            ..setVolume(0)
            ..setLooping(true)
            ..play();
          setState(() {});
        });
    }
  }

  void _goToGallery() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => HiddenGalleryScreen(collectionId: widget.collectionId),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _kenBurns.dispose();
    _overlay.dispose();
    _progress.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.coverPath;
    final hasFile = path != null && File(path).existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _goToGallery,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasFile && _isVideo && _video != null && _video!.value.isInitialized)
              _buildVideoLayer()
            else if (hasFile && !_isVideo)
              _buildImageLayer(path)
            else
              _buildFallbackLayer(),

            _buildScrim(),

            FadeTransition(
              opacity: CurvedAnimation(parent: _overlay, curve: Curves.easeOut),
              child: _buildOverlay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLayer(String path) {
    return AnimatedBuilder(
      animation: _kenBurns,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_kenBurns.value);
        final scale = 1.05 + 0.18 * t;
        final dx = -8.0 * t;
        final dy = -6.0 * t;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackLayer(),
      ),
    );
  }

  Widget _buildVideoLayer() {
    return AnimatedBuilder(
      animation: _kenBurns,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_kenBurns.value);
        final scale = 1.05 + 0.15 * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _video!.value.size.width,
            height: _video!.value.size.height,
            child: VideoPlayer(_video!),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackLayer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A003F), _kAccent2, _kAccent],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.lock_rounded,
        color: Colors.white.withOpacity(0.3),
        size: 120,
      ),
    );
  }

  Widget _buildScrim() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.55),
              Colors.black.withOpacity(0.15),
              Colors.black.withOpacity(0.65),
              Colors.black.withOpacity(0.9),
            ],
            stops: const [0.0, 0.35, 0.75, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_kAccent, _kAccent2]),
                    boxShadow: [
                      BoxShadow(color: _kAccent.withOpacity(0.5), blurRadius: 16),
                    ],
                  ),
                  child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENTERING VAULT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _goToGallery,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Skip',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.9), size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kAccent.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 5),
                  Text(
                    'ENCRYPTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Unlocking...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: _progress,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    color: Colors.white.withOpacity(0.12),
                  ),
                  FractionallySizedBox(
                    widthFactor: _progress.value.clamp(0.0, 1.0),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kAccent, _kAccent2]),
                        boxShadow: [
                          BoxShadow(color: _kAccent.withOpacity(0.6), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
