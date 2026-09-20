import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import 'theme.dart';
import 'album_art.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final songs = provider.favorites;

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1DB954), Color(0xFF121212)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor.withOpacity(0.5),
                    ),
                    child: Icon(Icons.favorite_border, size: 64, color: Colors.white24),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No favorites yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any song\nto add it to your favorites',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header with song count and shuffle play
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${songs.length} song${songs.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (songs.isNotEmpty) {
                            final shuffled = List.of(songs)..shuffle();
                            provider.playSong(shuffled.first, playlist: shuffled);
                          }
                        },
                        icon: Icon(Icons.shuffle, size: 18),
                        label: Text('Shuffle Play'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor1,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, top: 0),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: AlbumArt(
                          song: song,
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: Icon(Icons.favorite, color: AppTheme.accentColor1),
                          onPressed: () => provider.toggleFavorite(song),
                        ),
                        onTap: () => provider.playSong(song, playlist: songs),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}



