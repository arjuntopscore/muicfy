import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../hidden_photo_service.dart';
import 'hidden_photo_viewer.dart';

const Color _kAccent = Color(0xFFFF4081);
const Color _kAccent2 = Color(0xFF7A1FA2);
const Color _kBg = Color(0xFF070711);
const Color _kSurface = Color(0xFF14141F);
const Color _kSurfaceHigh = Color(0xFF1E1E2E);

class HiddenGalleryScreen extends StatelessWidget {
  final String collectionId;
  const HiddenGalleryScreen({super.key, required this.collectionId});

  Future<void> _pickAndAddPhoto(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        final service = context.read<HiddenPhotoService>();
        int added = 0;
        for (final file in result.files) {
          if (file.path != null) {
            final ok = await service.addPhotoToCollection(collectionId, file.path!);
            if (ok) added++;
          }
        }
        if (context.mounted && added > 0) {
          _showSnack(context, 'Added $added photo${added > 1 ? 's' : ''} to the vault');
        }
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  void _showSnack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: error ? Colors.redAccent : _kAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Photo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('Remove this photo from the vault? This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final service = context.read<HiddenPhotoService>();
      await service.removePhotoFromCollection(collectionId, index);
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            decoration: BoxDecoration(
              color: _kSurface.withOpacity(0.92),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _AddOptionTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Pick from device',
                  subtitle: 'Choose photos or videos',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndAddPhoto(context);
                  },
                ),
                _AddOptionTile(
                  icon: Icons.link_rounded,
                  title: 'Import from URL',
                  subtitle: 'Direct image links (.jpg, .png)',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showUrlImportDialog(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUrlImportDialog(BuildContext context) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Import image URL',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: urlController,
          style: const TextStyle(color: Colors.white),
          cursorColor: _kAccent,
          decoration: InputDecoration(
            hintText: 'https://example.com/image.jpg',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                _downloadFromUrl(context, url);
              }
            },
            child: const Text('Download',
                style: TextStyle(color: _kAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFromUrl(BuildContext context, String url) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Downloading...'),
          ],
        ),
        backgroundColor: _kAccent,
        duration: const Duration(seconds: 10),
      ),
    );

    final service = context.read<HiddenPhotoService>();
    final ok = await service.downloadPhotoToCollection(collectionId, url);

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (ok) {
        _showSnack(context, 'Photo added to the vault');
      } else {
        _showSnack(context, 'Failed to download. Use a direct image URL.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<HiddenPhotoService>();
    final collection = service.collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => HiddenCollection(id: '', title: 'Unknown'),
    );
    final photos = collection.photoPaths;
    final coverPath = collection.coverPhotoPath ??
        (photos.isNotEmpty ? photos.first : null);

    return Scaffold(
      backgroundColor: _kBg,
      extendBodyBehindAppBar: true,
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2))
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
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                    title: Text(
                      collection.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    background: _GalleryHero(
                      coverPath: coverPath,
                      title: collection.title,
                      photoCount: photos.length,
                      service: service,
                    ),
                  ),
                ),
                if (photos.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final isCover = collection.coverPhotoPath == photos[index];
                          return _PhotoCard(
                            photoPath: photos[index],
                            index: index,
                            isCover: isCover,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HiddenPhotoViewer(
                                      photoPaths: photos, initialIndex: index),
                                ),
                              );
                            },
                            onSetCover: () {
                              service.setCollectionCover(collectionId, photos[index]);
                              _showSnack(context, 'Set as cover photo');
                            },
                            onDelete: () => _confirmDelete(context, index),
                          );
                        },
                        childCount: photos.length,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _GradientFab(
        onTap: () => _showAddOptions(context),
        label: 'Add',
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
              child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No photos yet',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add private\nphotos or videos to this collection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _GalleryHero extends StatelessWidget {
  final String? coverPath;
  final String title;
  final int photoCount;
  final HiddenPhotoService service;

  const _GalleryHero({
    required this.coverPath,
    required this.title,
    required this.photoCount,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = coverPath != null &&
        File(coverPath!).existsSync() &&
        !service.isVideo(coverPath!);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          Image.file(File(coverPath!), fit: BoxFit.cover)
        else
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
        if (hasImage)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(color: Colors.black.withOpacity(0.35)),
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  image: hasImage
                      ? DecorationImage(image: FileImage(File(coverPath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: hasImage ? null : const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kAccent.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kAccent.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, color: Colors.white, size: 11),
                              SizedBox(width: 4),
                              Text(
                                'PRIVATE',
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$photoCount ${photoCount == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
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

class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_kAccent.withOpacity(0.3), _kAccent2.withOpacity(0.3)],
                ),
                border: Border.all(color: _kAccent.withOpacity(0.4)),
              ),
              child: Icon(icon, color: _kAccent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.4)),
          ],
        ),
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

class _PhotoCard extends StatefulWidget {
  final String photoPath;
  final int index;
  final bool isCover;
  final VoidCallback onTap;
  final VoidCallback onSetCover;
  final VoidCallback onDelete;

  const _PhotoCard({
    required this.photoPath,
    required this.index,
    required this.isCover,
    required this.onTap,
    required this.onSetCover,
    required this.onDelete,
  });

  @override
  State<_PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<_PhotoCard> {
  bool _pressed = false;

  void _showOptionsMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      color: _kSurfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        PopupMenuItem<String>(
          value: 'cover',
          child: Row(
            children: [
              Icon(widget.isCover ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _kAccent, size: 20),
              const SizedBox(width: 10),
              Text(widget.isCover ? 'Current Cover' : 'Set as Cover',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 10),
              Text('Delete',
                  style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'cover') {
        widget.onSetCover();
      } else if (value == 'delete') {
        widget.onDelete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<HiddenPhotoService>();
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (details) => _showOptionsMenu(context, details.globalPosition),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(widget.isCover ? 0.3 : 0.15),
                blurRadius: 16,
                spreadRadius: widget.isCover ? -1 : -3,
                offset: const Offset(0, 6),
              ),
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(service.isVideo(widget.photoPath)
                      ? '${widget.photoPath}.jpg'
                      : widget.photoPath),
                  fit: BoxFit.cover,
                  cacheWidth: 400,
                  errorBuilder: (_, __, ___) => Container(
                    color: _kSurface,
                    child: const Icon(Icons.broken_image_rounded,
                        color: Colors.white24, size: 40),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                        stops: const [0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                if (service.isVideo(widget.photoPath))
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.4),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                if (widget.isCover)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kAccent, _kAccent2]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: _kAccent.withOpacity(0.5), blurRadius: 8),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 3),
                          Text('Cover',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white70, size: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
