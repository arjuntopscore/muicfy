import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../song_model.dart';
import '../api_service.dart';
import 'theme.dart';
import 'album_art.dart';

/// Shows search results as a browsable library/playlist.
/// Triggered when user searches for genre/language-based queries
/// like "Malayalam songs", "Tamil rap", etc.
class SearchLibraryScreen extends StatefulWidget {
  final String query;
  final List<Song> initialResults;

  const SearchLibraryScreen({
    super.key,
    required this.query,
    required this.initialResults,
  });

  @override
  State<SearchLibraryScreen> createState() => _SearchLibraryScreenState();
}

class _SearchLibraryScreenState extends State<SearchLibraryScreen> {
  final ApiService _apiService = ApiService();
  late List<Song> _songs;
  bool _isLoadingMore = false;
  int _page = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _songs = List.from(widget.initialResults);
    _scrollController.addListener(_onScroll);
    // If initial results are few, load more
    if (_songs.length < 10) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _page++;

    // Search with slightly varied queries to get more diverse results
    final variations = [
      widget.query,
      '${widget.query} hits',
      '${widget.query} popular',
      '${widget.query} latest',
      '${widget.query} best',
    ];
    final variationQuery = variations[_page % variations.length];

    final results = await _apiService.searchSongs(variationQuery, limit: 20);
    if (mounted) {
      final existingIds = _songs.map((s) => s.id).toSet();
      final newSongs = results.where((s) => !existingIds.contains(s.id)).toList();
      setState(() {
        _songs.addAll(newSongs);
        _isLoadingMore = false;
      });
    }
  }

  /// Generate a display title from the query
  String get _displayTitle {
    return widget.query.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Pick a gradient based on query content for visual variety
  List<Color> get _headerGradient {
    final q = widget.query.toLowerCase();
    if (q.contains('malayalam')) {
      return [const Color(0xFF1a237e), const Color(0xFF0d47a1)];
    } else if (q.contains('tamil')) {
      return [const Color(0xFFb71c1c), const Color(0xFFe65100)];
    } else if (q.contains('hindi')) {
      return [const Color(0xFF4a148c), const Color(0xFF7b1fa2)];
    } else if (q.contains('telugu')) {
      return [const Color(0xFF004d40), const Color(0xFF00695c)];
    } else if (q.contains('kannada')) {
      return [const Color(0xFFe65100), const Color(0xFFf57c00)];
    } else if (q.contains('rap') || q.contains('hip hop')) {
      return [const Color(0xFF212121), const Color(0xFF424242)];
    } else if (q.contains('romantic') || q.contains('love')) {
      return [const Color(0xFFc62828), const Color(0xFFe91e63)];
    } else if (q.contains('sad')) {
      return [const Color(0xFF263238), const Color(0xFF37474f)];
    } else {
      return [const Color(0xFF1b5e20), const Color(0xFF2e7d32)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Gradient header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _headerGradient.first,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _displayTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        _getIconForQuery(),
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_songs.length} songs',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Play all / shuffle row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _songs.isNotEmpty
                          ? () => provider.playSong(_songs.first, playlist: _songs)
                          : null,
                      icon: const Icon(Icons.play_arrow, color: Colors.black),
                      label: const Text('Play All', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _songs.isNotEmpty
                          ? () {
                              final shuffled = List<Song>.from(_songs)..shuffle();
                              provider.playSong(shuffled.first, playlist: shuffled);
                            }
                          : null,
                      icon: const Icon(Icons.shuffle, color: AppTheme.accentColor1),
                      label: const Text('Shuffle', style: TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.accentColor1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Save as playlist button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.createPlaylist(_displayTitle, initialSongs: _songs);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved "$_displayTitle" as a playlist'),
                      backgroundColor: const Color(0xFF282828),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.playlist_add, color: Colors.white70),
                label: const Text('Save as Playlist', style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Songs list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _songs.length) return null;
                final song = _songs[index];
                return ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${index + 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AlbumArt(
                        song: song,
                        width: 48,
                        height: 48,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    color: const Color(0xFF282828),
                    onSelected: (value) {
                      if (value == 'favorite') {
                        provider.toggleFavorite(song);
                      } else if (value == 'add_to_playlist') {
                        _showAddToPlaylistDialog(context, provider, song);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(
                              provider.isFavorite(song) ? Icons.favorite : Icons.favorite_border,
                              color: provider.isFavorite(song) ? AppTheme.accentColor1 : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              provider.isFavorite(song) ? 'Remove from Favorites' : 'Add to Favorites',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add_to_playlist',
                        child: Row(
                          children: [
                            Icon(Icons.playlist_add, color: Colors.white70, size: 20),
                            SizedBox(width: 8),
                            Text('Add to Playlist', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    provider.addToRecentSearches(song);
                    provider.playSong(song, playlist: _songs);
                  },
                );
              },
              childCount: _songs.length,
            ),
          ),

          // Loading more indicator
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: AppTheme.accentColor1)),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  IconData _getIconForQuery() {
    final q = widget.query.toLowerCase();
    if (q.contains('rap') || q.contains('hip hop')) return Icons.mic;
    if (q.contains('romantic') || q.contains('love')) return Icons.favorite;
    if (q.contains('sad')) return Icons.sentiment_dissatisfied;
    if (q.contains('party') || q.contains('dance')) return Icons.celebration;
    return Icons.library_music;
  }

  void _showAddToPlaylistDialog(BuildContext context, MusicProvider provider, Song song) {
    final playlists = provider.userPlaylists;
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a playlist first from the Library tab'),
          backgroundColor: Color(0xFF282828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Add to Playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...playlists.map((p) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.accentColor1.withOpacity(0.2),
                  ),
                  child: const Icon(Icons.queue_music, color: AppTheme.accentColor1),
                ),
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('${p.songs.length} songs', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  provider.addSongToPlaylist(p.id, song);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to "${p.name}"'),
                      backgroundColor: const Color(0xFF282828),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
