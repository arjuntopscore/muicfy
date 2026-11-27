import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../hidden_photo_service.dart';
import 'hidden_gallery_screen.dart';

const Color _kCyberCyan = Color(0xFF00E5FF);
const Color _kNeonRose = Color(0xFFFF2D55);
const Color _kSecureGreen = Color(0xFF10B981);

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
  static const Duration _duration = Duration(milliseconds: 3200);

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
    _overlay = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
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
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => HiddenGalleryScreen(collectionId: widget.collectionId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

            // Top skip button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: GestureDetector(
                onTap: _goToGallery,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 10),
                    ],
                  ),
                ),
              ),
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
        final scale = 1.05 + 0.15 * t;
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
        errorBuilder: (context, error, stackTrace) => _buildFallbackLayer(),
      ),
    );
  }

  Widget _buildVideoLayer() {
    return AnimatedBuilder(
      animation: _kenBurns,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_kenBurns.value);
        final scale = 1.05 + 0.12 * t;
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
          colors: [Color(0xFF0F2038), Color(0xFF16102C), Color(0xFF090D16)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        CupertinoIcons.lock_shield_fill,
        color: _kCyberCyan.withValues(alpha: 0.25),
        size: 110,
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
              Colors.black.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.95),
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            // Glowing Lock Icon
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kCyberCyan, _kNeonRose],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kCyberCyan.withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(CupertinoIcons.lock_shield_fill, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 20),

            // Decryption handshake tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kSecureGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kSecureGreen.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, color: _kSecureGreen, size: 12),
                  SizedBox(width: 6),
                  Text(
                    'AES-256 ENCRYPTED PARTITION',
                    style: TextStyle(
                      color: _kSecureGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Collection Title
            Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _progress,
              builder: (context, _) {
                final val = _progress.value;
                String status = 'Authenticating cryptographic key...';
                if (val > 0.35) status = 'Decrypting media container...';
                if (val > 0.75) status = 'Mounting private secure enclave...';

                return Text(
                  status,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Smooth Decryption Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => LinearProgressIndicator(
                  value: _progress.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(_kCyberCyan),
                  minHeight: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Tap anywhere to open enclave instantly',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
