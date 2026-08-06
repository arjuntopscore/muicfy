import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../song_model.dart';
import '../api_service.dart';
import 'theme.dart';
import 'album_art.dart';
import 'favorites_screen.dart';
import 'artist_screen.dart';
class HomeTab extends StatelessWidget {
  final VoidCallback onSearchTapped;
  final VoidCallback onLocalLibraryTapped;

  const HomeTab({
    super.key,
    required this.onSearchTapped,
    required this.onLocalLibraryTapped,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final topArtists = provider.getTopArtists();
    final greeting = provider.userName.isNotEmpty
        ? '${_getGreeting()}, ${provider.userName}'
        : _getGreeting();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2a2a2a), // Dark grey
            AppTheme.bgColor,
          ],
          begin: Alignment.topLeft,
          end: FractionalOffset(0.0, 0.4),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.surfaceColor,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: _buildQuickSearchCard(context),
            ),

            // ── Top Artists ──
            if (topArtists.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 28, 16, 14),
                  child: Text('Top Artists', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildTopArtists(context, topArtists),
              ),
            ],

            // ── Favorites ──
            if (provider.favorites.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Favorites', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                        },
                        child: const Text('View All', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalList(context, provider.favorites, provider),
              ),
            ],
            
            if (provider.recentlyPlayed.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Text('Recently played', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalList(context, provider.recentlyPlayed, provider),
              ),
            ],

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Local Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: onLocalLibraryTapped,
                      child: const Text('View All', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: provider.localLibrary.isNotEmpty
                  ? _buildHorizontalList(context, provider.localLibrary, provider)
                  : _buildEmptyLocalLibrary(context, provider),
            ),

            // ── Trending Tamil ──
            if (provider.trendingTamil.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 28, 16, 14),
                  child: Text('Trending Tamil 🎶', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalList(context, provider.trendingTamil, provider),
              ),
            ],

            // ── Trending Malayalam ──
            if (provider.trendingMalayalam.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 28, 16, 14),
                  child: Text('Trending Malayalam 🎶', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalList(context, provider.trendingMalayalam, provider),
              ),
            ],
            
            const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for mini player
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSearchCard(BuildContext context) {
    return GestureDetector(
      onTap: onSearchTapped,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.accentColor1,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: const Text(
                'Looking for something new?',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal circular artist avatars
  Widget _buildTopArtists(BuildContext context, List<Map<String, String>> artists) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          final name = artist['name'] ?? '';
          final imageUrl = artist['imageUrl'] ?? '';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistScreen(
                    artistName: name,
                    artistImageUrl: imageUrl,
                  ),
                ),
              );
            },
            child: Container(
              width: 85,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceColor,
                      image: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: Border.all(
                        color: AppTheme.accentColor1.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: imageUrl.isEmpty || !imageUrl.startsWith('http')
                        ? const Icon(Icons.person, color: Colors.white54, size: 32)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List<Song> songs, MusicProvider provider) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
            onTap: () => provider.playSong(song, playlist: songs),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AlbumArt(
                    song: song,
                    width: 140,
                    height: 140,
                    borderRadius: BorderRadius.circular(8),
                    iconSize: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyLocalLibrary(BuildContext context, MusicProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.library_music, size: 48, color: Color(0xFFB3B3B3)),
          const SizedBox(height: 16),
          const Text('No local songs uploaded yet.', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.pickLocalAudio(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Upload Music', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

