import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../api_service.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';

/// A screen that shows songs for a single predefined library category.
/// Loads 30 songs initially, then auto-loads 10 more on scroll.
class BrowseLibraryScreen extends StatefulWidget {
  final String title;
  final String query;
  final List<Color> gradientColors;
  final IconData icon;

  const BrowseLibraryScreen({
    super.key,
    required this.title,
    required this.query,
    required this.gradientColors,
    required this.icon,
  });

  @override
  State<BrowseLibraryScreen> createState() => _BrowseLibraryScreenState();
}

class _BrowseLibraryScreenState extends State<BrowseLibraryScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final List<Song> _songs = [];
  final Set<String> _seenIds = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);

    final results = await _apiService.searchSongs(widget.query, limit: 30, page: 1);

    for (final song in results) {
      if (!_seenIds.contains(song.id)) {
        _seenIds.add(song.id);
        _songs.add(song);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasMore = results.length >= 10;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    _page++;
    
    final results = await _apiService.searchSongs(widget.query, limit: 30, page: _page);

    int addedCount = 0;
    for (final song in results) {
      if (!_seenIds.contains(song.id)) {
        _seenIds.add(song.id);
        _songs.add(song);
        addedCount++;
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        _hasMore = addedCount > 0; // Keep fetching until we run out of unique songs
      });
    }
  }

  void _playAll() {
    if (_songs.isEmpty) return;
    final provider = context.read<MusicProvider>();
    provider.playSong(_songs.first, playlist: _songs);
  }

  void _shufflePlay() {
    if (_songs.isEmpty) return;
    final provider = context.read<MusicProvider>();
    final shuffled = List<Song>.from(_songs)..shuffle();
    provider.playSong(shuffled.first, playlist: shuffled);
  }

  void _showAddToPlaylistSheet(Song song) {
    final provider = context.read<MusicProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 4),
              Text(song.artist, style: const TextStyle(color: Colors.white54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  provider.isFavorite(song) ? Icons.favorite : Icons.favorite_border,
                  color: provider.isFavorite(song) ? Colors.redAccent : Colors.white70,
                ),
                title: Text(
                  provider.isFavorite(song) ? 'Remove from Favorites' : 'Add to Favorites',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  provider.toggleFavorite(song);
                  Navigator.pop(ctx);
                },
              ),
              if (provider.userPlaylists.isNotEmpty) ...[
                const Divider(color: Colors.white12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Add to Playlist', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ),
                ...provider.userPlaylists.map((pl) => ListTile(
                  leading: Icon(Icons.queue_music, color: Colors.white70),
                  title: Text(pl.name, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    provider.addSongToPlaylist(pl.id, song);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to "${pl.name}"'),
                        backgroundColor: const Color(0xFF282828),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                )),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Gradient header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: widget.gradientColors.first,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 24),
                      Icon(widget.icon, size: 48, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        widget.title,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Play All / Shuffle row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _songs.isNotEmpty ? _playAll : null,
                      icon: Icon(Icons.play_arrow, size: 20),
                      label: Text('Play All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor1,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _songs.isNotEmpty ? _shufflePlay : null,
                      icon: Icon(Icons.shuffle, size: 20),
                      label: Text('Shuffle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentColor1,
                        side: const BorderSide(color: AppTheme.accentColor1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading state
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor1),
              ),
            )
          else ...[
            // Song list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: AlbumArt(
                      song: song,
                      width: 50,
                      height: 50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.white54),
                      onPressed: () => _showAddToPlaylistSheet(song),
                    ),
                    onTap: () {
                      final provider = context.read<MusicProvider>();
                      provider.playSong(song, playlist: _songs);
                    },
                  );
                },
                childCount: _songs.length,
              ),
            ),

            // Loading more spinner at the bottom
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: AppTheme.accentColor1, strokeWidth: 2),
                    ),
                  ),
                ),
              ),

            // Bottom padding for mini player
            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }
}



