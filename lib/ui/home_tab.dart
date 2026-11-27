import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'song_action_sheet.dart';
import 'apple_music_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final adminService = context.watch<AdminService>();
    final topArtists = provider.getTopArtists();

    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final hasBackground = themeProvider.getBackgroundImageForTab(0) != null;

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF6E6E73);

    return Container(
      decoration: BoxDecoration(
        color: hasBackground ? Colors.transparent : (isDark ? Colors.black : const Color(0xFFF2F2F7)),
        gradient: hasBackground
            ? null
            : (isDark
                ? const LinearGradient(
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF090D16),
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.4, 0.85],
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFFE8EEF9),
                      Color(0xFFF5F6F9),
                      Color(0xFFF2F2F7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.4, 0.85],
                  )),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Apple Music / Radio Top Header (Image 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Radio',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const Spacer(),

                    // Instant Theme Mode Switcher (Sun / Moon)
                    IconButton(
                      icon: Icon(
                        isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
                        color: isDark ? const Color(0xFFFFD60A) : const Color(0xFF5856D6),
                        size: 22,
                      ),
                      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      onPressed: () {
                        context.read<ThemeProvider>().toggleTheme();
                      },
                    ),

                    // Gemini AI Sparkle Icon
                    IconButton(
                      icon: const Icon(CupertinoIcons.sparkles, color: Colors.amber, size: 24),
                      tooltip: 'Gemini AI Vibe Playlist',
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

                    // User Profile / Admin Avatar (Image 3)
                    GestureDetector(
                      onLongPress: () {
                        if (adminService.isAdminLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
                          );
                        } else {
                          showAdminPinDialog(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: adminService.isAdminLoggedIn
                              ? const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFFF9500)])
                              : const LinearGradient(colors: [Color(0xFFFA2D48), Color(0xFF5856D6)]),
                        ),
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          child: Icon(
                            adminService.isAdminLoggedIn ? Icons.admin_panel_settings : CupertinoIcons.person_fill,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Three dots overflow menu
                    FrostedCircleButton(
                      icon: CupertinoIcons.ellipsis,
                      size: 36,
                      iconSize: 18,
                      onPressed: () {
                        _showHomeOptions(context, provider);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Radio Mixes Grid (Image 3 - My Supermix, Discover Mix, etc.)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildRadioMixGrid(context, provider),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // "Your Mixes" Section (Image 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Mixes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        provider.generateMadeForYouMix();
                        provider.loadTopSongs();
                      },
                      child: Row(
                        children: [
                          Icon(
                            provider.isLoadingMix ? CupertinoIcons.arrow_2_circlepath : CupertinoIcons.refresh,
                            size: 14,
                            color: AppTheme.accentColor1,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            provider.isLoadingMix ? 'Refreshing...' : 'Refresh',
                            style: const TextStyle(
                              color: AppTheme.accentColor1,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Your Mixes Horizontal Carousel (Image 3)
            SliverToBoxAdapter(
              child: _buildYourMixesCarousel(context, provider, textColor, subtextColor, isDark),
            ),

            // ── Trending Now ──
            if (provider.topSongs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    'Trending Now 🔥',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalSongList(context, provider.topSongs, provider, textColor, subtextColor),
              ),
            ] else if (provider.isLoadingLibrary) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    'Trending Now 🔥',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 185,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.accentColor1, strokeWidth: 2.5),
                  ),
                ),
              ),
            ],

            // ── Trending Tamil ──
            if (provider.trendingTamil.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    'Trending Tamil 🎶',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalSongList(context, provider.trendingTamil, provider, textColor, subtextColor),
              ),
            ],

            // ── Trending Malayalam ──
            if (provider.trendingMalayalam.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    'Trending Malayalam 🎶',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalSongList(context, provider.trendingMalayalam, provider, textColor, subtextColor),
              ),
            ],

            // ── Recently Played ──
            if (provider.recentlyPlayed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    'Recently Played 🎧',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalSongList(context, provider.recentlyPlayed, provider, textColor, subtextColor),
              ),
            ],

            // ── Admin Catalog Songs / New Releases ──
            if (adminService.catalogSongs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    'New Releases 🎵',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalSongList(context, adminService.catalogSongs, provider, textColor, subtextColor),
              ),
            ],

            // ── Top Artists ──
            if (topArtists.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    'Top Artists',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildTopArtists(context, topArtists, textColor),
              ),
            ],

            // ── Your Favorites ──
            if (provider.favorites.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Favorites',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(color: AppTheme.accentColor1, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildHorizontalSongList(context, provider.favorites, provider, textColor, subtextColor),
              ),
            ],

            // ── Quick Gemini AI Recommendation Banner ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                child: _buildGeminiAiCard(context, isDark),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  /// 2-Column Grid of Radio Mix Cards (Image 3)
  Widget _buildRadioMixGrid(BuildContext context, MusicProvider provider) {
    final mixes = [
      {
        'title': 'My Supermix',
        'gradient': const [Color(0xFF2C3E50), Color(0xFF1E272C)],
        'action': () => _playMixPreset(context, provider, 'Supermix'),
      },
      {
        'title': 'Discover Mix',
        'gradient': const [Color(0xFF1F1C2C), Color(0xFF2C3E50)],
        'action': () => _playMixPreset(context, provider, 'Discover'),
      },
      {
        'title': 'New Release Mix',
        'gradient': const [Color(0xFF5F0A87), Color(0xFFA4508B)],
        'action': () => _playMixPreset(context, provider, 'New Releases'),
      },
      {
        'title': 'Replay Mix',
        'gradient': const [Color(0xFF4A2810), Color(0xFF6B4423)],
        'action': () => _playMixPreset(context, provider, 'Replay'),
      },
      {
        'title': 'Liked Music',
        'gradient': const [Color(0xFFFA2D48), Color(0xFFFF375F)],
        'action': () {
          if (provider.favorites.isNotEmpty) {
            provider.playSong(provider.favorites.first, playlist: provider.favorites);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No liked songs yet! Like songs to play this mix.')),
            );
          }
        },
      },
      {
        'title': 'Chill Radio',
        'gradient': const [Color(0xFF0F2027), Color(0xFF203A43)],
        'action': () => _playMixPreset(context, provider, 'Chill'),
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = screenWidth > 1200 ? 6 : (screenWidth > 750 ? 4 : 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mixes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final mix = mixes[index];
        final gradientColors = mix['gradient'] as List<Color>;
        final title = mix['title'] as String;
        final action = mix['action'] as VoidCallback;

        return GestureDetector(
          onTap: action,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.40),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: RadioWaveIcon(
                      size: 28,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _playMixPreset(BuildContext context, MusicProvider provider, String name) {
    if (provider.topSongs.isNotEmpty) {
      final shuffled = List<Song>.from(provider.topSongs)..shuffle();
      provider.playSong(shuffled.first, playlist: shuffled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing $name Mix 📻'),
          backgroundColor: const Color(0xFF22242B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      provider.generateMadeForYouMix();
    }
  }

  /// "Your Mixes" carousel (Image 3)
  Widget _buildYourMixesCarousel(BuildContext context, MusicProvider provider, Color textColor, Color subtextColor, bool isDark) {
    final mixNames = ['My Mix 01', 'My Mix 02', 'Vibe Mix 03', 'Focus Mix', 'Party Mix'];
    final gradients = [
      [const Color(0xFF141E30), const Color(0xFF243B55)],
      [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
      [const Color(0xFF4B1248), const Color(0xFFF0C27B)],
      [const Color(0xFF000428), const Color(0xFF004e92)],
      [const Color(0xFF3A1C71), const Color(0xFFD76D77)],
    ];

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: mixNames.length,
        itemBuilder: (context, index) {
          final name = mixNames[index];
          final grad = gradients[index % gradients.length];

          return GestureDetector(
            onTap: () => _playMixPreset(context, provider, name),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: grad,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.15,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                            child: const Icon(CupertinoIcons.play_fill, color: Colors.white, size: 24),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Text(
                            '0${index + 1}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Infinite station',
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalSongList(BuildContext context, List<Song> songs, MusicProvider provider, Color textColor, Color subtextColor) {
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
            onTap: () => provider.playSong(song, playlist: songs),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        AlbumArt(
                          song: song,
                          width: 130,
                          height: 130,
                          iconSize: 44,
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => SongActionSheet.show(context, song),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.55),
                              ),
                              child: const Icon(CupertinoIcons.ellipsis, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (song.isExplicit) const ExplicitBadge(size: 11),
                      Expanded(
                        child: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtextColor,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopArtists(BuildContext context, List<Map<String, String>> artists, Color textColor) {
    return SizedBox(
      height: 135,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
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
              width: 90,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      image: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                          ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: imageUrl.isEmpty || !imageUrl.startsWith('http')
                        ? const Icon(CupertinoIcons.person_fill, color: Colors.white54, size: 32)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeminiAiCard(BuildContext context, bool isDark) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF380C66), Color(0xFF1E0E3D), Color(0xFF0F0824)]
                    : const [Color(0xFFEFE8FF), Color(0xFFF7F2FF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isDark ? const Color(0xFFB366FF).withValues(alpha: 0.45) : const Color(0xFF9D4EDD).withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A2387).withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF375F), Color(0xFF8E2DE2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E2DE2).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Gemini AI Vibe Matcher',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Describe any vibe, mood, or scene for an instant smart mix',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF6E6E73),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: isDark ? Colors.white54 : Colors.black45,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHomeOptions(BuildContext context, MusicProvider provider) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF141923) : Colors.white).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(CupertinoIcons.folder, color: isDark ? Colors.white : Colors.black87),
                title: Text(
                  'Offline Local Files',
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1E)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onLocalLibraryTapped();
                },
              ),
              ListTile(
                leading: Icon(
                  isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
                  color: isDark ? const Color(0xFFFFD60A) : const Color(0xFF5856D6),
                ),
                title: Text(
                  isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1E)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ThemeProvider>().toggleTheme();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
