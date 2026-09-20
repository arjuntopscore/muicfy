import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../playlist_model.dart';
import '../song_model.dart';
import '../api_service.dart';
import 'theme.dart';
import 'album_art.dart';

class PlaylistScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final playlist = provider.userPlaylists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => Playlist(id: '', name: 'Not Found'),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white70),
            onPressed: () => _showRenameDialog(context, provider, playlist),
          ),
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.accentColor1),
            onPressed: () => _showAddSongsDialog(context, provider, playlist),
          ),
        ],
      ),
      body: playlist.songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'No songs in this playlist yet',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSongsDialog(context, provider, playlist),
                    icon: Icon(Icons.add, color: Colors.black),
                    label: Text('Add Songs', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Play all / Shuffle buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (playlist.songs.isNotEmpty) {
                              provider.playSong(playlist.songs.first, playlist: playlist.songs);
                            }
                          },
                          icon: Icon(Icons.play_arrow, color: Colors.black),
                          label: Text('Play All', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (playlist.songs.isNotEmpty) {
                              final shuffled = List<Song>.from(playlist.songs)..shuffle();
                              provider.playSong(shuffled.first, playlist: shuffled);
                            }
                          },
                          icon: Icon(Icons.shuffle, color: AppTheme.accentColor1),
                          label: Text('Shuffle', style: TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.accentColor1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: playlist.songs.length,
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderPlaylistSong(playlist.id, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = playlist.songs[index];
                      return ListTile(
                        key: ValueKey('${playlist.id}_${song.id}_$index'),
                        leading: AlbumArt(
                          song: song,
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                provider.removeSongFromPlaylist(playlist.id, song);
                              },
                            ),
                            Icon(Icons.drag_handle, color: Colors.white38),
                          ],
                        ),
                        onTap: () => provider.playSong(song, playlist: playlist.songs),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showRenameDialog(BuildContext context, MusicProvider provider, Playlist playlist) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: Text('Rename Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentColor1)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                provider.renamePlaylist(playlist.id, name);
                Navigator.pop(ctx);
              }
            },
            child: Text('Save', style: TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddSongsDialog(BuildContext context, MusicProvider provider, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddSongsSheet(playlistId: playlist.id),
    );
  }
}

/// Bottom sheet for searching and adding songs to a playlist
class _AddSongsSheet extends StatefulWidget {
  final String playlistId;
  const _AddSongsSheet({required this.playlistId});

  @override
  State<_AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends State<_AddSongsSheet> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Song> _results = [];
  bool _isSearching = false;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final results = await _apiService.searchSongs(query, limit: 20);
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final playlist = provider.userPlaylists.firstWhere(
      (p) => p.id == widget.playlistId,
      orElse: () => Playlist(id: '', name: ''),
    );
    final existingIds = playlist.songs.map((s) => s.id).toSet();

    // Build source list: recently played + favorites + search results
    List<Song> sourceSongs;
    String headerText;
    if (_results.isNotEmpty) {
      sourceSongs = _results;
      headerText = 'Search Results';
    } else {
      // Show recently played and favorites as suggestions
      final suggestions = <Song>[];
      for (final s in provider.recentlyPlayed) {
        if (!suggestions.any((x) => x.id == s.id)) suggestions.add(s);
      }
      for (final s in provider.favorites) {
        if (!suggestions.any((x) => x.id == s.id)) suggestions.add(s);
      }
      sourceSongs = suggestions;
      headerText = 'Suggestions';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add to "${playlist.name}"',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search songs to add...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            SizedBox(height: 8),
            if (_isSearching)
              Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppTheme.accentColor1),
              ),
            if (!_isSearching && sourceSongs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(headerText, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: sourceSongs.length,
                itemBuilder: (context, index) {
                  final song = sourceSongs[index];
                  final alreadyAdded = existingIds.contains(song.id);
                  return ListTile(
                    leading: AlbumArt(
                      song: song,
                      width: 45,
                      height: 45,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    trailing: alreadyAdded
                        ? Icon(Icons.check_circle, color: AppTheme.accentColor1)
                        : IconButton(
                            icon: Icon(Icons.add_circle_outline, color: Colors.white54),
                            onPressed: () {
                              provider.addSongToPlaylist(widget.playlistId, song);
                              setState(() {}); // refresh check marks
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}


