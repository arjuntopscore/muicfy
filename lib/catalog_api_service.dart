import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'song_model.dart';

/// Service that communicates with the Cloudflare Worker catalog API.
/// Handles fetching catalog (public) and uploading/deleting (admin).
class CatalogApiService {
  // ┌────────────────────────────────────────────────────────────────────┐
  // │  Your deployed Cloudflare Worker URL                              │
  // └────────────────────────────────────────────────────────────────────┘
  static const String catalogBaseUrl = 'https://music-catalog.arjunktp88.workers.dev';

  /// Fetch all catalog songs from the API. Called by all users on app start.
  Future<List<Song>> fetchCatalog() async {
    try {
      final response = await http.get(
        Uri.parse('$catalogBaseUrl/catalog'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final map = item as Map<String, dynamic>;
          final id = map['id'] as String;
          return Song(
            id: id,
            title: map['title']?.toString() ?? 'Unknown',
            artist: map['artist']?.toString() ?? 'Unknown',
            imageUrl: map['hasImage'] == true
                ? '$catalogBaseUrl/catalog/cover/$id'
                : '',
            videoId: '$catalogBaseUrl/catalog/stream/$id',
            language: map['language']?.toString() ?? 'unknown',
            isLocal: false, // streamed from the server
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching catalog: $e');
    }
    return [];
  }

  /// Upload a song file + metadata to the catalog API. Admin only.
  /// Returns the new song's ID on success, or null on failure.
  Future<String?> uploadSong({
    required String title,
    required String artist,
    required String audioPath,
    required String adminPin,
    String imagePath = '',
    String language = 'unknown',
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$catalogBaseUrl/catalog'),
      );

      request.headers['X-Admin-Pin'] = adminPin;
      request.fields['title'] = title;
      request.fields['artist'] = artist;
      request.fields['language'] = language;

      // Attach audio file
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioPath),
      );

      // Attach cover image if provided
      if (imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('cover', imagePath),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120), // generous timeout for large files
      );

      if (streamedResponse.statusCode == 200) {
        final body = await streamedResponse.stream.bytesToString();
        final data = json.decode(body);
        return data['id'] as String?;
      } else {
        final body = await streamedResponse.stream.bytesToString();
        debugPrint('Upload failed (${streamedResponse.statusCode}): $body');
      }
    } catch (e) {
      debugPrint('Error uploading song: $e');
    }
    return null;
  }

  /// Delete a catalog song by ID. Admin only.
  Future<bool> deleteSong({
    required String id,
    required String adminPin,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$catalogBaseUrl/catalog/$id'),
        headers: {'X-Admin-Pin': adminPin},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting song: $e');
      return false;
    }
  }
}
