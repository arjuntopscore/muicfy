import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import 'theme.dart';
import 'album_art.dart';
import 'favorites_screen.dart';
import 'stats_screen.dart';
import 'playlist_screen.dart';
import 'browse_library_screen.dart';
import '../spotify_service.dart';
import '../api_service.dart';
import '../song_model.dart';/// Data class for predefined library categories
class _LibraryCategory {
  final String title;
  final String query;
  final IconData icon;
  final List<Color> gradientColors;
  final String? imageUrl;

  const _LibraryCategory({
    required this.title,
    required this.query,
    required this.icon,
    required this.gradientColors,
    this.imageUrl,
  });
}

/// 30 predefined library categories
const List<_LibraryCategory> _predefinedLibraries = [
  // ── Malayalam ──
  _LibraryCategory(
    title: 'Malayalam Vintage Songs',
    query: 'Yesudas Malayalam',
    icon: Icons.music_note,
    gradientColors: [Color(0xFF1A237E), Color(0xFF4FC3F7)],
    imageUrl: 'https://c.saavncdn.com/artists/KJ_Yesudas_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Malayalam Old Songs',
    query: 'Mohanlal Malayalam',
    icon: Icons.album,
    gradientColors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
    imageUrl: 'https://c.saavncdn.com/artists/Mohanlal_004_20180706155810_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Malayalam Romantic Songs',
    query: 'Shaan Rahman Malayalam',
    icon: Icons.favorite,
    gradientColors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
    imageUrl: 'https://c.saavncdn.com/artists/Shaan_Rahman_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Malayalam Rap Songs',
    query: 'Dabzee Malayalam',
    icon: Icons.mic,
    gradientColors: [Color(0xFF263238), Color(0xFF546E7A)],
    imageUrl: 'https://c.saavncdn.com/artists/Dabzee_000_20230516072112_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Malayalam Sad Songs',
    query: 'Gopi Sundar Malayalam',
    icon: Icons.water_drop,
    gradientColors: [Color(0xFF37474F), Color(0xFF78909C)],
    imageUrl: 'https://c.saavncdn.com/artists/Gopi_Sundar_001_20190827112215_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Malayalam Devotional',
    query: 'Ayyappa devotional malayalam',
    icon: Icons.temple_hindu,
    gradientColors: [Color(0xFFFF6F00), Color(0xFFFFCA28)],
  ),
  _LibraryCategory(
    title: 'Malayalam Party Hits',
    query: 'Sushin Shyam Malayalam',
    icon: Icons.celebration,
    gradientColors: [Color(0xFF6A1B9A), Color(0xFFCE93D8)],
    imageUrl: 'https://c.saavncdn.com/artists/Sushin_Shyam_002_20250707125538_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Malayalam New Releases',
    query: 'Malayalam latest songs',
    icon: Icons.new_releases,
    gradientColors: [Color(0xFF00695C), Color(0xFF80CBC4)],
  ),

  // ── Tamil ──
  _LibraryCategory(
    title: 'Tamil Romance Songs',
    query: 'Anirudh Ravichander Tamil',
    icon: Icons.favorite_border,
    gradientColors: [Color(0xFFC62828), Color(0xFFEF9A9A)],
    imageUrl: 'https://c.saavncdn.com/artists/Anirudh_Ravichander_003_20260121134149_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Tamil Classic Hits',
    query: 'Ilayaraja SPB Tamil',
    icon: Icons.stars,
    gradientColors: [Color(0xFFBF360C), Color(0xFFFFAB91)],
    imageUrl: 'https://c.saavncdn.com/artists/Ilaiyaraaja_001_20251020081419_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Tamil Kuthu Songs',
    query: 'Vijay Anirudh Tamil',
    icon: Icons.music_note,
    gradientColors: [Color(0xFFAD1457), Color(0xFFF06292)],
  ),
  _LibraryCategory(
    title: 'Tamil Sad Songs',
    query: 'Yuvan Shankar Raja Tamil',
    icon: Icons.nightlight_round,
    gradientColors: [Color(0xFF1B5E20), Color(0xFF81C784)],
    imageUrl: 'https://c.saavncdn.com/artists/Yuvan_Shankar_Raja_002_20180802174245_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Tamil Rap & Hip Hop',
    query: 'Hiphop Tamizha Tamil',
    icon: Icons.surround_sound,
    gradientColors: [Color(0xFF212121), Color(0xFF757575)],
    imageUrl: 'https://c.saavncdn.com/artists/Arivu_000_20240109070048_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Tamil Melody Hits',
    query: 'Harris Jayaraj Tamil',
    icon: Icons.piano,
    gradientColors: [Color(0xFF4A148C), Color(0xFFB39DDB)],
    imageUrl: 'https://c.saavncdn.com/artists/Harris_Jayaraj_002_20230718071330_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Tamil New Releases',
    query: 'Tamil latest hit songs',
    icon: Icons.fiber_new,
    gradientColors: [Color(0xFF00838F), Color(0xFF80DEEA)],
  ),
  _LibraryCategory(
    title: 'Tamil Devotional',
    query: 'Murugan devotional tamil',
    icon: Icons.temple_hindu,
    gradientColors: [Color(0xFFE65100), Color(0xFFFFCC80)],
  ),

  // ── Hindi ──
  _LibraryCategory(
    title: 'Hindi Romantic Songs',
    query: 'Arijit Singh Hindi',
    icon: Icons.favorite,
    gradientColors: [Color(0xFFD32F2F), Color(0xFFFFCDD2)],
    imageUrl: 'https://c.saavncdn.com/artists/Arijit_Singh_004_20241118063717_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Hindi Party Anthems',
    query: 'Badshah Hindi',
    icon: Icons.nightlife,
    gradientColors: [Color(0xFF7B1FA2), Color(0xFFE1BEE7)],
    imageUrl: 'https://c.saavncdn.com/artists/Badshah_006_20241118064015_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Hindi Old Classics',
    query: 'Kishore Kumar Hindi',
    icon: Icons.auto_awesome,
    gradientColors: [Color(0xFF5D4037), Color(0xFFBCAAA4)],
    imageUrl: 'https://c.saavncdn.com/artists/Kishore_Kumar_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Hindi Sad Songs',
    query: 'Arijit Singh sad Hindi',
    icon: Icons.cloud,
    gradientColors: [Color(0xFF455A64), Color(0xFF90A4AE)],
  ),
  _LibraryCategory(
    title: 'Hindi Lofi & Chill',
    query: 'Hindi lofi mashup',
    icon: Icons.headphones,
    gradientColors: [Color(0xFF311B92), Color(0xFF9FA8DA)],
  ),
  _LibraryCategory(
    title: 'Hindi Rap & Hip Hop',
    query: 'Divine Naezy Hindi',
    icon: Icons.mic_external_on,
    gradientColors: [Color(0xFF1A1A1A), Color(0xFF616161)],
  ),

  // ── Telugu ──
  _LibraryCategory(
    title: 'Telugu Love Songs',
    query: 'Sid Sriram Telugu',
    icon: Icons.favorite_outline,
    gradientColors: [Color(0xFFF57F17), Color(0xFFFFF176)],
    imageUrl: 'https://c.saavncdn.com/artists/Sid_Sriram_005_20240425180600_500x500.jpg',
  ),
  _LibraryCategory(
    title: 'Telugu Mass Songs',
    query: 'Devi Sri Prasad Telugu',
    icon: Icons.bolt,
    gradientColors: [Color(0xFFFF6F00), Color(0xFFFFE082)],
    imageUrl: 'https://c.saavncdn.com/artists/Devi_Sri_Prasad_008_20250619062824_500x500.jpg',
  ),

  // ── Kannada ──
  _LibraryCategory(
    title: 'Kannada Love Songs',
    query: 'Sanjith Hegde Kannada',
    icon: Icons.spa,
    gradientColors: [Color(0xFF2E7D32), Color(0xFFA5D6A7)],
  ),

  // ── Mood-based ──
  _LibraryCategory(
    title: 'Workout Motivation',
    query: 'Gym workout motivation',
    icon: Icons.fitness_center,
    gradientColors: [Color(0xFFE53935), Color(0xFFFF8A65)],
  ),
  _LibraryCategory(
    title: 'Study & Focus',
    query: 'Instrumental study focus',
    icon: Icons.school,
    gradientColors: [Color(0xFF1565C0), Color(0xFF90CAF9)],
  ),
  _LibraryCategory(
    title: 'Road Trip Vibes',
    query: 'Travel road trip songs',
    icon: Icons.directions_car,
    gradientColors: [Color(0xFF00897B), Color(0xFF80CBC4)],
  ),
  _LibraryCategory(
    title: 'Late Night Vibes',
    query: 'Midnight chill lofi',
    icon: Icons.dark_mode,
    gradientColors: [Color(0xFF0D0D2B), Color(0xFF3949AB)],
  ),
  _LibraryCategory(
    title: 'Feel Good Hits',
    query: 'Happy upbeat songs',
    icon: Icons.emoji_emotions,
    gradientColors: [Color(0xFFFFA000), Color(0xFFFFE57F)],
  ),
];

