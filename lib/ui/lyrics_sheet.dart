import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';
import 'apple_music_widgets.dart';

class LyricsSheet extends StatefulWidget {
  final Song song;
  final ScrollController scrollController;

  const LyricsSheet({
    super.key,
    required this.song,
    required this.scrollController,
  });

  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, scrollController) => LyricsSheet(
          song: song,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _lyrics;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fetchLyrics();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'(?i)feat\..*'), '')
        .replaceAll(RegExp(r'(?i)ft\..*'), '')
        .trim();
  }

  Future<void> _fetchLyrics() async {
    final cleanTitle = _cleanTitle(widget.song.title);
    final artist = widget.song.artist.split(',').first.trim();
    
    final queryWithArtist = Uri.encodeComponent('$cleanTitle $artist');
    final queryTitleOnly = Uri.encodeComponent(cleanTitle);
    
    final headers = {
      'User-Agent': 'music_app_flutter_client/1.0',
    };

    // Attempt 1: lrclib (Title + Artist)
    try {
      final response = await http.get(
        Uri.parse('https://lrclib.net/api/search?q=$queryWithArtist'), 
        headers: headers,
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data.first['plainLyrics'] != null && data.first['plainLyrics'].toString().isNotEmpty) {
          if (mounted) {
            setState(() {
              _lyrics = data.first['plainLyrics'];
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('lrclib artist search error: $e');
    }

    // Attempt 2: lrclib (Title only)
    try {
      final response = await http.get(
        Uri.parse('https://lrclib.net/api/search?q=$queryTitleOnly'), 
        headers: headers,
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data.first['plainLyrics'] != null && data.first['plainLyrics'].toString().isNotEmpty) {
          if (mounted) {
            setState(() {
              _lyrics = data.first['plainLyrics'];
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('lrclib title search error: $e');
    }

    // Attempt 3: lyrics.ovh Fallback
    try {
      final artistUrl = Uri.encodeComponent(artist);
      final titleUrl = Uri.encodeComponent(cleanTitle);
      final fallbackResponse = await http.get(
        Uri.parse('https://api.lyrics.ovh/v1/$artistUrl/$titleUrl'),
      ).timeout(const Duration(seconds: 5));
      
      if (fallbackResponse.statusCode == 200) {
        final data = json.decode(fallbackResponse.body);
        if (data['lyrics'] != null && data['lyrics'].toString().isNotEmpty) {
          if (mounted) {
            setState(() {
              _lyrics = data['lyrics'];
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('lyrics.ovh search error: $e');
    }

    if (mounted) {
      setState(() {
        _lyrics = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6E6E73);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F1420).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.95),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              CustomScrollView(
                controller: widget.scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Top Drag Handle & Song Summary Bar
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 42,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: AlbumArt(
                                    song: widget.song,
                                    width: 48,
                                    height: 48,
                                    iconSize: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (widget.song.isExplicit) const ExplicitBadge(size: 11),
                                        Expanded(
                                          child: Text(
                                            widget.song.title,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.3,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.song.artist,
                                      style: TextStyle(
                                        color: subtextColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              FrostedCircleButton(
                                icon: CupertinoIcons.xmark,
                                size: 36,
                                iconSize: 16,
                                iconColor: textColor,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Divider(
                          height: 1,
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Lyrics Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                      child: _buildLyricsContent(isDark, textColor, subtextColor),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),

              // Bottom Fade Gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 50,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          isDark ? const Color(0xFF0F1420) : Colors.white,
                          (isDark ? const Color(0xFF0F1420) : Colors.white).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsContent(bool isDark, Color textColor, Color subtextColor) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentColor1.withValues(alpha: 0.15 + 0.15 * _pulseController.value),
                          AppTheme.accentColor2.withValues(alpha: 0.05 + 0.10 * _pulseController.value),
                        ],
                      ),
                    ),
                    child: const Icon(CupertinoIcons.music_mic, color: AppTheme.accentColor1, size: 38),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Searching live lyrics...',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fetching synchronised text from music database',
                style: TextStyle(color: subtextColor, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_lyrics == null || _lyrics!.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                ),
                child: Icon(CupertinoIcons.text_bubble, color: subtextColor, size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                'Lyrics Not Available',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We couldn\'t find lyrics for this song yet.\nEnjoy the music!',
                textAlign: TextAlign.center,
                style: TextStyle(color: subtextColor, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchLyrics();
                },
                icon: const Icon(CupertinoIcons.refresh, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                  foregroundColor: textColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Split into lines for beautiful Apple Music style lyric layout
    final lines = _lyrics!.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          return const SizedBox(height: 22);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            trimmed,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: textColor.withValues(alpha: 0.92),
              letterSpacing: -0.3,
            ),
          ),
        );
      }).toList(),
    );
  }
}
