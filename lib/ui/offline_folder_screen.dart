import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import 'theme.dart';
import 'album_art.dart';

class OfflineFolderScreen extends StatelessWidget {
  const OfflineFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final songs = provider.localLibrary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Offline Folder'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Upload Music',
            onPressed: () => provider.pickLocalAudio(context),
          )
        ],
      ),
      body: songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Nothing here yet — add some songs to get started', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.pickLocalAudio(context),
                    icon: Icon(Icons.upload_file),
                    label: Text('Upload Music'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor1,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100, top: 8),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: AlbumArt(
                    song: song,
                    width: 50,
                    height: 50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _showDeleteDialog(context, provider, song),
                  ),
                  onTap: () => provider.playSong(song, playlist: songs),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(BuildContext context, MusicProvider provider, song) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Remove from Your Library?'),
        content: Text('Are you sure you want to remove "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteLocalSong(song);
              Navigator.pop(ctx);
            },
            child: Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}


