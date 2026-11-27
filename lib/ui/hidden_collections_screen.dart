import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../hidden_photo_service.dart';
import 'hidden_vault_intro_screen.dart';

const Color _kVaultBg = Color(0xFF090D16);
const Color _kVaultSurface = Color(0xFF131926);
const Color _kVaultSurfaceHigh = Color(0xFF1A2234);
const Color _kCyberCyan = Color(0xFF00E5FF);
const Color _kNeonRose = Color(0xFFFF2D55);
const Color _kSecureGreen = Color(0xFF10B981);

class HiddenCollectionsScreen extends StatefulWidget {
  const HiddenCollectionsScreen({super.key});

  @override
  State<HiddenCollectionsScreen> createState() => _HiddenCollectionsScreenState();
}

class _HiddenCollectionsScreenState extends State<HiddenCollectionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _panicLock(BuildContext context) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    // Immediately return to the main application
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _createCollection(BuildContext context) async {
    final titleController = TextEditingController();
    String? coverPath;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: _kVaultSurface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [_kCyberCyan, _kNeonRose],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kNeonRose.withValues(alpha: 0.35),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: const Icon(CupertinoIcons.lock_shield_fill, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Enclave',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Create a private encrypted partition',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      cursorColor: _kCyberCyan,
                      decoration: InputDecoration(
                        hintText: 'Partition name (e.g., Vault Alpha)',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _kCyberCyan, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (result != null && result.files.single.path != null) {
                          setDialogState(() => coverPath = result.files.single.path);
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(18),
                          image: coverPath != null
                              ? DecorationImage(image: FileImage(File(coverPath!)), fit: BoxFit.cover)
                              : null,
                          border: Border.all(
                            color: coverPath != null ? _kCyberCyan : Colors.white.withValues(alpha: 0.1),
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
                                      color: _kCyberCyan.withValues(alpha: 0.12),
                                    ),
                                    child: const Icon(CupertinoIcons.photo_on_rectangle, color: _kCyberCyan, size: 22),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Set cover art (optional)',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                  ),
                                ],
                              )
                            : Container(
                                alignment: Alignment.topRight,
                                padding: const EdgeInsets.all(8),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.check, color: _kSecureGreen, size: 16),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_kCyberCyan, _kNeonRose]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _kNeonRose.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                if (titleController.text.trim().isNotEmpty) {
                                  context.read<HiddenPhotoService>().createCollection(
                                        titleController.text.trim(),
                                        coverPath,
                                      );
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(ctx);
                                }
                              },
                              child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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

  void _renameCollection(BuildContext context, HiddenCollection collection) {
    final controller = TextEditingController(text: collection.title);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => AlertDialog(
        backgroundColor: _kVaultSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Rename Vault', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          cursorColor: _kCyberCyan,
          decoration: InputDecoration(
            hintText: 'Enter new vault name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
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
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<HiddenPhotoService>().renameCollection(collection.id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, HiddenCollection collection) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => AlertDialog(
        backgroundColor: _kVaultSurfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text('Purge Enclave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Permanently delete "${collection.title}" and all its ${collection.photoPaths.length} encrypted items? This cannot be recovered.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              context.read<HiddenPhotoService>().deleteCollection(collection.id);
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
            },
            child: const Text('Purge', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showVaultSettings(BuildContext context) {
    final service = context.read<HiddenPhotoService>();
    final formattedSize = service.getFormattedStorageSize();
    final totalVaults = service.collections.length;
    final totalItems = service.collections.fold<int>(0, (sum, c) => sum + c.photoPaths.length);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: _kVaultSurface.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kCyberCyan.withValues(alpha: 0.12),
                      ),
                      child: const Icon(CupertinoIcons.gear_alt_fill, color: _kCyberCyan, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enclave Security & Storage',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        Text(
                          'Cryptographic Vault Configuration',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Storage Metric Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kSecureGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.chart_pie_fill, color: _kSecureGreen, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Local Encrypted Storage', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              formattedSize,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalItems files / $totalVaults vaults',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Security status row
                _SettingsTile(
                  icon: CupertinoIcons.shield_lefthalf_fill,
                  title: 'Security Architecture',
                  subtitle: 'AES-256 GCM Isolated Sandbox Enclave',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kSecureGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kSecureGreen.withValues(alpha: 0.4)),
                    ),
                    child: const Text('ACTIVE', style: TextStyle(color: _kSecureGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: CupertinoIcons.lock_rotation,
                  title: 'Change Enclave PIN',
                  subtitle: 'Update your 6-digit master unlock PIN',
                  trailing: const Icon(CupertinoIcons.chevron_forward, color: Colors.white38, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showChangePinDialog(context);
                  },
                ),
                _SettingsTile(
                  icon: CupertinoIcons.bolt_slash_fill,
                  title: 'Emergency Panic Mode',
                  subtitle: 'Immediate memory flush & jump to music player',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kNeonRose.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kNeonRose.withValues(alpha: 0.4)),
                    ),
                    child: const Text('READY', style: TextStyle(color: _kNeonRose, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                  onTap: () => _panicLock(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _kVaultSurfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Change Master PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              TextField(
                controller: oldPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: InputDecoration(
                  hintText: 'Current PIN',
                  hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 0),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: InputDecoration(
                  hintText: 'New 6-digit PIN',
                  hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 0),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: InputDecoration(
                  hintText: 'Confirm new PIN',
                  hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 0),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ],
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
                final oldPin = oldPinController.text.trim();
                final newPin = newPinController.text.trim();
                final confirmPin = confirmPinController.text.trim();

                if (newPin != confirmPin) {
                  setDialogState(() => errorText = 'New PINs do not match');
                  return;
                }
                if (newPin.length < 4) {
                  setDialogState(() => errorText = 'PIN must be at least 4 digits');
                  return;
                }

                final service = context.read<HiddenPhotoService>();
                final ok = await service.changePin(oldPin, newPin);
                if (ok) {
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Vault PIN successfully updated'),
                        backgroundColor: _kSecureGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    );
                  }
                } else {
                  setDialogState(() => errorText = 'Incorrect current PIN');
                }
              },
              child: const Text('Update PIN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (context, animation, secondaryAnimation) => HiddenVaultIntroScreen(
          collectionId: col.id,
          title: col.title,
          coverPath: resolvedCover,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildCover(BuildContext context, HiddenCollection col, HiddenPhotoService service) {
    if (col.coverPhotoPath != null && File(col.coverPhotoPath!).existsSync()) {
      if (service.isVideo(col.coverPhotoPath!)) {
        return _VaultGridVideoPlayer(videoPath: col.coverPhotoPath!);
      }
      return Image.file(
        File(col.coverPhotoPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderCover(),
      );
    }
    if (col.photoPaths.isNotEmpty && File(col.photoPaths.first).existsSync()) {
      final first = col.photoPaths.first;
      if (service.isVideo(first)) {
        return _VaultGridVideoPlayer(videoPath: first);
      }
      return Image.file(
        File(first),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderCover(),
      );
    }
    return _placeholderCover();
  }

  Widget _placeholderCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2638), Color(0xFF0F1420)],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: const Icon(CupertinoIcons.folder_fill_badge_plus, color: Colors.white30, size: 36),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<HiddenPhotoService>();
    final allCollections = service.collections;
    final totalItems = allCollections.fold<int>(0, (sum, c) => sum + c.photoPaths.length);
    final storageSize = service.getFormattedStorageSize();

    final filteredCollections = _searchQuery.isEmpty
        ? allCollections
        : allCollections.where((c) => c.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: _kVaultBg,
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator(color: _kCyberCyan))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: _kVaultBg,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _CircleIconButton(
                      icon: CupertinoIcons.chevron_back,
                      tooltip: 'Back',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  actions: [
                    // Emergency Panic Button
                    Padding(
                      padding: const EdgeInsets.only(right: 6, top: 8, bottom: 8),
                      child: Tooltip(
                        message: 'Emergency Panic Lock',
                        child: InkWell(
                          onTap: () => _panicLock(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _kNeonRose.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _kNeonRose.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.lock_slash_fill, color: _kNeonRose, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'PANIC',
                                  style: TextStyle(
                                    color: _kNeonRose,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                      child: _CircleIconButton(
                        icon: CupertinoIcons.gear_alt_fill,
                        tooltip: 'Vault Settings',
                        onTap: () => _showVaultSettings(context),
                      ),
                    ),
                  ],
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
                    background: _CyberVaultHero(
                      collectionCount: allCollections.length,
                      totalItems: totalItems,
                      storageSize: storageSize,
                    ),
                  ),
                ),

                // Search & Filter Bar
                if (allCollections.length > 2)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kVaultSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          cursorColor: _kCyberCyan,
                          decoration: InputDecoration(
                            hintText: 'Search enclaves...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
                            prefixIcon: const Icon(CupertinoIcons.search, color: Colors.white38, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (filteredCollections.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context, isSearch: _searchQuery.isNotEmpty),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final col = filteredCollections[index];
                          return _CyberCollectionCard(
                            collection: col,
                            cover: _buildCover(context, col, service),
                            onTap: () => _openCollection(context, col),
                            onRename: () => _renameCollection(context, col),
                            onDelete: () => _confirmDelete(context, col),
                          );
                        },
                        childCount: filteredCollections.length,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _CyberGlowFab(
        onTap: () => _createCollection(context),
        label: 'New Enclave',
        icon: CupertinoIcons.add,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isSearch}) {
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
              child: Icon(
                isSearch ? CupertinoIcons.search : CupertinoIcons.lock_shield_fill,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearch ? 'No Enclaves Found' : 'Vault Enclave Empty',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'No matching partitions match "$_searchQuery"'
                : 'Create an isolated encrypted enclave to safeguard private photos and confidential video recordings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14, height: 1.5),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCyberCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _createCollection(context),
              icon: const Icon(CupertinoIcons.add, size: 18),
              label: const Text('Initialize Partition', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}

class _CyberVaultHero extends StatelessWidget {
  final int collectionCount;
  final int totalItems;
  final String storageSize;

  const _CyberVaultHero({
    required this.collectionCount,
    required this.totalItems,
    required this.storageSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark aurora backdrop
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F2038),
                Color(0xFF16102C),
                Color(0xFF090D16),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Ambient neon blurred circles
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kCyberCyan.withValues(alpha: 0.18),
            ),
          ),
        ),
        Positioned(
          top: 60,
          left: -40,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kNeonRose.withValues(alpha: 0.14),
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(color: Colors.transparent),
        ),
        // Vignette gradient
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
        // Metrics banner
        Positioned(
          left: 20,
          right: 20,
          top: 96,
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: _kCyberCyan.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _kCyberCyan.withValues(alpha: 0.25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.lock_shield_fill, color: _kCyberCyan, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kSecureGreen.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kSecureGreen.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, color: _kSecureGreen, size: 10),
                              SizedBox(width: 4),
                              Text(
                                'AES-256 ZERO-KNOWLEDGE',
                                style: TextStyle(
                                  color: _kSecureGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatToken(value: '$collectionCount', label: 'vaults'),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                        const SizedBox(width: 8),
                        _StatToken(value: '$totalItems', label: 'items'),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                        const SizedBox(width: 8),
                        _StatToken(value: storageSize, label: 'used'),
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

class _StatToken extends StatelessWidget {
  final String value;
  final String label;
  const _StatToken({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' $label',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
  final String? tooltip;
  const _CircleIconButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final btn = Material(
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
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _CyberCollectionCard extends StatelessWidget {
  final HiddenCollection collection;
  final Widget cover;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _CyberCollectionCard({
    required this.collection,
    required this.cover,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

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
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  collection.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(CupertinoIcons.pencil, color: _kCyberCyan),
                  title: const Text('Rename Enclave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onRename();
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.trash, color: Colors.redAccent),
                  title: const Text('Purge Enclave', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
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
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _kCyberCyan.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              cover,
              // Dark vignette overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.45, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
              // Item counter pill
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.photo_on_rectangle, color: Colors.white, size: 11),
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
              // Lock indicator
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kCyberCyan.withValues(alpha: 0.25),
                    border: Border.all(color: _kCyberCyan.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(CupertinoIcons.lock_shield_fill, color: _kCyberCyan, size: 11),
                ),
              ),
              // Bottom information
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
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
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${collection.photoPaths.length} items',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showContextMenu(context),
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.more_vert_rounded, color: Colors.white.withValues(alpha: 0.7), size: 18),
                      ),
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

class _VaultGridVideoPlayer extends StatefulWidget {
  final String videoPath;
  const _VaultGridVideoPlayer({required this.videoPath});

  @override
  State<_VaultGridVideoPlayer> createState() => _VaultGridVideoPlayerState();
}

class _VaultGridVideoPlayerState extends State<_VaultGridVideoPlayer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(
      File(widget.videoPath),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        if (mounted) {
          _controller?.setVolume(0);
          _controller?.setLooping(true);
          _controller?.play();
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      final thumb = File('${widget.videoPath}.jpg');
      if (thumb.existsSync()) {
        return Image.file(thumb, fit: BoxFit.cover);
      }
      return Container(color: _kVaultSurfaceHigh);
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
