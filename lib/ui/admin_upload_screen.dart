import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../admin_service.dart';
import '../music_provider.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';

class AdminUploadScreen extends StatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  String? _audioFilePath;
  String? _audioFileName;
  String? _imageFilePath;
  String? _imageFileName;
  String _selectedLanguage = 'hindi';

  final List<String> _languages = [
    'hindi',
    'tamil',
    'malayalam',
    'telugu',
    'kannada',
    'english',
    'punjabi',
    'bengali',
    'marathi',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final name = result.files.single.name;
        setState(() {
          _audioFilePath = path;
          _audioFileName = name;
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = name.replaceAll(RegExp(r'\.[^.]*$'), '');
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking audio: $e');
    }
  }

  Future<void> _pickImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _imageFilePath = result.files.single.path!;
          _imageFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _uploadSong() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();

    if (title.isEmpty || artist.isEmpty || _audioFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title, Artist, and Audio file are required'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final adminService = context.read<AdminService>();

    final success = await adminService.addCatalogSong(
      title: title,
      artist: artist,
      audioPath: _audioFilePath!,
      imagePath: _imageFilePath ?? '',
      language: _selectedLanguage,
    );

    if (!mounted) return;

    if (success) {
      _titleController.clear();
      _artistController.clear();
      setState(() {
        _audioFilePath = null;
        _audioFileName = null;
        _imageFilePath = null;
        _imageFileName = null;
        _selectedLanguage = 'hindi';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded "$title" — now visible to all users! 🎉'),
          backgroundColor: const Color(0xFF1DB954),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed. Check your internet and try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(AdminService adminService, Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: Text('Remove Song', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${song.title}" from the catalog?\nThis will delete it for all users.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await adminService.removeCatalogSong(song.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Removed "${song.title}"' : 'Failed to remove'),
          backgroundColor: success ? const Color(0xFF282828) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();
    final musicProvider = context.read<MusicProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.accentGradient,
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Admin Catalog',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Refresh catalog',
            onPressed: () => adminService.fetchCatalogFromApi(),
          ),
          TextButton.icon(
            onPressed: () {
              adminService.logout();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout, color: AppTheme.accentColor1, size: 18),
            label: const Text('Logout', style: TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Upload Form ──
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF141926),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.accentColor1.withValues(alpha: 0.35), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_rounded, color: AppTheme.accentColor1, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Upload New Song',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Upload a song file — it will be synced and available to all users.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Audio file picker
                  _buildFilePicker(
                    label: 'Audio File *',
                    fileName: _audioFileName,
                    icon: Icons.audio_file_rounded,
                    accentColor: AppTheme.accentColor1,
                    onTap: adminService.isUploading ? null : _pickAudioFile,
                  ),
                  const SizedBox(height: 12),

                  // Cover image picker
                  _buildFilePicker(
                    label: 'Cover Image (optional)',
                    fileName: _imageFileName,
                    icon: Icons.image_rounded,
                    accentColor: const Color(0xFF0A84FF),
                    onTap: adminService.isUploading ? null : _pickImageFile,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(_titleController, 'Song Title *', Icons.music_note_rounded),
                  const SizedBox(height: 12),
                  _buildTextField(_artistController, 'Artist Name *', Icons.person_rounded),
                  const SizedBox(height: 12),

                  // Language dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E2433),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white60),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        items: _languages.map((lang) {
                          return DropdownMenuItem(
                            value: lang,
                            child: Row(
                              children: [
                                const Icon(Icons.language_rounded, color: Colors.white54, size: 18),
                                const SizedBox(width: 10),
                                Text(lang[0].toUpperCase() + lang.substring(1)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: adminService.isUploading
                            ? null
                            : (val) {
                                if (val != null) setState(() => _selectedLanguage = val);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preview card
                  if (_audioFilePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPreviewCard(),
                    ),

                  // Upload button / progress
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: adminService.isUploading
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.accentColor1,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Uploading to server...',
                                  style: TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: AppTheme.accentGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentColor1.withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _uploadSong,
                              icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                              label: const Text(
                                'Upload to Catalog',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Catalog Songs List ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Catalog Songs (${adminService.catalogSongs.length})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                if (adminService.catalogSongs.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      musicProvider.playSong(
                        adminService.catalogSongs.first,
                        playlist: adminService.catalogSongs,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentColor1.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text('Play All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (adminService.isLoadingCatalog)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppTheme.accentColor1, strokeWidth: 2)),
              )
            else if (adminService.catalogSongs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF141926),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.white24),
                    SizedBox(height: 12),
                    Text('No catalog songs yet', style: TextStyle(color: Colors.white54, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Upload songs to make them available for all users',
                        style: TextStyle(color: Colors.white30, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: adminService.catalogSongs.length,
                itemBuilder: (context, index) {
                  final song = adminService.catalogSongs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141926),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: AlbumArt(
                            song: song,
                            width: 48,
                            height: 48,
                            borderRadius: BorderRadius.circular(8),
                            iconSize: 24,
                          ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${song.artist} • ${song.language}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.accentColor1, size: 28),
                            onPressed: () {
                              musicProvider.playSong(song, playlist: adminService.catalogSongs);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF453A)),
                            onPressed: () => _confirmDelete(adminService, song),
                          ),
                        ],
                      ),
                      onTap: () {
                        musicProvider.playSong(song, playlist: adminService.catalogSongs);
                      },
                    ),
                  );
                },
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker({
    required String label,
    required String? fileName,
    required IconData icon,
    required Color accentColor,
    required VoidCallback? onTap,
  }) {
    final bool hasFile = fileName != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasFile ? accentColor.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasFile ? accentColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle_rounded : icon,
              color: hasFile ? accentColor : Colors.white38,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(color: hasFile ? accentColor : Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
                  if (hasFile) ...[
                    const SizedBox(height: 2),
                    Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ] else
                    const Text('Tap to select file', style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
            Icon(hasFile ? Icons.swap_horiz : Icons.folder_open_rounded, color: hasFile ? accentColor : Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _imageFilePath != null
                ? Image.file(File(_imageFilePath!), width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderArt())
                : _placeholderArt(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preview', style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  _titleController.text.trim().isEmpty ? 'Song Title' : _titleController.text.trim(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _artistController.text.trim().isEmpty ? 'Artist' : _artistController.text.trim(),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(_audioFileName ?? '', style: const TextStyle(color: Colors.white30, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderArt() {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.music_note_rounded, color: Colors.white30, size: 28),
    );
  }
}


