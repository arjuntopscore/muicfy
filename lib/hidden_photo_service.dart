import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';

class HiddenCollection {
  final String id;
  String title;
  String? coverPhotoPath;
  List<String> photoPaths;

  HiddenCollection({
    required this.id,
    required this.title,
    this.coverPhotoPath,
    List<String>? photoPaths,
  }) : photoPaths = photoPaths ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'coverPhotoPath': coverPhotoPath,
        'photoPaths': photoPaths,
      };

  factory HiddenCollection.fromJson(Map<String, dynamic> json) {
    return HiddenCollection(
      id: json['id'] as String,
      title: json['title'] as String,
      coverPhotoPath: json['coverPhotoPath'] as String?,
      photoPaths: (json['photoPaths'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Service to manage hidden photos.
/// Photos are copied into a private app directory and paths stored in SharedPreferences.
class HiddenPhotoService extends ChangeNotifier {
  static const String _collectionsKey = 'hidden_collections_v2';
  static const String _legacyStorageKey = 'hidden_photos_paths';
  static const String _legacyCoverKey = 'hidden_cover_photo_path';
  static const String _hiddenPin = '572751';

  List<HiddenCollection> _collections = [];
  List<HiddenCollection> get collections => List.unmodifiable(_collections);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  HiddenPhotoService() {
    _loadCollections();
  }

  /// Verify if the given PIN matches the hidden gallery PIN.
  bool verifyPin(String pin) => pin.trim() == _hiddenPin;

  /// Load saved collections from SharedPreferences.
  Future<void> _loadCollections() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_collectionsKey);
      
      if (data != null) {
        final List<dynamic> decoded = json.decode(data);
        _collections = decoded.map((e) => HiddenCollection.fromJson(e)).toList();
        
        // Remove missing photos
        for (var c in _collections) {
          c.photoPaths.retainWhere((p) => File(p).existsSync());
          if (c.coverPhotoPath != null && !File(c.coverPhotoPath!).existsSync()) {
            c.coverPhotoPath = null;
          }
        }
      } else {
        // Migration from old schema
        final oldData = prefs.getString(_legacyStorageKey);
        if (oldData != null) {
          final List<dynamic> decoded = json.decode(oldData);
          final paths = decoded.cast<String>().where((p) => File(p).existsSync()).toList();
          String? cover = prefs.getString(_legacyCoverKey);
          if (cover != null && !File(cover).existsSync()) cover = null;
          
          if (paths.isNotEmpty || cover != null) {
            _collections.add(HiddenCollection(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Keerthy Suresh',
              coverPhotoPath: cover,
              photoPaths: paths,
            ));
            await _saveCollections();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading hidden collections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new collection.
  Future<void> createCollection(String title, [String? coverPath]) async {
    String? destCoverPath;
    if (coverPath != null) {
      final hiddenDir = await _getHiddenDir();
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}_${coverPath.split(Platform.pathSeparator).last}';
      destCoverPath = '${hiddenDir.path}${Platform.pathSeparator}$fileName';
      await File(coverPath).copy(destCoverPath);
    }
    
    _collections.add(HiddenCollection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      coverPhotoPath: destCoverPath,
    ));
    await _saveCollections();
    notifyListeners();
  }

  /// Delete a collection and all its photos.
  Future<void> deleteCollection(String id) async {
    final idx = _collections.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = _collections[idx];
      for (final p in c.photoPaths) {
        final f = File(p);
        if (await f.exists()) await f.delete();
      }
      if (c.coverPhotoPath != null) {
        final f = File(c.coverPhotoPath!);
        if (await f.exists()) await f.delete();
      }
      _collections.removeAt(idx);
      await _saveCollections();
      notifyListeners();
    }
  }

  bool isVideo(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.mkv');
  }

  /// Add a photo or video to a specific collection.
  Future<bool> addPhotoToCollection(String collectionId, String sourcePath) async {
    try {
      final idx = _collections.indexWhere((c) => c.id == collectionId);
      if (idx == -1) return false;

      final hiddenDir = await _getHiddenDir();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${sourcePath.split(Platform.pathSeparator).last}';
      final destPath = '${hiddenDir.path}${Platform.pathSeparator}$fileName';

      await File(sourcePath).copy(destPath);

      if (isVideo(destPath)) {
        try {
          final plugin = FcNativeVideoThumbnail();
          await plugin.saveThumbnailToFile(
            srcFile: destPath,
            destFile: '$destPath.jpg',
            width: 400,
            height: 400,
            format: 'jpeg',
            quality: 75,
          );
        } catch (e) {
          debugPrint('Could not generate thumbnail: $e');
        }
      }

      _collections[idx].photoPaths.add(destPath);
      await _saveCollections();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding hidden photo/video: $e');
      return false;
    }
  }

  /// Remove a photo from a collection by index.
  Future<bool> removePhotoFromCollection(String collectionId, int index) async {
    final cIdx = _collections.indexWhere((c) => c.id == collectionId);
    if (cIdx == -1) return false;
    final c = _collections[cIdx];
    
    if (index < 0 || index >= c.photoPaths.length) return false;
    try {
      final path = c.photoPaths[index];
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      final thumbFile = File('$path.jpg');
      if (await thumbFile.exists()) {
        await thumbFile.delete();
      }
      // If this was the cover photo, clear it
      if (c.coverPhotoPath == path) {
        c.coverPhotoPath = null;
      }
      c.photoPaths.removeAt(index);
      await _saveCollections();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing hidden photo: $e');
      return false;
    }
  }

  /// Set a photo as the cover picture for a collection.
  Future<void> setCollectionCover(String collectionId, String path) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx != -1) {
      _collections[idx].coverPhotoPath = path;
      await _saveCollections();
      notifyListeners();
    }
  }

  /// Save collections to SharedPreferences.
  Future<void> _saveCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_collectionsKey, json.encode(_collections.map((c) => c.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving hidden collections: $e');
    }
  }

  /// Download a photo from a URL and add it to a collection.
  Future<bool> downloadPhotoToCollection(String collectionId, String url) async {
    try {
      final idx = _collections.indexWhere((c) => c.id == collectionId);
      if (idx == -1) return false;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return false;

      final hiddenDir = await _getHiddenDir();
      String ext = '.jpg';
      final lowerUrl = url.toLowerCase();
      if (lowerUrl.endsWith('.mp4')) ext = '.mp4';
      if (lowerUrl.endsWith('.png')) ext = '.png';
      if (lowerUrl.endsWith('.gif')) ext = '.gif';
      if (lowerUrl.endsWith('.mov')) ext = '.mov';
      if (lowerUrl.endsWith('.mkv')) ext = '.mkv';

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_downloaded$ext';
      final destPath = '${hiddenDir.path}${Platform.pathSeparator}$fileName';

      final file = File(destPath);
      await file.writeAsBytes(response.bodyBytes);

      if (isVideo(destPath)) {
        try {
          final plugin = FcNativeVideoThumbnail();
          await plugin.saveThumbnailToFile(
            srcFile: destPath,
            destFile: '$destPath.jpg',
            width: 400,
            height: 400,
            format: 'jpeg',
            quality: 75,
          );
        } catch (e) {
          debugPrint('Could not generate thumbnail for downloaded video: $e');
        }
      }

      _collections[idx].photoPaths.add(destPath);
      await _saveCollections();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error downloading photo: $e');
      return false;
    }
  }

  /// Get (or create) the hidden directory inside app documents.
  Future<Directory> _getHiddenDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final hiddenDir = Directory('${appDir.path}${Platform.pathSeparator}.hidden_vault');
    if (!await hiddenDir.exists()) {
      await hiddenDir.create(recursive: true);
    }
    return hiddenDir;
  }
}
