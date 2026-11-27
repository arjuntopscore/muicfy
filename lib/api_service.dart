import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'song_model.dart';

class ApiService {
  final Map<String, String> _urlCache = {};
  
  static const String baseUrl = 'https://jiosaavn-api2.arjunktp88.workers.dev';

  Future<List<Song>> searchSongs(String query, {int limit = 20, int page = 1}) async {
    try {
      final url = Uri.parse('$baseUrl/api/search/songs?query=${Uri.encodeComponent(query)}&limit=$limit&page=$page');
      final response = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['data'] != null && data['data']['results'] != null) {
          final List items = data['data']['results'];
          if (items.isNotEmpty) {
            final List<Song> songs = [];
            for (final item in items) {
              try {
                // Filter out short clips/ringtones (< 60 seconds)
                if (item is Map && item['duration'] != null) {
                  final duration = int.tryParse(item['duration'].toString()) ?? 0;
                  if (duration > 0 && duration < 60) continue;
                }

                final song = Song.fromMap(item as Map<String, dynamic>);
                if (song.videoId.startsWith('http')) {
                  _urlCache[song.id] = song.videoId;
                }
                songs.add(song);
              } catch (e) {
                debugPrint('Error parsing an item: $e');
              }
            }
            return songs;
          }
        }
      }
    } catch (e) {
      debugPrint('Search failed: $e');
    }
    
    // Return empty list to trigger the "Couldn't reach..." message
    return [];
  }

  /// Attempts to fetch suggestions/recommendations for a song.
  /// If the endpoint returns 500 or is unavailable, returns an empty list safely.
  Future<List<Song>> getSongSuggestions(String songId, {int limit = 15}) async {
    if (songId.isEmpty) return [];
    try {
      final url = Uri.parse('$baseUrl/api/songs/$songId/suggestions?limit=$limit');
      final response = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          final dynamic rawList = data['data'];
          if (rawList is List && rawList.isNotEmpty) {
            final List<Song> songs = [];
            for (final item in rawList) {
              if (item != null && item is Map<String, dynamic>) {
                try {
                  final song = Song.fromMap(item);
                  if (song.videoId.startsWith('http')) {
                    _urlCache[song.id] = song.videoId;
                  }
                  songs.add(song);
                } catch (e) {
                  debugPrint('Error parsing suggestion: $e');
                }
              }
            }
            return songs;
          }
        }
      }
    } catch (e) {
      debugPrint('JioSaavn suggestions endpoint error: $e');
    }
    return [];
  }

  Future<String> getStreamUrl(String videoIdOrStreamUrl) async {
    // If we cached it by real ID
    if (_urlCache.containsKey(videoIdOrStreamUrl)) {
      return _urlCache[videoIdOrStreamUrl]!;
    }

    // Since our updated Song model stores the stream URL directly in videoId
    // when using this API, we can just return it if it looks like a URL.
    if (videoIdOrStreamUrl.startsWith('http')) {
      return videoIdOrStreamUrl;
    }
    
    return '';
  }

  void dispose() {
    // No resources to dispose
  }
}
