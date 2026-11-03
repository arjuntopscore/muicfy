import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';

class QueueScreen extends StatefulWidget {
  QueueScreen({Key? key}) : super(key: key);

  @override
  _QueueScreenState createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  bool _showPreviouslyPlayed = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final queue = provider.currentPlaylist;
    final currentIndex = provider.currentPlaylistIndex;
    final currentSong = provider.currentSong;

    List<Song> previouslyPlayed = [];
    List<Song> upNext = [];
    
    if (queue.isNotEmpty && currentIndex >= 0) {
      previouslyPlayed = queue.sublist(0, currentIndex);
      if (currentIndex + 1 < queue.length) {
        upNext = queue.sublist(currentIndex + 1);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Scaffold(
          backgroundColor: Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Color(0xFF121212),
            elevation: 0,
            title: Text('Queue', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            leading: IconButton(
              icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).textTheme.bodyLarge?.color),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: queue.isEmpty
              ? Center(child: Text('Queue is empty', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (previouslyPlayed.isNotEmpty)
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(
                            'Previously Played',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          iconColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          collapsedIconColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _showPreviouslyPlayed = expanded;
                            });
                          },
                          initiallyExpanded: _showPreviouslyPlayed,
                          children: previouslyPlayed.asMap().entries.map((entry) {
                            final index = entry.key; // Index in previouslyPlayed matches index in original queue
                            final song = entry.value;
                            return _buildSongTile(context, song, provider, index, false);
                          }).toList(),
                        ),
                      ),
                    
                    if (currentSong != null) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Now Playing',
                          style: TextStyle(
                            color: Color(0xFF1DB954),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _buildSongTile(context, currentSong, provider, currentIndex, true),
                    ],
                      
                    if (upNext.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Up Next',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ...upNext.asMap().entries.map((entry) {
                        final index = currentIndex + 1 + entry.key;
                        final song = entry.value;
                        return _buildSongTile(context, song, provider, index, false);
                      }).toList(),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, Song song, MusicProvider provider, int originalIndex, bool isPlaying) {
    Widget tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: AlbumArt(
        song: song,
        width: 50,
        height: 50,
        borderRadius: BorderRadius.circular(4),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isPlaying ? Color(0xFF1DB954) : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        song.artist,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: isPlaying
          ? _buildWaveAnimation()
          : null,
      onTap: () {
        provider.playSong(song);
      },
    );

    if (isPlaying) {
      return tile;
    }

    return Dismissible(
      key: ValueKey('${song.id}_$originalIndex'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      onDismissed: (direction) {
        setState(() {
          provider.currentPlaylist.removeAt(originalIndex);
          // Note: to sync with audio player state correctly in the future, 
          // provider should implement and expose a method for queue reordering/deletion.
        });
      },
      child: tile,
    );
  }

  Widget _buildWaveAnimation() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3,
          height: 12.0 + (index * 4 % 8), // Static visual representation of a wave
          decoration: BoxDecoration(
            color: Color(0xFF1DB954),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}






