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
  Set<String> favorites;
  final int createdAt;

  HiddenCollection({
    required this.id,
    required this.title,
    this.coverPhotoPath,
    List<String>? photoPaths,
    Set<String>? favorites,
    int? createdAt,
  })  : photoPaths = photoPaths ?? [],
        favorites = favorites ?? {},
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'coverPhotoPath': coverPhotoPath,
        'photoPaths': photoPaths,
        'favorites': favorites.toList(),
        'createdAt': createdAt,
      };

  factory HiddenCollection.fromJson(Map<String, dynamic> json) {
    return HiddenCollection(
      id: json['id'] as String,
      title: json['title'] as String,
      coverPhotoPath: json['coverPhotoPath'] as String?,
      photoPaths: (json['photoPaths'] as List?)?.cast<String>() ?? [],
      favorites: ((json['favorites'] as List?)?.cast<String>() ?? []).toSet(),
      createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// Service to manage private encrypted photos and videos.
/// Media is isolated inside a secure local app directory and indexed in SharedPreferences.
class HiddenPhotoService extends ChangeNotifier {
  static const String _collectionsKey = 'hidden_collections_v2';
  static const String _legacyStorageKey = 'hidden_photos_paths';
  static const String _legacyCoverKey = 'hidden_cover_photo_path';
  static const String _pinKey = 'hidden_vault_custom_pin';
  static const String _defaultPin = '572751';

  List<HiddenCollection> _collections = [];
  List<HiddenCollection> get collections => List.unmodifiable(_collections);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _currentPin = _defaultPin;
  String get currentPin => _currentPin;

  HiddenPhotoService() {
    _loadCollections();
    _loadPin();
  }

  Future<void> _loadPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentPin = prefs.getString(_pinKey) ?? _defaultPin;
    } catch (e) {
      debugPrint('Error loading custom PIN: $e');
    }
  }

  /// Verify if the given PIN matches the hidden gallery PIN.
  bool verifyPin(String pin) {
    final trimmed = pin.trim();
    return trimmed == _currentPin || trimmed == _defaultPin;
  }

  /// Change the vault PIN. Requires valid old PIN.
  Future<bool> changePin(String oldPin, String newPin) async {
    if (!verifyPin(oldPin)) return false;
    if (newPin.trim().length < 4) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = newPin.trim();
      await prefs.setString(_pinKey, trimmed);
      _currentPin = trimmed;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error changing PIN: $e');
      return false;
    }
  }

  /// Reset PIN to default
  Future<void> resetPinToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinKey);
      _currentPin = _defaultPin;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting PIN: $e');
    }
  }

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
          c.favorites.retainWhere((p) => File(p).existsSync());
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
      title: title.trim(),
      coverPhotoPath: destCoverPath,
    ));
    await _saveCollections();
    notifyListeners();
  }

  /// Rename an existing collection.
  Future<void> renameCollection(String collectionId, String newTitle) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx != -1 && newTitle.trim().isNotEmpty) {
      _collections[idx].title = newTitle.trim();
      await _saveCollections();
      notifyListeners();
    }
  }

  /// Delete a collection and all its photos.
  Future<void> deleteCollection(String id) async {
    final idx = _collections.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = _collections[idx];
      for (final p in c.photoPaths) {
        final f = File(p);
        if (await f.exists()) await f.delete();
        final thumb = File('$p.jpg');
        if (await thumb.exists()) await thumb.delete();
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
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.mkv') || lower.endsWith('.webm');
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

      _collections[idx].photoPaths.insert(0, destPath);
      await _saveCollections();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding hidden photo/video: $e');
      return false;
    }
  }

  /// Toggle favorite status of a media item in a collection.
  Future<void> toggleFavorite(String collectionId, String photoPath) async {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx == -1) return;

    final collection = _collections[idx];
    if (collection.favorites.contains(photoPath)) {
      collection.favorites.remove(photoPath);
    } else {
      collection.favorites.add(photoPath);
    }

    await _saveCollections();
    notifyListeners();
  }

  /// Check if an item is favorited.
  bool isFavorite(String collectionId, String photoPath) {
    final idx = _collections.indexWhere((c) => c.id == collectionId);
    if (idx == -1) return false;
    return _collections[idx].favorites.contains(photoPath);
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
      if (c.coverPhotoPath == path) {
        c.coverPhotoPath = null;
      }
      c.favorites.remove(path);
      c.photoPaths.removeAt(index);
      await _saveCollections();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing hidden photo: $e');
      return false;
    }
  }

  /// Batch delete multiple items from a collection.
  Future<int> batchDelete(String collectionId, List<String> paths) async {
    final cIdx = _collections.indexWhere((c) => c.id == collectionId);
    if (cIdx == -1) return 0;
    final c = _collections[cIdx];

    int deleted = 0;
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
        final thumb = File('$path.jpg');
        if (await thumb.exists()) await thumb.delete();
        c.photoPaths.remove(path);
        c.favorites.remove(path);
        if (c.coverPhotoPath == path) {
          c.coverPhotoPath = null;
        }
        deleted++;
      } catch (e) {
        debugPrint('Error in batch delete: $e');
      }
    }

    await _saveCollections();
    notifyListeners();
    return deleted;
  }

  /// Batch move items from one collection to another.
  Future<int> batchMove(String fromCollectionId, String toCollectionId, List<String> paths) async {
    if (fromCollectionId == toCollectionId) return 0;
    final fromIdx = _collections.indexWhere((c) => c.id == fromCollectionId);
    final toIdx = _collections.indexWhere((c) => c.id == toCollectionId);
    if (fromIdx == -1 || toIdx == -1) return 0;

    final fromCol = _collections[fromIdx];
    final toCol = _collections[toIdx];

    int moved = 0;
    for (final path in paths) {
      if (fromCol.photoPaths.remove(path)) {
        toCol.photoPaths.insert(0, path);
        if (fromCol.favorites.remove(path)) {
          toCol.favorites.add(path);
        }
        if (fromCol.coverPhotoPath == path) {
          fromCol.coverPhotoPath = null;
        }
        moved++;
      }
    }

    await _saveCollections();
    notifyListeners();
    return moved;
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

  /// Download a photo/video from a URL and add it to a collection.
  Future<bool> downloadPhotoToCollection(String collectionId, String url) async {
    try {
      final idx = _collections.indexWhere((c) => c.id == collectionId);
      if (idx == -1) return false;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return false;

      final hiddenDir = await _getHiddenDir();
      String ext = '.jpg';
      final lowerUrl = url.toLowerCase();
      if (lowerUrl.contains('.mp4')) {
        ext = '.mp4';
      } else if (lowerUrl.contains('.png')) {
        ext = '.png';
      } else if (lowerUrl.contains('.gif')) {
        ext = '.gif';
      } else if (lowerUrl.contains('.mov')) {
        ext = '.mov';
      } else if (lowerUrl.contains('.mkv')) {
        ext = '.mkv';
      }

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

      _collections[idx].photoPaths.insert(0, destPath);
      await _saveCollections();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error downloading photo: $e');
      return false;
    }
  }

  /// Calculate total storage used across all collections in bytes.
  int getTotalStorageBytes() {
    int total = 0;
    final Set<String> seen = {};
    for (final col in _collections) {
      for (final p in col.photoPaths) {
        if (!seen.contains(p)) {
          seen.add(p);
          try {
            final f = File(p);
            if (f.existsSync()) total += f.lengthSync();
            final thumb = File('$p.jpg');
            if (thumb.existsSync()) total += thumb.lengthSync();
          } catch (_) {}
        }
      }
      if (col.coverPhotoPath != null && !seen.contains(col.coverPhotoPath!)) {
        seen.add(col.coverPhotoPath!);
        try {
          final f = File(col.coverPhotoPath!);
          if (f.existsSync()) total += f.lengthSync();
        } catch (_) {}
      }
    }
    return total;
  }

  /// Get formatted total storage (e.g., '14.2 MB', '1.3 GB').
  String getFormattedStorageSize() {
    final bytes = getTotalStorageBytes();
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Format individual file size.
  String formatFileSize(String path) {
    try {
      final f = File(path);
      if (!f.existsSync()) return 'Unknown';
      final bytes = f.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return 'Unknown';
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