class LibraryTab extends StatelessWidget {
  final VoidCallback onOfflineFolderTapped;

  const LibraryTab({super.key, required this.onOfflineFolderTapped});

  void _importFromSpotify(BuildContext context, MusicProvider provider) async {
    final spotifyService = SpotifyService();
    
    // Show a loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to Spotify...'), duration: Duration(seconds: 2)),
    );

    bool success = await spotifyService.authenticate();
    if (!success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to Spotify')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching playlists...'), duration: Duration(seconds: 2)),
    );

    final playlists = await spotifyService.getUserPlaylists();
    
    if (!context.mounted) return;
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Spotify playlists found.')),
      );
      return;
    }

    // Show a dialog to let the user pick a playlist
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: Text('Select a Playlist to Import', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final pl = playlists.elementAt(index);
              return ListTile(
                title: Text(pl.name ?? 'Unknown', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () async {
                  Navigator.pop(ctx);
                  _processSpotifyPlaylist(context, provider, spotifyService, pl.id!, pl.name ?? 'Imported Playlist');
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _processSpotifyPlaylist(BuildContext context, MusicProvider provider, SpotifyService spotifyService, String spotifyPlaylistId, String playlistName) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Importing "$playlistName"... This might take a minute.'), duration: const Duration(seconds: 5)),
    );

    final tracks = await spotifyService.getPlaylistTracks(spotifyPlaylistId);
    
    // Convert Spotify tracks to playable songs by searching API
    final apiService = ApiService();
    List<Song> importedSongs = [];
    
    for (var track in tracks.take(20)) { // Limit to 20 to avoid rate limits
      final artistName = track.artists?.isNotEmpty == true ? track.artists!.first.name : '';
      final query = '${track.name} $artistName';
      final results = await apiService.searchSongs(query, limit: 1);
      if (results.isNotEmpty) {
        importedSongs.add(results.first);
      }
    }

    provider.createPlaylist(playlistName, initialSongs: importedSongs);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully imported ${importedSongs.length} songs into "$playlistName"')),
      );
    }
  }

  void _showCreatePlaylistDialog(BuildContext context, MusicProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: Text('Create Playlist', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.38)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.24) ?? Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentColor1)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.70))),
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
            child: Text('Create', style: TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Library', style: Theme.of(context).textTheme.displaySmall),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add, color: AppTheme.accentColor1, size: 30),
                        tooltip: 'Create Playlist',
                        onPressed: () => _showCreatePlaylistDialog(context, provider),
                      ),
                      IconButton(
                        icon: Icon(Icons.bar_chart, color: AppTheme.accentColor1, size: 30),
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
          ),

          // Favorites tile
          SliverToBoxAdapter(
            child: ListTile(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FF7), Color(0xFFE91E63)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.favorite, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              title: Text('Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${provider.favorites.length} liked songs'),
              trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.54)),
            ),
          ),

          // Offline folder tile
          SliverToBoxAdapter(
            child: ListTile(
              onTap: onOfflineFolderTapped,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                ),
                child: Icon(Icons.library_music, color: AppTheme.accentColor1),
              ),
              title: Text('Offline Local Folder', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${provider.localLibrary.length} saved songs'),
              trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.54)),
            ),
          ),

          // Spotify Import tile
          SliverToBoxAdapter(
            child: ListTile(
              onTap: () => _importFromSpotify(context, provider),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF1DB954), // Spotify Green
                ),
                child: Icon(Icons.download, color: Colors.black),
              ),
              title: Text('Import from Spotify', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Connect your account'),
              trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.54)),
            ),
          ),

          // ── User Playlists section ──
          if (provider.userPlaylists.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('Your Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final playlist = provider.userPlaylists[index];
                  return Dismissible(
                    key: ValueKey(playlist.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: Icon(Icons.delete, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF282828),
                          title: Text('Delete Playlist', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                          content: Text('Delete "${playlist.name}"?', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.70))),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.70))),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ) ?? false;
                    },
                    onDismissed: (_) => provider.deletePlaylist(playlist.id),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PlaylistScreen(playlistId: playlist.id)),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentColor1.withValues(alpha: 0.6),
                              AppTheme.accentColor1.withValues(alpha: 0.2),
                            ],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(Icons.queue_music, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      title: Text(playlist.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${playlist.songs.length} songs'),
                      trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.54)),
                    ),
                  );
                },
                childCount: provider.userPlaylists.length,
              ),
            ),
          ],

          // Create playlist CTA (when empty)
          if (provider.userPlaylists.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: GestureDetector(
                  onTap: () => _showCreatePlaylistDialog(context, provider),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.12) ?? Colors.grey),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: AppTheme.accentColor1, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Create your first playlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('Organize your music your way', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.54), fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Browse Libraries section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Browse Libraries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Explore curated collections by language and mood', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.54), fontSize: 13)),
                ],
              ),
            ),
          ),

          // Library grid - 2 columns
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final lib = _predefinedLibraries[index];
                  return _LibraryCard(category: lib);
                },
                childCount: _predefinedLibraries.length,
              ),
            ),
          ),

          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

/// A single library card in the grid
class _LibraryCard extends StatelessWidget {
  final _LibraryCategory category;

  const _LibraryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BrowseLibraryScreen(
              title: category.title,
              query: category.query,
              gradientColors: category.gradientColors,
              icon: category.icon,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Base background
            Positioned.fill(
              child: category.imageUrl != null
                  ? Image.network(
                      category.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: category.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: category.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
            ),
            
            // Blur and dark dimming overlay (no opaque gradient, just simple tint)
            if (category.imageUrl != null)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3), // Lightly dim the image to make text readable
                  ),
                ),
              ),

            // Content
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(category.icon, color: Theme.of(context).textTheme.bodyLarge?.color, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.title,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}









