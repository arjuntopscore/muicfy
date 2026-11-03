import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../hidden_photo_service.dart';
import 'hidden_vault_intro_screen.dart';

const Color _kAccent = Color(0xFFFF4081);
const Color _kAccent2 = Color(0xFF7A1FA2);
const Color _kBg = Color(0xFF070711);
const Color _kSurface = Color(0xFF14141F);
const Color _kSurfaceHigh = Color(0xFF1E1E2E);

class HiddenCollectionsScreen extends StatelessWidget {
  const HiddenCollectionsScreen({super.key});

  Future<void> _createCollection(BuildContext context) async {
    final titleController = TextEditingController();
    String? coverPath;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: _kSurface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [_kAccent, _kAccent2]),
                          ),
                          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Text('New Collection',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      cursorColor: _kAccent,
                      decoration: InputDecoration(
                        hintText: 'Collection name',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _kAccent.withOpacity(0.6), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (result != null && result.files.single.path != null) {
                          setState(() => coverPath = result.files.single.path);
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          image: coverPath != null
                              ? DecorationImage(image: FileImage(File(coverPath!)), fit: BoxFit.cover)
                              : null,
                          border: Border.all(
                            color: coverPath != null ? Colors.transparent : Colors.white.withOpacity(0.08),
                            width: 1.2,
                          ),
                        ),
                        child: coverPath == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _kAccent.withOpacity(0.15),
                                    ),
                                    child: const Icon(Icons.add_photo_alternate_rounded, color: _kAccent, size: 24),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Choose cover (optional)',
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.white.withOpacity(0.04),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancel',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ).copyWith(
                              backgroundColor: WidgetStateProperty.all(Colors.transparent),
                              foregroundColor: WidgetStateProperty.all(Colors.white),
                              overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
                            ),
                            onPressed: () {
                              if (titleController.text.trim().isNotEmpty) {
                                context.read<HiddenPhotoService>().createCollection(
                                      titleController.text.trim(),
                                      coverPath,
                                    );
                                Navigator.pop(ctx);
                              }
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [_kAccent, _kAccent2]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                height: 46,
                                alignment: Alignment.center,
                                child: const Text('Create',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, HiddenCollection collection) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Collection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text('Delete "${collection.title}" and all its photos?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              context.read<HiddenPhotoService>().deleteCollection(collection.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openCollection(BuildContext context, HiddenCollection col) {
    String? resolvedCover = col.coverPhotoPath;
    if (resolvedCover == null || !File(resolvedCover).existsSync()) {
      resolvedCover = col.photoPaths.isNotEmpty && File(col.photoPaths.first).existsSync()
          ? col.photoPaths.first
          : null;
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => HiddenVaultIntroScreen(
          collectionId: col.id,
          title: col.title,
          coverPath: resolvedCover,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildCover(BuildContext context, HiddenCollection col, HiddenPhotoService service) {
    if (col.coverPhotoPath != null && File(col.coverPhotoPath!).existsSync()) {
      if (service.isVideo(col.coverPhotoPath!)) {
        return _GridVideoPlayer(videoPath: col.coverPhotoPath!);
      }
      return Image.file(File(col.coverPhotoPath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderCover());
    }
    if (col.photoPaths.isNotEmpty && File(col.photoPaths.first).existsSync()) {
      final first = col.photoPaths.first;
      if (service.isVideo(first)) {
        return _GridVideoPlayer(videoPath: first);
      }
      return Image.file(File(first),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderCover());
    }
    return _placeholderCover();
  }

  Widget _placeholderCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1935), Color(0xFF14141F)],
        ),
      ),
      child: const Icon(Icons.folder_rounded, color: Colors.white24, size: 44),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<HiddenPhotoService>();
    final collections = service.collections;
    final totalItems = collections.fold<int>(0, (sum, c) => sum + c.photoPaths.length);

    return Scaffold(
      backgroundColor: _kBg,
      extendBodyBehindAppBar: true,
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: _kBg,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: const Text(
                      'Private Vault',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    background: _HeroHeader(
                      collectionCount: collections.length,
                      totalItems: totalItems,
                    ),
                  ),
                ),
                if (collections.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final col = collections[index];
                          return _CollectionCard(
                            collection: col,
                            cover: _buildCover(context, col, service),
                            onTap: () => _openCollection(context, col),
                            onLongPress: () => _confirmDelete(context, col),
                          );
                        },
                        childCount: collections.length,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _GradientFab(
        onTap: () => _createCollection(context),
        label: 'New Collection',
        icon: Icons.add_rounded,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_kAccent.withOpacity(0.25), _kAccent.withOpacity(0.0)],
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [_kAccent, _kAccent2]),
                boxShadow: [BoxShadow(color: _kAccent.withOpacity(0.4), blurRadius: 24, spreadRadius: 2)],
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your vault is empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a collection to keep private\nphotos safely organized.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final int collectionCount;
  final int totalItems;
  const _HeroHeader({required this.collectionCount, required this.totalItems});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A003F), _kAccent2, _kAccent],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -50,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
          child: Container(color: Colors.transparent),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _kBg.withOpacity(0.0),
                _kBg,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 90,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.4),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENCRYPTED SPACE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _HeroStat(value: '$collectionCount', label: 'vaults'),
                        const SizedBox(width: 10),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _HeroStat(value: '$totalItems', label: 'items'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          TextSpan(
            text: ' $label',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.4),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final HiddenCollection collection;
  final Widget cover;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CollectionCard({
    required this.collection,
    required this.cover,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.18),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              cover,
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.45, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${collection.photoPaths.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kAccent.withOpacity(0.9),
                  ),
                  child: const Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      collection.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${collection.photoPaths.length} items',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientFab extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  const _GradientFab({required this.onTap, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kAccent, _kAccent2]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: _kAccent.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                )),
          ],
        ),
      ),
    );
  }
}

class _GridVideoPlayer extends StatefulWidget {
  final String videoPath;
  const _GridVideoPlayer({required this.videoPath});

  @override
  State<_GridVideoPlayer> createState() => _GridVideoPlayerState();
}

class _GridVideoPlayerState extends State<_GridVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(
      File(widget.videoPath),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        if (mounted) {
          _controller.setVolume(0);
          _controller.setLooping(true);
          _controller.play();
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      final thumb = File('${widget.videoPath}.jpg');
      if (thumb.existsSync()) {
        return Image.file(thumb, fit: BoxFit.cover);
      }
      return Container(color: const Color(0xFF2A2A3E));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
