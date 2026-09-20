import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'song_model.dart';
import 'catalog_api_service.dart';

class AdminService extends ChangeNotifier {
  // Admin PIN — used for both local verification and API auth header
  static const String _adminPin = '1432';
  static const String _catalogCacheKey = 'admin_catalog_cache';

  final CatalogApiService _api = CatalogApiService();

  bool _isAdminLoggedIn = false;
  bool get isAdminLoggedIn => _isAdminLoggedIn;

  List<Song> _catalogSongs = [];
  List<Song> get catalogSongs => _catalogSongs;

  bool isUploading = false;
  bool isLoadingCatalog = false;

  AdminService() {
    _init();
  }

  Future<void> _init() async {
    // Load local cache first for instant display
    await _loadCatalogCache();
    // Then fetch fresh data from API
    await fetchCatalogFromApi();
  }

  /// Verify if the given PIN matches the admin PIN.
  bool verifyPin(String pin) {
    return pin.trim() == _adminPin;
  }

  /// Set admin as logged in (session only — not persisted).
  void login() {
    _isAdminLoggedIn = true;
    notifyListeners();
  }

  /// Log out the admin.
  void logout() {
    _isAdminLoggedIn = false;
    notifyListeners();
  }

  // ── API Operations ─────────────────────────────────────────────────

  /// Fetch catalog from the remote API. Called on app start for ALL users.
  Future<void> fetchCatalogFromApi() async {
    isLoadingCatalog = true;
    notifyListeners();

    try {
      final songs = await _api.fetchCatalog();
      if (songs.isNotEmpty) {
        _catalogSongs = songs;
        await _saveCatalogCache();
      }
    } catch (e) {
      debugPrint('Error fetching catalog from API: $e');
      // Keep the local cache as fallback
    } finally {
      isLoadingCatalog = false;
      notifyListeners();
    }
  }

  /// Upload a song file to the remote API (admin only).
  Future<bool> addCatalogSong({
    required String title,
    required String artist,
    required String audioPath,
    String imagePath = '',
    String language = 'unknown',
  }) async {
    isUploading = true;
    notifyListeners();

    try {
      final newId = await _api.uploadSong(
        title: title,
        artist: artist,
        audioPath: audioPath,
        imagePath: imagePath,
        language: language,
        adminPin: _adminPin,
      );

      if (newId != null) {
        // Refresh catalog from API to get the complete song with server URLs
        await fetchCatalogFromApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error uploading song: $e');
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  /// Delete a song from the remote API (admin only).
  Future<bool> removeCatalogSong(String id) async {
    try {
      final success = await _api.deleteSong(id: id, adminPin: _adminPin);
      if (success) {
        _catalogSongs.removeWhere((s) => s.id == id);
        await _saveCatalogCache();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting song: $e');
      return false;
    }
  }

  // ── Local Cache ────────────────────────────────────────────────────

  /// Load cached catalog from SharedPreferences (offline fallback).
  Future<void> _loadCatalogCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_catalogCacheKey);
      if (data != null) {
        final List<dynamic> decoded = json.decode(data);
        _catalogSongs = decoded.map((e) => Song.fromMap(e as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading catalog cache: $e');
    }
  }

  /// Save catalog to SharedPreferences as offline cache.
  Future<void> _saveCatalogCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(_catalogSongs.map((e) => e.toJson()).toList());
      await prefs.setString(_catalogCacheKey, encoded);
    } catch (e) {
      debugPrint('Error saving catalog cache: $e');
    }
  }
}
