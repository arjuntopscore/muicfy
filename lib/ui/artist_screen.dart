import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../api_service.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';

class ArtistScreen extends StatefulWidget {
  final String artistName;
  final String artistImageUrl;

  const ArtistScreen({
    super.key,
    required this.artistName,
    required this.artistImageUrl,
  });

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  final ApiService _apiService = ApiService();
  List<Song> _artistSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistSongs();
  }

  Future<void> _loadArtistSongs() async {
    final songs = await _apiService.searchSongs(widget.artistName, limit: 30);
    if (mounted) {
      setState(() {
        _artistSongs = songs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppTheme.bgColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.artistName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.dstIn,
                child: Image.network(
                  widget.artistImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: AppTheme.surfaceColor);
                  },
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor1),
              ),
            )
          else if (_artistSongs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No songs found',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = _artistSongs[index];
                    final isPlaying = provider.currentSong?.id == song.id;

                    return ListTile(
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
                        style: TextStyle(
                          color: isPlaying ? AppTheme.accentColor1 : Colors.white,
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              provider.isFavorite(song) ? Icons.favorite : Icons.favorite_border,
                              color: provider.isFavorite(song) ? AppTheme.accentColor1 : Colors.white54,
                            ),
                            onPressed: () => provider.toggleFavorite(song),
                          ),
                          const Icon(Icons.more_vert, color: Colors.white54),
                        ],
                      ),
                      onTap: () => provider.playSong(song, playlist: _artistSongs),
                    );
                  },
                  childCount: _artistSongs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
