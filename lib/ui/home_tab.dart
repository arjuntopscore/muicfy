import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../admin_service.dart';
import '../theme_provider.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';
import 'favorites_screen.dart';
import 'artist_screen.dart';
import 'admin_pin_dialog.dart';
import 'admin_upload_screen.dart';
import '../gemini/gemini_music_screen.dart';
import '../gemini/gemini_config.dart';
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
    final adminService = context.watch<AdminService>();
    final topArtists = provider.getTopArtists();
    final greeting = provider.userName.isNotEmpty
        ? '${_getGreeting()}, ${provider.userName}'
        : _getGreeting();

    final themeProvider = context.watch<ThemeProvider>();
    final hasBackground = themeProvider.getBackgroundImageForTab(0) != null;

    return Container(
      decoration: BoxDecoration(
        color: hasBackground ? Colors.transparent : null,
        gradient: hasBackground ? null : LinearGradient(
          colors: [
            themeProvider.isDarkMode 
                ? const Color(0xFF2a2a2a) 
                : AppTheme.accentColor1.withOpacity(0.15),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          begin: Alignment.topLeft,
          end: const FractionalOffset(0.0, 0.4),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onLongPress: () {
                        // Hidden admin access — long-press avatar
                        if (adminService.isAdminLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
                          );
                        } else {
                          showAdminPinDialog(context);
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: adminService.isAdminLoggedIn
                            ? const Color(0xFFFF6B6B).withOpacity(0.3)
                            : Theme.of(context).cardColor,
                        child: Icon(
                          adminService.isAdminLoggedIn ? Icons.admin_panel_settings : Icons.person,
                          color: adminService.isAdminLoggedIn ? const Color(0xFFFF6B6B) : Theme.of(context).iconTheme.color,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                      tooltip: 'Gemini AI Music',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GeminiMusicScreen(
                              geminiApiKey: geminiApiKey,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        context.watch<ThemeProvider>().isDarkMode 
                            ? Icons.light_mode_rounded 
                            : Icons.dark_mode_rounded,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                      ),
                      onPressed: () {
                        context.read<ThemeProvider>().toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: _buildQuickSearchCard(context),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),
            SliverToBoxAdapter(
              child: _buildGeminiAiCard(context),
            ),

            // ── Admin Catalog Songs ──
            if (adminService.catalogSongs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 28, 16, 14),
                  child: Text('New Releases 🎵', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalList(context, adminService.catalogSongs, provider),
              ),
            ],

            // ── Top Artists ──
            if (topArtists.isNotEmpty) ...[
              SliverToBoxAdapter(
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
                      Text('Your Favorites', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                        },
                        child: Text('View All', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalList(context, provider.favorites, provider),
              ),
            ],

            // ── Made For You Mix ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Made For You 💫', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => provider.generateMadeForYouMix(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).cardColor,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              provider.isLoadingMix ? Icons.hourglass_top : Icons.refresh,
                              color: AppTheme.accentColor1, size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              provider.isLoadingMix ? 'Mixing...' : 'Refresh',
                              style: TextStyle(color: AppTheme.accentColor1, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: provider.isLoadingMix
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.accentColor1, strokeWidth: 2)),
                    )
                  : provider.madeForYouMix.isNotEmpty
                      ? _buildHorizontalList(context, provider.madeForYouMix, provider)
                      : GestureDetector(
                          onTap: () => provider.generateMadeForYouMix(),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1DB954), Color(0xFF0D6B30)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Theme.of(context).textTheme.bodyLarge?.color, size: 32),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Generate Your Mix', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16)),
                                      SizedBox(height: 4),
                                      Text('A personalized mix based on your taste', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.70), fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.play_circle_fill, color: Theme.of(context).textTheme.bodyLarge?.color, size: 36),
                              ],
                            ),
                          ),
                        ),
            ),
            
            if (provider.recentlyPlayed.isNotEmpty) ...[
              SliverToBoxAdapter(
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
                    Text('Your Local Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: onLocalLibraryTapped,
                      child: Text('View All', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12, fontWeight: FontWeight.bold)),
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
              SliverToBoxAdapter(
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 28, 16, 14),
                  child: Text('Trending Malayalam 🎶', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalList(context, provider.trendingMalayalam, provider),
              ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: 32)), 
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor1,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search, color: Colors.black, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Looking for something new?',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal circular artist avatars
  Widget _buildTopArtists(BuildContext context, List<Map<String, String>> artists) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;
    
    // Calculate responsive sizes
    final double targetItemWidth = isWide ? (screenWidth - 32) / artists.length : 85.0;
    final double targetAvatarSize = targetItemWidth - 14;
    final double finalAvatarSize = targetAvatarSize.clamp(72.0, 150.0);
    final double finalItemWidth = isWide ? targetItemWidth : 85.0;
    final double containerHeight = finalAvatarSize + 48.0;

    return SizedBox(
      height: containerHeight,
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
              width: finalItemWidth,
              padding: EdgeInsets.only(right: isWide ? 0 : 14),
              child: Column(
                children: [
                  Container(
                    width: finalAvatarSize,
                    height: finalAvatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
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
                        ? Icon(Icons.person, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.54), size: finalAvatarSize * 0.4)
                        : null,
                  ),
                  SizedBox(height: 8),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: isWide ? 13 : 11, fontWeight: FontWeight.w500),
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
                  SizedBox(height: 12),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.library_music, size: 48, color: Color(0xFFB3B3B3)),
          SizedBox(height: 16),
          Text('No local songs uploaded yet.', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.pickLocalAudio(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).textTheme.bodyLarge?.color,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('Upload Music', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiAiCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GeminiMusicScreen(
              geminiApiKey: geminiApiKey,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A11CB).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gemini AI Music Hub ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create vibe playlists & search by scene',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}







