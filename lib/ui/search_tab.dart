import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../admin_service.dart';
import '../api_service.dart';
import '../theme_provider.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';
import 'search_library_screen.dart';
import 'song_action_sheet.dart';
import 'apple_music_widgets.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Song> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  // Tabs: 0 = "APPLE MUSIC", 1 = "YOUR LIBRARY" (Image 4)
  int _selectedSearchSourceTab = 0;

  // Filter chips: "All", "Songs", "Videos", "Albums", "Artists" (Image 0)
  int _selectedFilterIndex = 0;
  final List<String> _filterChips = ['All', 'Songs', 'Videos', 'Albums', 'Artists'];

  /// Keywords that indicate the user wants a browsable library, not a single song.
  static const _libraryKeywords = [
    'songs', 'music', 'hits', 'playlist', 'collection',
    'best', 'top', 'new', 'latest', 'old', 'classic',
    'rap', 'hip hop', 'rock', 'pop', 'jazz', 'lofi',
    'romantic', 'love', 'sad', 'happy', 'party', 'dance',
    'devotional', 'chill', 'workout', 'study',
  ];

  static const _languageKeywords = [
    'malayalam', 'tamil', 'hindi', 'telugu', 'kannada',
    'bengali', 'punjabi', 'marathi', 'english', 'korean',
  ];

  bool _isLibrarySearch(String query) {
    final q = query.toLowerCase().trim();
    final words = q.split(RegExp(r'\s+'));
    if (words.length < 2) return false;

    final hasLanguage = _languageKeywords.any((lang) => q.contains(lang));
    final hasLibraryKeyword = _libraryKeywords.any((kw) => q.contains(kw));
    return hasLanguage && hasLibraryKeyword;
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final provider = context.read<MusicProvider>();
    final adminService = context.read<AdminService>();
    final queryLower = query.toLowerCase();

    // If "YOUR LIBRARY" is selected (Image 4)
    if (_selectedSearchSourceTab == 1) {
      final libraryMatches = [
        ...provider.localLibrary,
        ...provider.favorites,
      ].where((s) =>
        s.title.toLowerCase().contains(queryLower) ||
        s.artist.toLowerCase().contains(queryLower)
      ).toSet().toList();

      setState(() {
        _searchResults = libraryMatches;
        _isSearching = false;
      });
      return;
    }

    // Otherwise search Apple Music / Saavn API
    final results = await _apiService.searchSongs(query, limit: 20);

    final catalogMatches = adminService.catalogSongs.where((song) {
      return song.title.toLowerCase().contains(queryLower) ||
          song.artist.toLowerCase().contains(queryLower) ||
          song.language.toLowerCase().contains(queryLower);
    }).toList();

    final existingIds = results.map((s) => s.id).toSet();
    final mergedResults = [
      ...catalogMatches.where((s) => !existingIds.contains(s.id)),
      ...results,
    ];

    if (mounted) {
      if (_isLibrarySearch(query) && mergedResults.isNotEmpty) {
        setState(() {
          _isSearching = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchLibraryScreen(
              query: query,
              initialResults: mergedResults,
            ),
          ),
        );
      } else {
        setState(() {
          _searchResults = mergedResults;
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    final timer = _debounce;
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch();
    });
  }

  @override
  void dispose() {
    final timer = _debounce;
    if (timer != null) {
      timer.cancel();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF6E6E73);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFFEDF2F7),
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFFE2EAF8),
                  Color(0xFFF1EEFB),
                  Color(0xFFEDF2F7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Search Bar (Image 0 & Image 4)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1E) : Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.92),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search songs, artists, albums...',
                                hintStyle: TextStyle(
                                  color: subtextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  CupertinoIcons.search,
                                  color: subtextColor,
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(CupertinoIcons.clear_circled_solid, color: subtextColor, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (text) {
                                setState(() {});
                                _onSearchChanged(text);
                              },
                              onSubmitted: (_) => _performSearch(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Theme toggle button
                    FrostedCircleButton(
                      icon: isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
                      size: 40,
                      iconSize: 18,
                      iconColor: isDark ? const Color(0xFFFFD60A) : const Color(0xFF5856D6),
                      onPressed: () {
                        context.read<ThemeProvider>().toggleTheme();
                      },
                    ),

                    const SizedBox(width: 6),

                    // Three dots overflow action button (Image 0)
                    FrostedCircleButton(
                      icon: CupertinoIcons.ellipsis,
                      size: 40,
                      iconSize: 18,
                      onPressed: () {
                        _showSearchMenu(context, isDark, textColor);
                      },
                    ),
                  ],
                ),
              ),

            // Tab bar: "APPLE MUSIC" and "YOUR LIBRARY" (Image 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildSearchSourceTab(0, 'APPLE MUSIC', subtextColor),
                  const SizedBox(width: 24),
                  _buildSearchSourceTab(1, 'YOUR LIBRARY', subtextColor),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Filter chips horizontal row: "All", "Songs", "Videos", "Albums", "Artists" (Image 0)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterChips.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  final title = _filterChips[index];

                  final chipBg = isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? const Color(0xFF1E2430).withValues(alpha: 0.8) : Colors.white);
                  final chipText = isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : textColor;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
                          ),
                          boxShadow: (!isSelected && !isDark)
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          title,
                          style: TextStyle(
                            color: chipText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Section Header: "Songs" (Image 0)
            if (_searchResults.isNotEmpty || provider.recentSearches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                child: Text(
                  _searchResults.isNotEmpty ? 'Songs' : 'Recent Searches',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

            // Results List
            Expanded(
              child: _isSearching
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: AppTheme.accentColor1, strokeWidth: 2.5),
                          const SizedBox(height: 14),
                          Text('Searching catalog...', style: TextStyle(color: subtextColor)),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                      ? (_searchController.text.isNotEmpty
                          ? Center(
                              child: Text(
                                'No matching songs found',
                                style: TextStyle(color: subtextColor),
                              ),
                            )
                          : _buildRecentSearchesList(context, provider, textColor, subtextColor))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 90, top: 4),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final song = _searchResults[index];
                            final current = provider.currentSong;
                            final isPlayingCurrent = current != null && current.id == song.id;

                            return _buildSongItemTile(
                              context,
                              song: song,
                              isPlaying: isPlayingCurrent,
                              textColor: textColor,
                              subtextColor: subtextColor,
                              onTap: () {
                                provider.addToRecentSearches(song);
                                provider.playSong(
                                  song,
                                  playlist: _searchResults,
                                  searchQuery: _searchController.text.trim(),
                                );
                              },
                              onMoreTap: () => SongActionSheet.show(context, song),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSearchSourceTab(int tabIndex, String label, Color subtextColor) {
    final isSelected = _selectedSearchSourceTab == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSearchSourceTab = tabIndex;
        });
        if (_searchController.text.isNotEmpty) {
          _performSearch();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0A84FF) : subtextColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2.5,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongItemTile(
    BuildContext context, {
    required Song song,
    required bool isPlaying,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
    required VoidCallback onMoreTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 50,
              height: 50,
              child: AlbumArt(
                song: song,
                width: 50,
                height: 50,
                iconSize: 26,
              ),
            ),
          ),
          if (isPlaying)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.waveform,
                  color: AppTheme.accentColor1,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          if (song.isExplicit) const ExplicitBadge(size: 12),
          Expanded(
            child: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isPlaying ? AppTheme.accentColor1 : textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: subtextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      trailing: IconButton(
        icon: Icon(CupertinoIcons.ellipsis, color: subtextColor, size: 18),
        onPressed: onMoreTap,
      ),
      onTap: onTap,
    );
  }

  Widget _buildRecentSearchesList(BuildContext context, MusicProvider provider, Color textColor, Color subtextColor) {
    if (provider.recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.music_note_2,
              size: 54,
              color: subtextColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Search songs, artists, or genres',
              style: TextStyle(
                color: subtextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: provider.recentSearches.length,
      itemBuilder: (context, index) {
        final song = provider.recentSearches[index];
        final current = provider.currentSong;
        final isPlayingCurrent = current != null && current.id == song.id;

        return _buildSongItemTile(
          context,
          song: song,
          isPlaying: isPlayingCurrent,
          textColor: textColor,
          subtextColor: subtextColor,
          onTap: () {
            provider.addToRecentSearches(song);
            provider.playSong(song, playlist: provider.recentSearches);
          },
          onMoreTap: () => SongActionSheet.show(context, song),
        );
      },
    );
  }

  void _showSearchMenu(BuildContext context, bool isDark, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2B) : Colors.white,
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
              leading: Icon(CupertinoIcons.trash, color: textColor),
              title: Text('Clear Search History', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MusicProvider>().recentSearches.clear();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
