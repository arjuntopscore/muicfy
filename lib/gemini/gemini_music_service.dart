import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import 'models/semantic_song_match.dart';
import 'models/vibe_playlist.dart';

/// Custom exception for Gemini music operations.
class GeminiMusicException implements Exception {
  final String message;
  final dynamic cause;

  GeminiMusicException(this.message, [this.cause]);

  @override
  String toString() =>
      cause != null ? 'GeminiMusicException: $message (Cause: $cause)' : 'GeminiMusicException: $message';
}

/// Service class interfacing with the Google Gemini API to power AI music features.
class GeminiMusicService {
  final String apiKey;
  String defaultModel;

  /// Ordered list of production models to try if the primary model is retired/not found.
  static const List<String> candidateModels = [
    'gemini-2.0-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-pro',
    'gemini-pro',
  ];

  GeminiMusicService({
    required this.apiKey,
    this.defaultModel = 'gemini-2.0-flash',
  });

  /// Dynamically queries Google Generative Language API for the active models supported by the key.
  static Future<List<String>> fetchSupportedModels(String key) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) return [];

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$cleanKey');
      final res = await http.get(url).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['models'] is List) {
          final List models = data['models'];
          final supported = <String>[];
          for (final m in models) {
            final methods = m['supportedGenerationMethods'];
            if (methods is List && methods.contains('generateContent')) {
              String name = m['name'] ?? '';
              if (name.startsWith('models/')) {
                name = name.substring('models/'.length);
              }
              if (name.isNotEmpty) supported.add(name);
            }
          }
          return supported;
        }
      }
    } catch (_) {}
    return [];
  }

  // ---------------------------------------------------------------------------
  // Feature 1: Vibe-Based Playlist Generator
  // ---------------------------------------------------------------------------

  /// Generates a curated playlist based on a user's natural language vibe prompt.
  Future<VibePlaylist> generateVibePlaylist(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      throw GeminiMusicException('Please enter a description or vibe for your playlist.');
    }

    final effectiveKey = apiKey.trim();
    if (effectiveKey.isEmpty) {
      throw GeminiMusicException(
        'Gemini API key is not configured. Tap the Key icon (🔑) in the top right to paste your free API key from aistudio.google.com.',
      );
    }

    // Schema enforcing strict JSON array of songs
    final vibeSongSchema = Schema.object(
      description: 'A music track recommendation matching the requested vibe.',
      properties: {
        'title': Schema.string(description: 'Title of the track'),
        'artist': Schema.string(description: 'Name of the recording artist or band'),
        'album': Schema.string(description: 'Album the song belongs to'),
        'genre': Schema.string(description: 'Primary genre or subgenre'),
        'durationInSeconds': Schema.integer(
          description: 'Track length in seconds (typically between 120 and 360 seconds)',
        ),
      },
      requiredProperties: ['title', 'artist', 'album', 'genre', 'durationInSeconds'],
    );

    final playlistSchema = Schema.array(
      description: 'A list of curated songs matching the requested vibe and target duration.',
      items: vibeSongSchema,
    );

    // Build the ordered model candidates to try
    final modelsToTry = <String>[
      defaultModel,
      ...candidateModels.where((m) => m != defaultModel),
    ];

    GenerativeAIException? lastAIException;

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: effectiveKey,
          systemInstruction: Content.system(
            'You are an expert music curator, DJ, and musicologist. Your task is to craft '
            'cohesive, high-quality playlists tailored to the user\'s specific vibe, mood, activity, '
            'or target duration.\n\n'
            'Guidelines:\n'
            '1. If the user specifies a time constraint (e.g., 45 minutes, 1 hour), select songs whose '
            'cumulative duration in seconds closely matches the requested duration.\n'
            '2. Choose real, existing songs by recognizable artists that fit the aesthetic.\n'
            '3. Provide accurate estimated durations in seconds for each track.\n'
            '4. You MUST respond with ONLY a strict JSON array conforming to the output schema.',
          ),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: playlistSchema,
            temperature: 0.7,
          ),
        );

        final response = await model.generateContent([Content.text(cleanPrompt)]);
        final responseText = response.text;

        if (responseText == null || responseText.trim().isEmpty) {
          throw GeminiMusicException('No playlist was returned by the AI. Please try again.');
        }

        final dynamic decoded = _decodeJsonStrict(responseText);
        if (decoded is! List) {
          throw GeminiMusicException('Unexpected response format: expected a JSON array.');
        }

        final songs = decoded
            .map((item) => VibeSong.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();

        // Model succeeded: remember it for future calls
        defaultModel = modelName;
        return VibePlaylist(prompt: cleanPrompt, songs: songs);
      } on GenerativeAIException catch (e) {
        lastAIException = e;
        final msg = e.message.toLowerCase();
        // If model not found or not supported, try the next model candidate
        if (msg.contains('not found') || msg.contains('not supported') || msg.contains('404')) {
          continue;
        }
        if (msg.contains('permission') || msg.contains('403') || msg.contains('not have permission')) {
          throw GeminiMusicException(
            'Gemini API Permission Denied (HTTP 403).\n\n'
            'Common fixes:\n'
            '• Your API key may be invalid, restricted, or expired. Tap the Key icon (🔑) in the top right to update it.\n'
            '• Ensure the "Generative Language API" is enabled for your key in Google AI Studio / Google Cloud.\n'
            '• Disable VPN if active (Google may restrict requests from certain IP blocks).',
            e,
          );
        }
        throw GeminiMusicException('Gemini API error: ${e.message}', e);
      } on SocketException catch (e) {
        throw GeminiMusicException('Network error: Unable to reach Gemini API. Please check your connection.', e);
      } on http.ClientException catch (e) {
        throw GeminiMusicException('HTTP connection error: ${e.message}', e);
      } on FormatException catch (e) {
        throw GeminiMusicException('Failed to parse AI response into valid JSON: ${e.message}', e);
      } catch (e) {
        if (e is GeminiMusicException) rethrow;
        throw GeminiMusicException('An unexpected error occurred while generating the playlist.', e);
      }
    }

    if (lastAIException != null) {
      throw GeminiMusicException('Gemini API error: ${lastAIException.message}', lastAIException);
    }
    throw GeminiMusicException('Unable to generate playlist. Please try again.');
  }

  // ---------------------------------------------------------------------------
  // Feature 2: Semantic Audio Search
  // ---------------------------------------------------------------------------

  /// Searches for songs using vague, descriptive queries or pop culture references.
  Future<List<SemanticSongMatch>> searchByDescription(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      throw GeminiMusicException('Please enter a song description to search.');
    }

    final effectiveKey = apiKey.trim();
    if (effectiveKey.isEmpty) {
      throw GeminiMusicException(
        'Gemini API key is not configured. Tap the Key icon (🔑) in the top right to paste your free API key from aistudio.google.com.',
      );
    }

    // Schema enforcing strict JSON array of top 3 matches
    final searchResultSchema = Schema.object(
      description: 'A candidate song match with justification.',
      properties: {
        'title': Schema.string(description: 'Title of the song'),
        'artist': Schema.string(description: 'Name of the recording artist or band'),
        'album': Schema.string(description: 'Album on which the song was released'),
        'releaseYear': Schema.string(description: 'Year the track was released, e.g. "1999"'),
        'matchReason': Schema.string(
          description: 'A concise explanation explaining why this song matches the user\'s vague description or scene',
        ),
      },
      requiredProperties: ['title', 'artist', 'album', 'releaseYear', 'matchReason'],
    );

    final topMatchesSchema = Schema.array(
      description: 'Top 3 most probable songs matching the description.',
      items: searchResultSchema,
    );

    // Build ordered model candidates to try
    final modelsToTry = <String>[
      defaultModel,
      ...candidateModels.where((m) => m != defaultModel),
    ];

    GenerativeAIException? lastAIException;

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: effectiveKey,
          systemInstruction: Content.system(
            'You are an encyclopedic music detective and audio expert. Your task is to identify '
            'exact song matches from vague musical descriptions, lyrical fragments, sound textures, '
            'memorable basslines/synths/riffs, movie soundtracks, TV scenes, or cultural references.\n\n'
            'Guidelines:\n'
            '1. Return the top 3 most likely song matches ranked by likelihood.\n'
            '2. In "matchReason", explain clearly and concisely why this song matches the user\'s clues '
            '(e.g., mention the scene in Fight Club, the specific synthesizer used, or famous bassline hook).\n'
            '3. You MUST respond with ONLY a strict JSON array conforming to the output schema.',
          ),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: topMatchesSchema,
            temperature: 0.3,
          ),
        );

        final response = await model.generateContent([
          Content.text('Identify the top 3 song matches for this description:\n"$cleanQuery"'),
        ]);
        final responseText = response.text;

        if (responseText == null || responseText.trim().isEmpty) {
          throw GeminiMusicException('No matches found for that description.');
        }

        final dynamic decoded = _decodeJsonStrict(responseText);
        if (decoded is! List) {
          throw GeminiMusicException('Unexpected response format: expected a JSON array.');
        }

        defaultModel = modelName;
        return decoded
            .map((item) => SemanticSongMatch.fromJson(Map<String, dynamic>.from(item as Map)))
            .take(3)
            .toList();
      } on GenerativeAIException catch (e) {
        lastAIException = e;
        final msg = e.message.toLowerCase();
        // If model not found or not supported, try the next model candidate
        if (msg.contains('not found') || msg.contains('not supported') || msg.contains('404')) {
          continue;
        }
        if (msg.contains('permission') || msg.contains('403') || msg.contains('not have permission')) {
          throw GeminiMusicException(
            'Gemini API Permission Denied (HTTP 403).\n\n'
            'Common fixes:\n'
            '• Your API key may be invalid, restricted, or expired. Tap the Key icon (🔑) in the top right to update it.\n'
            '• Ensure the "Generative Language API" is enabled for your key in Google AI Studio / Google Cloud.\n'
            '• Disable VPN if active (Google may restrict requests from certain IP blocks).',
            e,
          );
        }
        throw GeminiMusicException('Gemini API error: ${e.message}', e);
      } on SocketException catch (e) {
        throw GeminiMusicException('Network error: Unable to reach Gemini API. Please check your connection.', e);
      } on http.ClientException catch (e) {
        throw GeminiMusicException('HTTP connection error: ${e.message}', e);
      } on FormatException catch (e) {
        throw GeminiMusicException('Failed to parse AI response into valid JSON: ${e.message}', e);
      } catch (e) {
        if (e is GeminiMusicException) rethrow;
        throw GeminiMusicException('An unexpected error occurred during semantic search.', e);
      }
    }

    if (lastAIException != null) {
      throw GeminiMusicException('Gemini API error: ${lastAIException.message}', lastAIException);
    }
    throw GeminiMusicException('Unable to find matches. Please try again.');
  }

  // ---------------------------------------------------------------------------
  // Helper: Resilient JSON Cleaner and Decoder
  // ---------------------------------------------------------------------------

  /// Strips potential markdown code blocks and decodes JSON safely.
  dynamic _decodeJsonStrict(String text) {
    var sanitized = text.trim();

    // Defensive check: strip leading and trailing ```json ... ``` if present
    if (sanitized.startsWith('```')) {
      final firstNewline = sanitized.indexOf('\n');
      final lastBackticks = sanitized.lastIndexOf('```');
      if (firstNewline != -1 && lastBackticks > firstNewline) {
        sanitized = sanitized.substring(firstNewline + 1, lastBackticks).trim();
      }
    }

    return jsonDecode(sanitized);
  }
}
