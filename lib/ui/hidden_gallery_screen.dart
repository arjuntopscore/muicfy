import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../hidden_photo_service.dart';
import 'hidden_photo_viewer.dart';

const Color _kVaultBg = Color(0xFF090D16);
const Color _kVaultSurface = Color(0xFF131926);
const Color _kVaultSurfaceHigh = Color(0xFF1A2234);
const Color _kCyberCyan = Color(0xFF00E5FF);
const Color _kNeonRose = Color(0xFFFF2D55);
const Color _kSecureGreen = Color(0xFF10B981);

enum _MediaFilter { all, photos, videos, favorites }
enum _SortOrder { newest, oldest, size }

class HiddenGalleryScreen extends StatefulWidget {
  final String collectionId;
  const HiddenGalleryScreen({super.key, required this.collectionId});

  @override
  State<HiddenGalleryScreen> createState() => _HiddenGalleryScreenState();
}

class _HiddenGalleryScreenState extends State<HiddenGalleryScreen> {
  _MediaFilter _activeFilter = _MediaFilter.all;
  _SortOrder _sortOrder = _SortOrder.newest;
  bool _selectionMode = false;
  final Set<String> _selectedPaths = {};

  void _panicLock() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
        if (_selectedPaths.isEmpty) _selectionMode = false;
      } else {
        _selectedPaths.add(path);
        _selectionMode = true;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _selectAll(List<String> allVisible) {
    setState(() {
      if (_selectedPaths.length == allVisible.length) {
        _selectedPaths.clear();
        _selectionMode = false;
      } else {
        _selectedPaths.addAll(allVisible);
        _selectionMode = true;
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _pickAndAddMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        if (!mounted) return;
        final service = context.read<HiddenPhotoService>();
        int added = 0;
        for (final file in result.files) {
          if (file.path != null) {
            final ok = await service.addPhotoToCollection(widget.collectionId, file.path!);
            if (ok) added++;
          }
        }
        if (mounted && added > 0) {
          _showSnack('Encrypted $added ${added > 1 ? 'items' : 'item'} into vault');
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: error ? Colors.redAccent : _kSecureGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _confirmDeleteSingle(String path, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => AlertDialog(
        backgroundColor: _kVaultSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text('Purge Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Remove this encrypted item permanently? This action cannot be reversed.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Purge', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final service = context.read<HiddenPhotoService>();
      await service.removePhotoFromCollection(widget.collectionId, index);
      _showSnack('Item purged from vault');
    }
  }

  Future<void> _confirmBatchDelete() async {
    if (_selectedPaths.isEmpty) return;
    final count = _selectedPaths.length;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => AlertDialog(
        backgroundColor: _kVaultSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 22),
            const SizedBox(width: 10),
            Text('Purge $count Items', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Permanently delete $count selected items from this enclave?',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Purge Selected', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final service = context.read<HiddenPhotoService>();
      final deleted = await service.batchDelete(widget.collectionId, _selectedPaths.toList());
      setState(() {
        _selectedPaths.clear();
        _selectionMode = false;
      });
      _showSnack('Purged $deleted items');
    }
  }

  Future<void> _batchMove(BuildContext context) async {
    final service = context.read<HiddenPhotoService>();
    final otherCollections = service.collections.where((c) => c.id != widget.collectionId).toList();

    if (otherCollections.isEmpty) {
      _showSnack('Create another enclave first to move items', error: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: _kVaultSurface.withValues(alpha: 0.96),
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
                Text(
                  'Move ${_selectedPaths.length} items to...',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 14),
                ...otherCollections.map((col) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kCyberCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.folder_fill, color: _kCyberCyan, size: 18),
                      ),
                      title: Text(col.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      subtitle: Text('${col.photoPaths.length} items', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final moved = await service.batchMove(
                          widget.collectionId,
                          col.id,
                          _selectedPaths.toList(),
                        );
                        setState(() {
                          _selectedPaths.clear();
                          _selectionMode = false;
                        });
                        if (mounted) {
                          _showSnack('Moved $moved items to "${col.title}"');
                        }
                      },
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMediaDetails(BuildContext context, String path) {
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
              color: _kVaultSurface.withValues(alpha: 0.96),
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
                    Text('Media Enclave Metadata', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 18),
                _MetaRow(label: 'Type', value: isVid ? 'Video Stream (.mp4)' : 'Encrypted Image (.jpg/.png)'),
                _MetaRow(label: 'Storage Size', value: size),
                if (modDate != null)
                  _MetaRow(label: 'Encrypted On', value: '${modDate.year}-${modDate.month.toString().padLeft(2, '0')}-${modDate.day.toString().padLeft(2, '0')} ${modDate.hour.toString().padLeft(2, '0')}:${modDate.minute.toString().padLeft(2, '0')}'),
                _MetaRow(label: 'Security Level', value: 'AES-256 Zero-Knowledge Local Sandbox'),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close', style: TextStyle(color: _kCyberCyan, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            decoration: BoxDecoration(
              color: _kVaultSurface.withValues(alpha: 0.95),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _AddTile(
                  icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                  title: 'Device Media Library',
                  subtitle: 'Select multiple photos or video recordings',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndAddMedia();
                  },
                ),
                _AddTile(
                  icon: CupertinoIcons.link,
                  title: 'Direct URL Download',
                  subtitle: 'Download and encrypt from direct media URL',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showUrlImportDialog(context);
                  },
                ),
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
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => AlertDialog(
        backgroundColor: _kVaultSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Import Media via URL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        content: TextField(
          controller: urlController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: _kCyberCyan,
          decoration: InputDecoration(
            hintText: 'https://example.com/asset.mp4 or .jpg',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kCyberCyan, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kCyberCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                _downloadFromUrl(url);
              }
            },
            child: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFromUrl(String url) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Downloading & Encrypting...'),
          ],
        ),
        backgroundColor: _kVaultSurfaceHigh,
        duration: const Duration(seconds: 12),
      ),
    );

    final service = context.read<HiddenPhotoService>();
    final ok = await service.downloadPhotoToCollection(widget.collectionId, url);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (ok) {
        _showSnack('Media encrypted into vault');
      } else {
        _showSnack('Failed to download. Check URL format.', error: true);
      }
    }
  }

  List<String> _getFilteredPhotos(HiddenCollection collection, HiddenPhotoService service) {
    List<String> list = List.from(collection.photoPaths);

    // Apply Filter
    switch (_activeFilter) {
      case _MediaFilter.photos:
        list = list.where((p) => !service.isVideo(p)).toList();
        break;
      case _MediaFilter.videos:
        list = list.where((p) => service.isVideo(p)).toList();
        break;
      case _MediaFilter.favorites:
        list = list.where((p) => collection.favorites.contains(p)).toList();
        break;
      case _MediaFilter.all:
        break;
    }

    // Apply Sort
    switch (_sortOrder) {
      case _SortOrder.newest:
        // already newest first
        break;
      case _SortOrder.oldest:
        list = list.reversed.toList();
        break;
      case _SortOrder.size:
        list.sort((a, b) {
          final sizeA = File(a).existsSync() ? File(a).lengthSync() : 0;
          final sizeB = File(b).existsSync() ? File(b).lengthSync() : 0;
          return sizeB.compareTo(sizeA);
        });
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<HiddenPhotoService>();
    final collection = service.collections.firstWhere(
      (c) => c.id == widget.collectionId,
      orElse: () => HiddenCollection(id: '', title: 'Unknown'),
    );

    final allPhotos = collection.photoPaths;
    final filteredPhotos = _getFilteredPhotos(collection, service);
    final coverPath = collection.coverPhotoPath ?? (allPhotos.isNotEmpty ? allPhotos.first : null);

    final photoCount = allPhotos.where((p) => !service.isVideo(p)).length;
    final videoCount = allPhotos.where((p) => service.isVideo(p)).length;
    final favCount = collection.favorites.length;

    return Scaffold(
      backgroundColor: _kVaultBg,
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator(color: _kCyberCyan, strokeWidth: 2))
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 260,
                      pinned: true,
                      backgroundColor: _kVaultBg,
                      elevation: 0,
                      leading: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _CircleIconButton(
                          icon: CupertinoIcons.chevron_back,
                          onTap: () {
                            if (_selectionMode) {
                              setState(() {
                                _selectionMode = false;
                                _selectedPaths.clear();
                              });
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                      actions: [
                        // Select / Selection counter button
                        if (allPhotos.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor: _selectionMode
                                    ? _kCyberCyan.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectionMode = !_selectionMode;
                                  if (!_selectionMode) _selectedPaths.clear();
                                });
                              },
                              icon: Icon(
                                _selectionMode ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.checkmark_circle,
                                color: _selectionMode ? _kCyberCyan : Colors.white70,
                                size: 16,
                              ),
                              label: Text(
                                _selectionMode ? 'Done' : 'Select',
                                style: TextStyle(
                                  color: _selectionMode ? _kCyberCyan : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                        // Panic lock
                        Padding(
                          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                          child: Tooltip(
                            message: 'Panic Lock',
                            child: _CircleIconButton(
                              icon: CupertinoIcons.lock_slash_fill,
                              color: _kNeonRose,
                              onTap: _panicLock,
                            ),
                          ),
                        ),
                      ],
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
                          photoCount: allPhotos.length,
                          service: service,
                        ),
                      ),
                    ),

                    // Filter & Sort Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Column(
                          children: [
                            // Filter Pills Row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FilterPill(
                                    label: 'All (${allPhotos.length})',
                                    active: _activeFilter == _MediaFilter.all,
                                    onTap: () => setState(() => _activeFilter = _MediaFilter.all),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterPill(
                                    icon: CupertinoIcons.photo,
                                    label: 'Photos ($photoCount)',
                                    active: _activeFilter == _MediaFilter.photos,
                                    onTap: () => setState(() => _activeFilter = _MediaFilter.photos),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterPill(
                                    icon: CupertinoIcons.play_circle,
                                    label: 'Videos ($videoCount)',
                                    active: _activeFilter == _MediaFilter.videos,
                                    onTap: () => setState(() => _activeFilter = _MediaFilter.videos),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterPill(
                                    icon: CupertinoIcons.heart_fill,
                                    label: 'Favorites ($favCount)',
                                    active: _activeFilter == _MediaFilter.favorites,
                                    onTap: () => setState(() => _activeFilter = _MediaFilter.favorites),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Sort & Select-All bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_selectionMode)
                                  GestureDetector(
                                    onTap: () => _selectAll(filteredPhotos),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _selectedPaths.length == filteredPhotos.length
                                              ? CupertinoIcons.check_mark_circled_solid
                                              : CupertinoIcons.circle,
                                          color: _kCyberCyan,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _selectedPaths.length == filteredPhotos.length ? 'Deselect All' : 'Select All',
                                          style: const TextStyle(color: _kCyberCyan, fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    '${filteredPhotos.length} items',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),

                                // Sort Menu
                                PopupMenuButton<_SortOrder>(
                                  color: _kVaultSurfaceHigh,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  onSelected: (sort) => setState(() => _sortOrder = sort),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _sortOrder == _SortOrder.newest
                                              ? CupertinoIcons.arrow_down
                                              : (_sortOrder == _SortOrder.oldest ? CupertinoIcons.arrow_up : CupertinoIcons.chart_bar_alt_fill),
                                          color: Colors.white70,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _sortOrder == _SortOrder.newest
                                              ? 'Newest'
                                              : (_sortOrder == _SortOrder.oldest ? 'Oldest' : 'By Size'),
                                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(CupertinoIcons.chevron_down, color: Colors.white38, size: 10),
                                      ],
                                    ),
                                  ),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: _SortOrder.newest,
                                      child: Text('Newest First', style: TextStyle(color: Colors.white, fontSize: 13)),
                                    ),
                                    const PopupMenuItem(
                                      value: _SortOrder.oldest,
                                      child: Text('Oldest First', style: TextStyle(color: Colors.white, fontSize: 13)),
                                    ),
                                    const PopupMenuItem(
                                      value: _SortOrder.size,
                                      child: Text('Largest File Size', style: TextStyle(color: Colors.white, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (filteredPhotos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context, isFiltered: _activeFilter != _MediaFilter.all),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final path = filteredPhotos[index];
                              final isCover = collection.coverPhotoPath == path;
                              final isFav = collection.favorites.contains(path);
                              final isSelected = _selectedPaths.contains(path);
                              final rawIndex = allPhotos.indexOf(path);

                              return _CyberMediaCard(
                                photoPath: path,
                                isCover: isCover,
                                isFavorite: isFav,
                                isSelected: isSelected,
                                selectionMode: _selectionMode,
                                onTap: () {
                                  if (_selectionMode) {
                                    _toggleSelection(path);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HiddenPhotoViewer(
                                          photoPaths: allPhotos,
                                          initialIndex: rawIndex != -1 ? rawIndex : 0,
                                          collectionId: widget.collectionId,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                onLongPress: () {
                                  if (!_selectionMode) {
                                    _toggleSelection(path);
                                  }
                                },
                                onToggleFavorite: () {
                                  service.toggleFavorite(widget.collectionId, path);
                                  HapticFeedback.lightImpact();
                                },
                                onSetCover: () {
                                  service.setCollectionCover(widget.collectionId, path);
                                  _showSnack('Set as enclave cover');
                                },
                                onDetails: () => _showMediaDetails(context, path),
                                onDelete: () => _confirmDeleteSingle(path, rawIndex),
                              );
                            },
                            childCount: filteredPhotos.length,
                          ),
                        ),
                      ),
                  ],
                ),

                // Floating Batch Selection Bottom Bar
                if (_selectionMode)
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _kVaultSurface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _kCyberCyan.withValues(alpha: 0.4)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _kCyberCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_selectedPaths.length} selected',
                                  style: const TextStyle(color: _kCyberCyan, fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                              ),
                              const Spacer(),
                              // Move action
                              IconButton(
                                icon: const Icon(CupertinoIcons.folder_badge_plus, color: Colors.white70),
                                tooltip: 'Move to another enclave',
                                onPressed: _selectedPaths.isEmpty ? null : () => _batchMove(context),
                              ),
                              // Delete action
                              IconButton(
                                icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent),
                                tooltip: 'Purge selected',
                                onPressed: _selectedPaths.isEmpty ? null : () => _confirmBatchDelete(),
                              ),
                              const SizedBox(width: 4),
                              // Close action
                              InkWell(
                                onTap: () => setState(() {
                                  _selectionMode = false;
                                  _selectedPaths.clear();
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _selectionMode
          ? null
          : _CyberGlowFab(
              onTap: () => _showAddOptions(context),
              label: 'Encrypt',
              icon: CupertinoIcons.add,
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isFiltered}) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_kCyberCyan.withValues(alpha: 0.2), Colors.transparent],
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kCyberCyan, _kNeonRose],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: _kCyberCyan.withValues(alpha: 0.4), blurRadius: 24, spreadRadius: 2),
                ],
              ),
              child: const Icon(CupertinoIcons.photo_on_rectangle, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? 'No Matches In Filter' : 'No Encrypted Media Yet',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try switching the filter pill above to view all items.'
                : 'Import private photos or sensitive video clips into this encrypted enclave partition.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14, height: 1.5),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCyberCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _showAddOptions(context),
              icon: const Icon(CupertinoIcons.plus_circle_fill, size: 18),
              label: const Text('Encrypt First Item', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _FilterPill({required this.label, this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _kCyberCyan : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _kCyberCyan : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: active ? Colors.black : Colors.white70, size: 13),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
    final hasImage = coverPath != null && File(coverPath!).existsSync() && !service.isVideo(coverPath!);

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
                colors: [Color(0xFF0F2038), Color(0xFF16102C), Color(0xFF090D16)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        if (hasImage)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _kVaultBg.withValues(alpha: 0.0),
                _kVaultBg,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 96,
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: _kCyberCyan.withValues(alpha: 0.4), width: 1.5),
                  image: hasImage ? DecorationImage(image: FileImage(File(coverPath!)), fit: BoxFit.cover) : null,
                  boxShadow: [
                    BoxShadow(color: _kCyberCyan.withValues(alpha: 0.25), blurRadius: 16),
                  ],
                ),
                child: hasImage ? null : const Icon(CupertinoIcons.lock_shield_fill, color: _kCyberCyan, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kSecureGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kSecureGreen.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.shield_fill, color: _kSecureGreen, size: 10),
                          SizedBox(width: 4),
                          Text(
                            'SECURE ENCLAVE',
                            style: TextStyle(
                              color: _kSecureGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$photoCount ${photoCount == 1 ? 'item' : 'items'} encrypted',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
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

class _CyberMediaCard extends StatefulWidget {
  final String photoPath;
  final bool isCover;
  final bool isFavorite;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleFavorite;
  final VoidCallback onSetCover;
  final VoidCallback onDetails;
  final VoidCallback onDelete;

  const _CyberMediaCard({
    required this.photoPath,
    required this.isCover,
    required this.isFavorite,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleFavorite,
    required this.onSetCover,
    required this.onDetails,
    required this.onDelete,
  });

  @override
  State<_CyberMediaCard> createState() => _CyberMediaCardState();
}

class _CyberMediaCardState extends State<_CyberMediaCard> {
  bool _pressed = false;

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: _kVaultSurface.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Icon(
                    widget.isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: widget.isFavorite ? _kNeonRose : Colors.white,
                  ),
                  title: Text(widget.isFavorite ? 'Remove from Favorites' : 'Add to Favorites', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onToggleFavorite();
                  },
                ),
                ListTile(
                  leading: Icon(widget.isCover ? CupertinoIcons.star_fill : CupertinoIcons.star, color: Colors.amber),
                  title: Text(widget.isCover ? 'Current Cover' : 'Set as Enclave Cover', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onSetCover();
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.info_circle, color: _kCyberCyan),
                  title: const Text('View Metadata', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onDetails();
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.trash, color: Colors.redAccent),
                  title: const Text('Purge Item', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onDelete();
                  },
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
    final service = context.read<HiddenPhotoService>();
    final isVid = service.isVideo(widget.photoPath);
    final thumbPath = isVid ? '${widget.photoPath}.jpg' : widget.photoPath;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () {
        if (!widget.selectionMode) {
          _showContextMenu(context);
        } else {
          widget.onLongPress();
        }
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? _kCyberCyan
                  : (widget.isCover ? _kCyberCyan.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08)),
              width: widget.isSelected ? 2.5 : (widget.isCover ? 1.5 : 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? _kCyberCyan.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.45),
                blurRadius: widget.isSelected ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(thumbPath),
                  fit: BoxFit.cover,
                  cacheWidth: 400,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: _kVaultSurface,
                    child: const Icon(CupertinoIcons.photo, color: Colors.white24, size: 36),
                  ),
                ),

                // Selection tinted overlay
                if (widget.isSelected)
                  Container(
                    color: _kCyberCyan.withValues(alpha: 0.25),
                  ),

                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),

                // Video play indicator
                if (isVid)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10),
                        ],
                      ),
                      child: const Icon(CupertinoIcons.play_fill, color: Colors.white, size: 22),
                    ),
                  ),

                // Selection checkmark
                if (widget.selectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isSelected ? _kCyberCyan : Colors.black45,
                        border: Border.all(
                          color: widget.isSelected ? _kCyberCyan : Colors.white70,
                          width: 2,
                        ),
                      ),
                      child: widget.isSelected
                          ? const Icon(Icons.check, color: Colors.black, size: 16)
                          : null,
                    ),
                  ),

                // Favorite Heart tag
                if (widget.isFavorite && !widget.selectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kNeonRose.withValues(alpha: 0.85),
                        boxShadow: [
                          BoxShadow(color: _kNeonRose.withValues(alpha: 0.5), blurRadius: 8),
                        ],
                      ),
                      child: const Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 12),
                    ),
                  ),

                // Cover Badge
                if (widget.isCover)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kCyberCyan, _kNeonRose]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: _kCyberCyan.withValues(alpha: 0.4), blurRadius: 8),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.star_fill, color: Colors.white, size: 10),
                          SizedBox(width: 3),
                          Text('COVER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),

                // Bottom security lock indicator
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Icon(CupertinoIcons.lock_shield_fill, color: Colors.white70, size: 11),
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

class _AddTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddTile({
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_kCyberCyan.withValues(alpha: 0.25), _kNeonRose.withValues(alpha: 0.25)],
                ),
                border: Border.all(color: _kCyberCyan.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: _kCyberCyan, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_forward, color: Colors.white.withValues(alpha: 0.4), size: 16),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _CircleIconButton({required this.icon, required this.onTap, this.color});

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
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, color: color ?? Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _CyberGlowFab extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  const _CyberGlowFab({required this.onTap, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kCyberCyan, _kNeonRose],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _kNeonRose.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
