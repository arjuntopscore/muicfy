import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import 'theme.dart';
import 'album_art.dart';
import 'favorites_screen.dart';
import 'stats_screen.dart';
import 'playlist_screen.dart';

class LibraryTab extends StatelessWidget {
  final VoidCallback onOfflineFolderTapped;

  const LibraryTab({super.key, required this.onOfflineFolderTapped});

  void _showCreatePlaylistDialog(BuildContext context, MusicProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Create Playlist', style: TextStyle(color: Colors.white)),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                provider.createPlaylist(name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created "$name"'),
                    backgroundColor: const Color(0xFF282828),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Library', style: Theme.of(context).textTheme.displaySmall),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: AppTheme.accentColor1, size: 30),
                      tooltip: 'Create Playlist',
                      onPressed: () => _showCreatePlaylistDialog(context, provider),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bar_chart, color: AppTheme.accentColor1, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StatsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // Favorites folder
                ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B2FF7), Color(0xFFE91E63)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white),
                  ),
                  title: const Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${provider.favorites.length} liked songs'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                ),

                ListTile(
                  onTap: onOfflineFolderTapped,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.surfaceColor,
                    ),
                    child: const Icon(Icons.library_music, color: AppTheme.accentColor1),
                  ),
                  title: const Text('Offline Local Folder', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${provider.localLibrary.length} saved songs'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                ),

                // User Playlists section
                if (provider.userPlaylists.isNotEmpty) ...[
                  const Divider(color: Colors.white12, height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Your Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ...provider.userPlaylists.map((playlist) => Dismissible(
                    key: ValueKey(playlist.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF282828),
                          title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
                          content: Text('Delete "${playlist.name}"?', style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ) ?? false;
                    },
                    onDismissed: (_) {
                      provider.deletePlaylist(playlist.id);
                    },
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistScreen(playlistId: playlist.id),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentColor1.withOpacity(0.6),
                              AppTheme.accentColor1.withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.queue_music, color: Colors.white),
                      ),
                      title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${playlist.songs.length} songs'),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    ),
                  )),
                ],

                // Create playlist button (when empty)
                if (provider.userPlaylists.isEmpty) ...[
                  const Divider(color: Colors.white12, height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => _showCreatePlaylistDialog(context, provider),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_circle_outline, color: AppTheme.accentColor1, size: 32),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Create your first playlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  SizedBox(height: 4),
                                  Text('Organize your music your way', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                
                const Divider(color: Colors.white12, height: 32),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Top Global Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                
                if (provider.isLoadingLibrary)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.accentColor1)),
                  )
                else
                  ...provider.topSongs.map((song) => ListTile(
                    leading: AlbumArt(
                      song: song,
                      width: 50,
                      height: 50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => provider.playSong(song, playlist: provider.topSongs),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
