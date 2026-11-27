import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'song_model.dart';

class VideoQualityOption {
  final String label;
  final String shortLabel;
  final String videoUrl;
  final String? audioUrl;
  final bool isMuxed;
  final int height;

  VideoQualityOption({
    required this.label,
    required this.shortLabel,
    required this.videoUrl,
    this.audioUrl,
    required this.isMuxed,
    required this.height,
  });
}

class YouTubeVideoResult {
  final String videoId;
  final String streamUrl;
  final String title;
  final List<VideoQualityOption> qualities;
  final VideoQualityOption defaultQuality;

  YouTubeVideoResult({
    required this.videoId,
    required this.streamUrl,
    required this.title,
    required this.qualities,
    required this.defaultQuality,
  });
}

class _CanvasFragmentInfo {
  final int startOffset;
  final int endOffset;
  final double startSec;
  final double endSec;

  _CanvasFragmentInfo({
    required this.startOffset,
    required this.endOffset,
    required this.startSec,
    required this.endSec,
  });
}

class YoutubeVideoService {
  static final YoutubeVideoService _instance = YoutubeVideoService._internal();
  factory YoutubeVideoService() => _instance;
  YoutubeVideoService._internal();

  /// Cleans song title and artist by removing HTML entities (&quot;, &amp;, etc.),
  /// download site tags (SnapYT, y2mate, etc.), and common noise like '(From "Movie")', '[Audio]', etc.
  static String cleanMetadata(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s*\((?:from|feat|ft|official|lyric|lyrics|video)[^)]*\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'-(?:SnapYT|y2mate|ytmp3|ssyoutube|pagalworld|masstamilan)[^ ]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.(?:app|mp3|m4a|wav|aac|flac|opus)', caseSensitive: false), '')
        .replaceAll(RegExp(r'[-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Builds a deterministic slug for caching by title + artist.
  static String buildSongSlug(String title, String artist) {
    final combined = '${title}_$artist'.toLowerCase();
    return combined.replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  /// Extracts sorted multi-quality video options (1080p, 720p, 480p, 360p) and matching audio stream.
  static List<VideoQualityOption> extractQualityOptions(StreamManifest manifest) {
    // 1. Find the best AAC audio stream for video-only tracks
    String? bestAudioUrl;
    final audioStreams = manifest.audioOnly;
    if (audioStreams.isNotEmpty) {
      final mp4Audios = audioStreams.where((a) => a.container.name == 'mp4').toList();
      if (mp4Audios.isNotEmpty) {
        final bestMp4 = mp4Audios.withHighestBitrate();
        bestAudioUrl = bestMp4.url.toString();
      } else {
        final bestAudio = audioStreams.withHighestBitrate();
        bestAudioUrl = bestAudio.url.toString();
      }
    }

    final Map<int, VideoQualityOption> qualityMap = {};

    // 2. Extract video-only streams (MP4 container with H.264/avc1 codec)
    if (bestAudioUrl != null && bestAudioUrl.isNotEmpty) {
      for (final s in manifest.videoOnly) {
        if (s.container.name != 'mp4') continue;
        final label = s.videoQualityLabel.toLowerCase();

        if (label.contains('1080') && !qualityMap.containsKey(1080)) {
          qualityMap[1080] = VideoQualityOption(
            label: '1080p Full HD',
            shortLabel: '1080p',
            videoUrl: s.url.toString(),
            audioUrl: bestAudioUrl,
            isMuxed: false,
            height: 1080,
          );
        } else if (label.contains('720') && !qualityMap.containsKey(720)) {
          qualityMap[720] = VideoQualityOption(
            label: '720p HD',
            shortLabel: '720p',
            videoUrl: s.url.toString(),
            audioUrl: bestAudioUrl,
            isMuxed: false,
            height: 720,
          );
        } else if (label.contains('480') && !qualityMap.containsKey(480)) {
          qualityMap[480] = VideoQualityOption(
            label: '480p SD',
            shortLabel: '480p',
            videoUrl: s.url.toString(),
            audioUrl: bestAudioUrl,
            isMuxed: false,
            height: 480,
          );
        }
      }
    }

    // 3. Extract muxed stream (360p with audio included)
    final muxedStreams = manifest.muxed;
    if (muxedStreams.isNotEmpty) {
      final bestMuxed = muxedStreams.withHighestBitrate();
      qualityMap[360] = VideoQualityOption(
        label: '360p Data Saver',
        shortLabel: '360p',
        videoUrl: bestMuxed.url.toString(),
        audioUrl: null,
        isMuxed: true,
        height: 360,
      );
    } else {
      // Fallback: if no muxed stream, look for 360p in videoOnly if audio is available
      if (bestAudioUrl != null && bestAudioUrl.isNotEmpty) {
        for (final s in manifest.videoOnly) {
          if (s.container.name == 'mp4' && s.videoQualityLabel.toLowerCase().contains('360')) {
            qualityMap[360] = VideoQualityOption(
              label: '360p Data Saver',
              shortLabel: '360p',
              videoUrl: s.url.toString(),
              audioUrl: bestAudioUrl,
              isMuxed: false,
              height: 360,
            );
            break;
          }
        }
      }
    }

    // 4. Sort qualities descending by height (1080, 720, 480, 360)
    final sortedKeys = qualityMap.keys.toList()..sort((a, b) => b.compareTo(a));
    final List<VideoQualityOption> list = [];
    for (final k in sortedKeys) {
      final opt = qualityMap[k];
      if (opt != null) {
        list.add(opt);
      }
    }

    return list;
  }

  /// Selects the guaranteed playable default stream (muxed audio+video container)
  /// to ensure immediate playback without YouTube 403 throttling.
  static VideoQualityOption pickDefaultQuality(List<VideoQualityOption> qualities) {
    if (qualities.isEmpty) {
      throw StateError('No video qualities available');
    }
    // Guaranteed playable stream: muxed progressive MP4 (audio + video together)
    for (final q in qualities) {
      if (q.isMuxed) return q;
    }
    return qualities.first;
  }

  /// Searches YouTube using the resilient InnerTube API (used by YouTube web/mobile apps).
  /// Unlike standard web page scraping, this does not get blocked by Google Abuse/CAPTCHA redirects.
  Future<List<Map<String, String>>> _searchInnerTube(String query) async {
    try {
      final url = Uri.parse('https://www.youtube.com/youtubei/v1/search?prettyPrint=false');
      final payload = {
        'context': {
          'client': {
            'clientName': 'WEB',
            'clientVersion': '2.20231201.00.00',
            'hl': 'en',
            'gl': 'US',
          }
        },
        'query': query,
      };

      final response = await http.post(
        url,
        body: json.encode(payload),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'X-YouTube-Client-Name': '1',
          'X-YouTube-Client-Version': '2.20231201.00.00',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final dynamic decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return [];

      final List<Map<String, String>> results = [];
      final contents = decoded['contents'];
      if (contents is Map) {
        final twoCol = contents['twoColumnSearchResultsRenderer'];
        if (twoCol is Map) {
          final primary = twoCol['primaryContents'];
          if (primary is Map) {
            final sectionList = primary['sectionListRenderer'];
            if (sectionList is Map) {
              final sectionContents = sectionList['contents'];
              if (sectionContents is List) {
                for (final section in sectionContents) {
                  if (section is Map) {
                    final itemSection = section['itemSectionRenderer'];
                    if (itemSection is Map) {
                      final items = itemSection['contents'];
                      if (items is List) {
                        for (final item in items) {
                          if (item is Map) {
                            final vid = item['videoRenderer'];
                            if (vid is Map && vid['videoId'] != null) {
                              final videoId = vid['videoId'].toString();
                              String title = '';
                              final runs = vid['title'];
                              if (runs is Map && runs['runs'] is List) {
                                final runList = runs['runs'] as List;
                                title = runList.map((r) => r is Map && r['text'] != null ? r['text'].toString() : '').join();
                              }
                              results.add({'id': videoId, 'title': title});
                              if (results.length >= 5) break;
                            }
                          }
                        }
                      }
                    }
                  }
                  if (results.isNotEmpty) break;
                }
              }
            }
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint("InnerTube search error: $e");
      return [];
    }
  }

  /// Resolves the direct video stream URL and quality options for the provided song.
  Future<YouTubeVideoResult?> getVideoStream(Song song) async {
    final prefs = await SharedPreferences.getInstance();

    final cleanTitle = cleanMetadata(song.title);
    final cleanArtist = cleanMetadata(song.artist);

    // Dual-key cache lookup: check song.id and slug (title_artist)
    final cacheKeyId = 'yt_video_cache_${song.id}';
    final cacheKeySlug = 'yt_video_cache_${buildSongSlug(cleanTitle, cleanArtist)}';

    String? cachedVideoId = prefs.getString(cacheKeyId);
    if (cachedVideoId == null || cachedVideoId.isEmpty) {
      cachedVideoId = prefs.getString(cacheKeySlug);
    }

    final yt = YoutubeExplode();

    try {
      // 1. If we have a cached video ID, try resolving its stream first
      if (cachedVideoId != null && cachedVideoId.isNotEmpty) {
        try {
          final manifest = await yt.videos.streamsClient.getManifest(VideoId(cachedVideoId));
          final qualities = extractQualityOptions(manifest);
          if (qualities.isNotEmpty) {
            final defaultQuality = pickDefaultQuality(qualities);
            return YouTubeVideoResult(
              videoId: cachedVideoId,
              streamUrl: defaultQuality.videoUrl,
              title: '${song.title} - ${song.artist}',
              qualities: qualities,
              defaultQuality: defaultQuality,
            );
          }
        } catch (e) {
          debugPrint("Cached video ID $cachedVideoId failed ($e), self-healing by searching fresh...");
          // Self-heal: invalidate broken cache so song is never stuck!
          await prefs.remove(cacheKeyId);
          await prefs.remove(cacheKeySlug);
        }
      }

      // 2. Search for candidates
      final List<Map<String, String>> candidates = [];

      // Primary Search query: "<cleanTitle> <cleanArtist> official video"
      String primaryQuery = '$cleanTitle $cleanArtist official video'.trim();
      if (cleanArtist.isEmpty) {
        primaryQuery = '$cleanTitle official video';
      }

      final innerTubeResults = await _searchInnerTube(primaryQuery);
      if (innerTubeResults.isNotEmpty) {
        candidates.addAll(innerTubeResults);
      }

      // Fallback search: "<cleanTitle> <cleanArtist>" if primary was empty
      if (candidates.isEmpty) {
        final fallbackQuery = '$cleanTitle $cleanArtist'.trim();
        final fallbackResults = await _searchInnerTube(fallbackQuery);
        if (fallbackResults.isNotEmpty) {
          candidates.addAll(fallbackResults);
        }
      }

      // Secondary fallback to youtube_explode_dart search
      if (candidates.isEmpty) {
        try {
          final ytSearchResults = await yt.search.search(primaryQuery);
          for (final v in ytSearchResults) {
            candidates.add({'id': v.id.value, 'title': v.title});
            if (candidates.length >= 5) break;
          }
        } catch (e) {
          debugPrint("YoutubeExplode search fallback error: $e");
        }
      }

      if (candidates.isEmpty) {
        return null;
      }

      // 3. Iterate through candidate videos to find one with valid streams
      for (final candidate in candidates) {
        final videoId = candidate['id'];
        if (videoId == null || videoId.isEmpty) continue;

        try {
          final manifest = await yt.videos.streamsClient.getManifest(VideoId(videoId));
          final qualities = extractQualityOptions(manifest);
          if (qualities.isNotEmpty) {
            final defaultQuality = pickDefaultQuality(qualities);

            // Cache to both keys for fast future lookups
            await prefs.setString(cacheKeyId, videoId);
            await prefs.setString(cacheKeySlug, videoId);

            String videoTitle = '${song.title} - ${song.artist}';
            final candidateTitle = candidate['title'];
            if (candidateTitle != null && candidateTitle.isNotEmpty) {
              videoTitle = candidateTitle;
            }

            return YouTubeVideoResult(
              videoId: videoId,
              streamUrl: defaultQuality.videoUrl,
              title: videoTitle,
              qualities: qualities,
              defaultQuality: defaultQuality,
            );
          }
        } catch (e) {
          debugPrint("Failed to get manifest for candidate $videoId: $e");
        }
      }

      return null;
    } catch (e) {
      debugPrint("Overall YouTube video resolution error: $e");
      return null;
    } finally {
      yt.close();
    }
  }

  /// Parses the ISO BMFF `sidx` (Segment Index) box to calculate byte ranges and timestamps of fragments.
  static List<_CanvasFragmentInfo> _parseSidx(ByteData sidxData, int sidxOffset, int sidxSize) {
    final list = <_CanvasFragmentInfo>[];
    if (sidxData.lengthInBytes < 32) return list;

    final version = sidxData.getUint8(8);
    final timescale = sidxData.getUint32(16);
    if (timescale == 0) return list;

    final int countOffset = (version == 0) ? 30 : 38;
    if (sidxData.lengthInBytes < countOffset + 2) return list;

    final count = sidxData.getUint16(countOffset);
    int pos = (version == 0) ? 32 : 40;

    int currentFileOffset = sidxOffset + sidxSize;
    double currentTime = 0.0;

    for (int i = 0; i < count; i++) {
      if (pos + 12 > sidxData.lengthInBytes) break;
      final ref = sidxData.getUint32(pos);
      final size = ref & 0x7FFFFFFF;
      final dur = sidxData.getUint32(pos + 4);
      pos += 12;

      final startSec = currentTime;
      final durSec = dur / timescale;
      final endSec = startSec + durSec;
      final startOffset = currentFileOffset;
      final endOffset = currentFileOffset + size - 1;

      list.add(_CanvasFragmentInfo(
        startOffset: startOffset,
        endOffset: endOffset,
        startSec: startSec,
        endSec: endSec,
      ));

      currentFileOffset += size;
      currentTime = endSec;
    }

    return list;
  }

  /// Rewrites the ISO BMFF `tfdt` (Track Fragment Base Media Decode Time) in all fragments
  /// so the first extracted fragment starts at timestamp 0.
  /// Without this normalization, Android ExoPlayer waits 40+ seconds before playing or gets permanently stuck at 0:00!
  static void _normalizeFragmentDecodeTimes(Uint8List fragmentBytes) {
    int fragOffset = 0;
    int? firstBaseDecodeTime;
    final fragData = ByteData.sublistView(fragmentBytes);

    while (fragOffset + 8 <= fragmentBytes.length) {
      final boxSize = fragData.getUint32(fragOffset);
      if (boxSize < 8 || fragOffset + boxSize > fragmentBytes.length) break;
      final boxType = String.fromCharCodes(fragmentBytes.sublist(fragOffset + 4, fragOffset + 8));

      if (boxType == 'moof') {
        int trafOffset = fragOffset + 8;
        while (trafOffset + 8 <= fragOffset + boxSize) {
          final subSize = fragData.getUint32(trafOffset);
          if (subSize < 8 || trafOffset + subSize > fragOffset + boxSize) break;
          final subType = String.fromCharCodes(fragmentBytes.sublist(trafOffset + 4, trafOffset + 8));

          if (subType == 'traf') {
            int tfdtOffset = trafOffset + 8;
            while (tfdtOffset + 8 <= trafOffset + subSize) {
              final tSize = fragData.getUint32(tfdtOffset);
              if (tSize < 8 || tfdtOffset + tSize > trafOffset + subSize) break;
              final tType = String.fromCharCodes(fragmentBytes.sublist(tfdtOffset + 4, tfdtOffset + 8));

              if (tType == 'tfdt') {
                final tfdtVersion = fragData.getUint8(tfdtOffset + 8);
                if (tfdtVersion == 0) {
                  final currentDecodeTime = fragData.getUint32(tfdtOffset + 12);
                  if (firstBaseDecodeTime == null) {
                    firstBaseDecodeTime = currentDecodeTime;
                  }
                  final newDecodeTime = currentDecodeTime - firstBaseDecodeTime;
                  fragData.setUint32(tfdtOffset + 12, newDecodeTime);
                } else {
                  final currentDecodeTime = fragData.getUint64(tfdtOffset + 12);
                  if (firstBaseDecodeTime == null) {
                    firstBaseDecodeTime = currentDecodeTime;
                  }
                  final newDecodeTime = currentDecodeTime - firstBaseDecodeTime;
                  fragData.setUint64(tfdtOffset + 12, newDecodeTime);
                }
              }
              tfdtOffset += tSize;
            }
          }
          trafOffset += subSize;
        }
      }
      fragOffset += boxSize;
    }
  }

  /// Patches the declared duration inside `moov` (`mvhd`, `tkhd`, `mdhd`, `elst`)
  /// to match the exact duration of the extracted fragments.
  /// Without this, ExoPlayer expects the full 3-minute video, hits EOF at 9s, and halts waiting for data!
  static void _patchMoovDuration(Uint8List ftypMoov, int totalDuration) {
    final data = ByteData.sublistView(ftypMoov);
    int moovOffset = -1;
    int moovSize = 0;
    int offset = 0;
    while (offset + 8 <= ftypMoov.length) {
      final size = data.getUint32(offset);
      if (size < 8) break;
      final type = String.fromCharCodes(ftypMoov.sublist(offset + 4, offset + 8));
      if (type == 'moov') {
        moovOffset = offset;
        moovSize = size;
        break;
      }
      offset += size;
    }
    if (moovOffset == -1) return;

    void patchBox(int start, int length) {
      int o = start;
      while (o + 8 <= start + length) {
        final size = data.getUint32(o);
        if (size < 8 || o + size > start + length) break;
        final type = String.fromCharCodes(ftypMoov.sublist(o + 4, o + 8));

        if (type == 'mvhd') {
          final v = data.getUint8(o + 8);
          if (v == 0) {
            data.setUint32(o + 24, totalDuration);
          } else {
            data.setUint64(o + 32, totalDuration);
          }
        } else if (type == 'tkhd') {
          final v = data.getUint8(o + 8);
          if (v == 0) {
            data.setUint32(o + 28, totalDuration);
          } else {
            data.setUint64(o + 36, totalDuration);
          }
        } else if (type == 'mdhd') {
          final v = data.getUint8(o + 8);
          if (v == 0) {
            data.setUint32(o + 24, totalDuration);
          } else {
            data.setUint64(o + 32, totalDuration);
          }
        } else if (type == 'elst') {
          final v = data.getUint8(o + 8);
          final entryCount = data.getUint32(o + 12);
          if (entryCount > 0) {
            if (v == 0) {
              data.setUint32(o + 16, totalDuration);
              data.setInt32(o + 20, 0); // mediaTime = 0
            } else {
              data.setUint64(o + 16, totalDuration);
              data.setInt64(o + 24, 0);
            }
          }
        } else if (type == 'trak' || type == 'mdia' || type == 'edts' || type == 'minf') {
          patchBox(o + 8, size - 8);
        }
        o += size;
      }
    }

    patchBox(moovOffset + 8, moovSize - 8);
  }

  /// Builds a minimal valid `sidx` box referencing only the extracted fragments.
  /// This is essential: ExoPlayer's FragmentedMp4Extractor needs a sidx to build
  /// its seek map during preparation, otherwise ProgressiveMediaPeriod throws
  /// "Loading finished before preparation is complete" and the video freezes.
  static Uint8List _buildMinimalSidx(
    int timescale,
    List<int> fragmentSizes,
    List<int> fragmentDurations,
    int firstFragmentFileOffset,
  ) {
    final int referenceCount = fragmentSizes.length;
    // sidx version 0: 8(header) + 4(version+flags) + 4(referenceId) + 4(timescale)
    // + 4(earliestPTS) + 4(firstOffset) + 2(reserved) + 2(referenceCount) + 12*N(entries)
    final int boxSize = 32 + (12 * referenceCount);
    final buf = Uint8List(boxSize);
    final bd = ByteData.sublistView(buf);

    bd.setUint32(0, boxSize); // box size
    buf[4] = 0x73; buf[5] = 0x69; buf[6] = 0x64; buf[7] = 0x78; // 'sidx'
    bd.setUint32(8, 0); // version 0 + flags
    bd.setUint32(12, 1); // reference_id = 1 (track 1)
    bd.setUint32(16, timescale);
    bd.setUint32(20, 0); // earliest_presentation_time = 0
    bd.setUint32(24, 0); // first_offset = 0 (fragments immediately follow sidx)
    bd.setUint16(28, 0); // reserved
    bd.setUint16(30, referenceCount);

    int pos = 32;
    for (int i = 0; i < referenceCount; i++) {
      bd.setUint32(pos, fragmentSizes[i] & 0x7FFFFFFF); // reference_type=0 + size
      bd.setUint32(pos + 4, fragmentDurations[i]);
      bd.setUint32(pos + 8, 0x90000000); // starts_with_SAP=1, SAP_type=1
      pos += 12;
    }
    return buf;
  }

  /// Scans fragment bytes (moof+mdat pairs) and returns lists of sizes and
  /// durations (in timescale units) for each fragment, to build a valid sidx.
  static Map<String, List<int>> _analyzeFragments(Uint8List fragmentBytes, int timescale) {
    final sizes = <int>[];
    final durations = <int>[];
    final fragData = ByteData.sublistView(fragmentBytes);

    int pos = 0;
    while (pos + 8 <= fragmentBytes.length) {
      final moofSize = fragData.getUint32(pos);
      if (moofSize < 8 || pos + moofSize > fragmentBytes.length) break;
      final moofType = String.fromCharCodes(fragmentBytes.sublist(pos + 4, pos + 8));
      if (moofType != 'moof') break;

      // Find trun inside moof -> traf to get sample count and durations
      int fragmentDuration = 0;
      int trafOff = pos + 8;
      while (trafOff + 8 <= pos + moofSize) {
        final subSize = fragData.getUint32(trafOff);
        if (subSize < 8 || trafOff + subSize > pos + moofSize) break;
        final subType = String.fromCharCodes(fragmentBytes.sublist(trafOff + 4, trafOff + 8));
        if (subType == 'traf') {
          int innerOff = trafOff + 8;
          int defaultSampleDuration = 0;
          // First pass: get tfhd default_sample_duration
          while (innerOff + 8 <= trafOff + subSize) {
            final iSize = fragData.getUint32(innerOff);
            if (iSize < 8 || innerOff + iSize > trafOff + subSize) break;
            final iType = String.fromCharCodes(fragmentBytes.sublist(innerOff + 4, innerOff + 8));
            if (iType == 'tfhd') {
              final tfhdFlags = fragData.getUint32(innerOff + 8) & 0xFFFFFF;
              int tfhdPos = innerOff + 12 + 4; // skip version+flags + track_id
              if (tfhdFlags & 0x000001 != 0) tfhdPos += 8; // base_data_offset
              if (tfhdFlags & 0x000002 != 0) tfhdPos += 4; // sample_description_index
              if (tfhdFlags & 0x000008 != 0) {
                if (tfhdPos + 4 <= innerOff + iSize) {
                  defaultSampleDuration = fragData.getUint32(tfhdPos);
                }
              }
            }
            innerOff += iSize;
          }
          // Second pass: get trun to calculate total duration
          innerOff = trafOff + 8;
          while (innerOff + 8 <= trafOff + subSize) {
            final iSize = fragData.getUint32(innerOff);
            if (iSize < 8 || innerOff + iSize > trafOff + subSize) break;
            final iType = String.fromCharCodes(fragmentBytes.sublist(innerOff + 4, innerOff + 8));
            if (iType == 'trun') {
              final trunFlags = fragData.getUint32(innerOff + 8) & 0xFFFFFF;
              final sampleCount = fragData.getUint32(innerOff + 12);
              final hasDuration = (trunFlags & 0x000100) != 0;
              final hasSize = (trunFlags & 0x000200) != 0;
              final hasFlags = (trunFlags & 0x000400) != 0;
              final hasCTO = (trunFlags & 0x000800) != 0;

              int samplePos = innerOff + 16;
              if (trunFlags & 0x000001 != 0) samplePos += 4; // data_offset
              if (trunFlags & 0x000004 != 0) samplePos += 4; // first_sample_flags

              for (int s = 0; s < sampleCount; s++) {
                int dur = defaultSampleDuration;
                if (hasDuration) {
                  if (samplePos + 4 <= innerOff + iSize) {
                    dur = fragData.getUint32(samplePos);
                  }
                  samplePos += 4;
                }
                if (hasSize) samplePos += 4;
                if (hasFlags) samplePos += 4;
                if (hasCTO) samplePos += 4;
                fragmentDuration += dur;
              }
            }
            innerOff += iSize;
          }
        }
        trafOff += subSize;
      }

      // Now find the mdat that follows this moof
      final mdatPos = pos + moofSize;
      if (mdatPos + 8 > fragmentBytes.length) break;
      final mdatSize = fragData.getUint32(mdatPos);
      if (mdatSize < 8) break;

      final totalFragSize = moofSize + mdatSize;
      sizes.add(totalFragSize);
      durations.add(fragmentDuration > 0 ? fragmentDuration : (timescale * 5)); // fallback 5s

      pos = mdatPos + mdatSize;
    }

    return {'sizes': sizes, 'durations': durations};
  }

  /// Downloads a high-definition 1080p canvas loop clip (~10 seconds)
  /// specifically extracted from the chorus/highlight scene (skipping intro movie titles & statutory warnings)
  /// and caches it locally so it loops seamlessly at 60fps with zero buffering or 403 blocks.
  Future<File?> get1080pCanvasClip(Song song) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final safeId = song.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final cacheKey = 'canvas_v6_1080_$safeId.mp4';
      final file = File('${tempDir.path}/$cacheKey');

      // Return immediately if already cached locally
      if (await file.exists()) {
        final length = await file.length();
        if (length > 500000) {
          return file;
        }
      }

      // Purge any older canvas cache files
      try {
        for (final prefix in ['canvas_1080_', 'canvas_chorus_1080_', 'canvas_v3_1080_', 'canvas_v4_1080_', 'canvas_v5_1080_']) {
          final oldFile = File('${tempDir.path}/$prefix$safeId.mp4');
          if (await oldFile.exists()) await oldFile.delete();
        }
      } catch (_) {}

      // Resolve YouTube video
      final videoResult = await getVideoStream(song);
      if (videoResult == null) return null;

      final yt = YoutubeExplode();
      try {
        final manifest = await yt.videos.streamsClient.getManifest(VideoId(videoResult.videoId));

        // Find 1080p Full HD MP4 video stream (or 720p/480p fallback)
        VideoStreamInfo? targetStream;
        for (final s in manifest.videoOnly) {
          if (s.container.name == 'mp4' && s.videoQualityLabel.contains('1080')) {
            targetStream = s;
            break;
          }
        }
        if (targetStream == null) {
          for (final s in manifest.videoOnly) {
            if (s.container.name == 'mp4' && s.videoQualityLabel.contains('720')) {
              targetStream = s;
              break;
            }
          }
        }
        if (targetStream == null) {
          for (final s in manifest.videoOnly) {
            if (s.container.name == 'mp4' && s.videoQualityLabel.contains('480')) {
              targetStream = s;
              break;
            }
          }
        }
        if (targetStream == null) return null;

        // Fetch initial header (first 16KB to handle large moov boxes)
        final headerRes = await http.get(
          targetStream.url,
          headers: {'Range': 'bytes=0-16383'},
        ).timeout(const Duration(seconds: 10));

        if (headerRes.statusCode != 206 && headerRes.statusCode != 200) {
          return null;
        }

        Uint8List initialBytes = headerRes.bodyBytes;
        ByteData data = ByteData.sublistView(initialBytes);

        // Scan top-level box headers to find moov end and sidx
        int moovEnd = 0;
        int sidxOffset = -1;
        int sidxSize = 0;
        int offset = 0;
        while (offset + 8 <= initialBytes.length) {
          final boxSize = data.getUint32(offset);
          if (boxSize < 8) break;
          final boxType = String.fromCharCodes(initialBytes.sublist(offset + 4, offset + 8));
          if (boxType == 'moov') {
            moovEnd = offset + boxSize;
            // If moov extends beyond our initial fetch, re-download with enough bytes
            if (moovEnd > initialBytes.length) {
              final bigHeaderRes = await http.get(
                targetStream.url,
                headers: {'Range': 'bytes=0-${moovEnd + 4096}'},
              ).timeout(const Duration(seconds: 12));
              if (bigHeaderRes.statusCode != 206 && bigHeaderRes.statusCode != 200) {
                return null;
              }
              initialBytes = bigHeaderRes.bodyBytes;
              data = ByteData.sublistView(initialBytes);
              // Continue scanning from after moov
            }
          }
          if (boxType == 'sidx') {
            sidxOffset = offset;
            sidxSize = boxSize;
            break;
          }
          offset += boxSize;
        }

        if (sidxOffset == -1) {
          // Fallback if sidx box is not found
          const fallbackEnd = 3637082;
          final fallbackRes = await http.get(
            targetStream.url,
            headers: {'Range': 'bytes=0-$fallbackEnd'},
          ).timeout(const Duration(seconds: 12));
          if (fallbackRes.statusCode == 206 || fallbackRes.statusCode == 200) {
            await file.writeAsBytes(fallbackRes.bodyBytes);
            return file;
          }
          return null;
        }

        // ftyp + moov initialization block (everything before sidx)
        final ftypMoov = initialBytes.sublist(0, sidxOffset);

        ByteData sidxData;
        if (sidxOffset + sidxSize <= initialBytes.length) {
          sidxData = ByteData.sublistView(initialBytes, sidxOffset, sidxOffset + sidxSize);
        } else {
          final sidxRes = await http.get(
            targetStream.url,
            headers: {'Range': 'bytes=$sidxOffset-${sidxOffset + sidxSize - 1}'},
          ).timeout(const Duration(seconds: 8));
          if (sidxRes.statusCode != 206 && sidxRes.statusCode != 200) {
            return null;
          }
          sidxData = ByteData.sublistView(sidxRes.bodyBytes);
        }

        final timescale = sidxData.getUint32(16) > 0 ? sidxData.getUint32(16) : 12288;
        final fragments = _parseSidx(sidxData, sidxOffset, sidxSize);
        if (fragments.isEmpty) return null;

        final totalDuration = fragments.last.endSec;
        // Skips intro statutory warnings, logos & title cards; targets the chorus/dance scene (~40s)
        final double targetTime = (totalDuration > 60.0) ? 40.0 : (totalDuration * 0.35);

        int targetStartByte = 0;
        int targetEndByte = 0;
        double clipStart = 0;
        double clipEnd = 0;

        for (final f in fragments) {
          if (f.startSec >= targetTime && targetStartByte == 0) {
            targetStartByte = f.startOffset;
            clipStart = f.startSec;
          }
          if (targetStartByte != 0 && f.endSec >= clipStart + 8.0) {
            targetEndByte = f.endOffset;
            clipEnd = f.endSec;
            break;
          }
        }

        if (targetStartByte == 0) {
          final fallbackIdx = (fragments.length * 0.35).floor().clamp(0, fragments.length - 1);
          targetStartByte = fragments[fallbackIdx].startOffset;
          targetEndByte = fragments[fallbackIdx].endOffset;
          clipStart = fragments[fallbackIdx].startSec;
          clipEnd = fragments[fallbackIdx].endSec;
        } else if (targetEndByte == 0) {
          targetEndByte = fragments.last.endOffset;
          clipEnd = fragments.last.endSec;
        }

        final double totalClipDurationSec = (clipEnd > clipStart) ? (clipEnd - clipStart) : 8.0;
        final int totalDurationUnits = (totalClipDurationSec * timescale).round();

        final clipRes = await http.get(
          targetStream.url,
          headers: {'Range': 'bytes=$targetStartByte-$targetEndByte'},
        ).timeout(const Duration(seconds: 15));

        if (clipRes.statusCode == 206 || clipRes.statusCode == 200) {
          final ftypMoovCopy = Uint8List.fromList(ftypMoov);
          _patchMoovDuration(ftypMoovCopy, totalDurationUnits);

          final fragmentBytes = Uint8List.fromList(clipRes.bodyBytes);
          _normalizeFragmentDecodeTimes(fragmentBytes);

          // Analyze fragments to build a proper sidx for ExoPlayer
          final fragInfo = _analyzeFragments(fragmentBytes, timescale);
          final fragSizes = fragInfo['sizes'];
          final fragDurations = fragInfo['durations'];

          final builder = BytesBuilder(copy: false);
          builder.add(ftypMoovCopy);

          if (fragSizes != null && fragSizes.isNotEmpty && fragDurations != null && fragDurations.isNotEmpty) {
            // Build a valid sidx pointing to our extracted fragments
            final newSidx = _buildMinimalSidx(
              timescale,
              fragSizes,
              fragDurations,
              ftypMoovCopy.length, // offset where sidx ends and fragments begin
            );
            builder.add(newSidx);
          }

          builder.add(fragmentBytes);
          await file.writeAsBytes(builder.toBytes());
          return file;
        }
      } finally {
        yt.close();
      }
      return null;
    } catch (e) {
      debugPrint("get1080pCanvasClip error: $e");
      return null;
    }
  }
}
