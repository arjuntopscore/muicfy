import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../song_model.dart';
import 'theme.dart';

class LyricsSheet extends StatefulWidget {
  final Song song;
  final ScrollController scrollController;

  LyricsSheet({
    Key? key,
    required this.song,
    required this.scrollController,
  }) : super(key: key);

  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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

class _LyricsSheetState extends State<LyricsSheet> {
  bool _isLoading = true;
  String? _lyrics;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
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
    final artist = widget.song.artist.split(',').first.trim(); // Take first artist if multiple
    
    final queryWithArtist = Uri.encodeComponent('$cleanTitle $artist');
    final queryTitleOnly = Uri.encodeComponent(cleanTitle);
    
    final headers = {
      'User-Agent': 'music_app_flutter_client/1.0',
    };

    // Attempt 1: lrclib (Title + Artist)
    try {
      final response = await http.get(
        Uri.parse('https://lrclib.net/api/search?q=$queryWithArtist'), 
        headers: headers
      ).timeout(Duration(seconds: 5));
      
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
        headers: headers
      ).timeout(Duration(seconds: 5));
      
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
        Uri.parse('https://api.lyrics.ovh/v1/$artistUrl/$titleUrl')
      ).timeout(Duration(seconds: 5));
      
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
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        widget.song.title,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        widget.song.artist,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: _buildContent(),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
          Positioned(
            top: 100, // Adjust based on header size to blend the top of the lyrics
            left: 0,
            right: 0,
            height: 40,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A1A1A),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 48),
          Icon(Icons.music_note, color: Color(0xFF1DB954), size: 48),
          SizedBox(height: 16),
          Text(
            'Finding lyrics...',
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.54), fontSize: 16),
          ),
        ],
      );
    }

    if (_lyrics == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 48),
          Icon(Icons.sentiment_dissatisfied, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.54), size: 48),
          SizedBox(height: 16),
          Text(
            'Lyrics not available for this song',
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.54), fontSize: 16),
          ),
        ],
      );
    }

    return Text(
      _lyrics!,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        height: 1.8,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }
}






