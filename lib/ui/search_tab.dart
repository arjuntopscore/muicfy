import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../api_service.dart';
import '../song_model.dart';
import 'theme.dart';
import 'album_art.dart';
import 'search_library_screen.dart';

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
  bool _hasSearched = false;
  Timer? _debounce;

  /// Keywords that indicate the user wants a browsable library, not a single song.
  static const _libraryKeywords = [
    'songs', 'music', 'hits', 'playlist', 'collection',
    'best', 'top', 'new', 'latest', 'old', 'classic',
    'rap', 'hip hop', 'rock', 'pop', 'jazz', 'lofi',
    'romantic', 'love', 'sad', 'happy', 'party', 'dance',
    'devotional', 'chill', 'workout', 'study',
  ];

  /// Language keywords that when combined with music terms suggest a library
  static const _languageKeywords = [
    'malayalam', 'tamil', 'hindi', 'telugu', 'kannada',
    'bengali', 'punjabi', 'marathi', 'english', 'korean',
  ];

  /// Check if the query looks like a library/genre search
  bool _isLibrarySearch(String query) {
    final q = query.toLowerCase().trim();
    final words = q.split(RegExp(r'\s+'));
    
    // Must have at least 2 words to be a library search
    if (words.length < 2) return false;

    final hasLanguage = _languageKeywords.any((lang) => q.contains(lang));
    final hasLibraryKeyword = _libraryKeywords.any((kw) => q.contains(kw));

    // "malayalam songs", "tamil rap songs", "hindi romantic songs", etc.
    return hasLanguage && hasLibraryKeyword;
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = false;
    });

    final results = await _apiService.searchSongs(query);

    // Prioritize Tamil and Malayalam songs
    results.sort((a, b) {
      bool aIsPriority = a.language == 'tamil' || a.language == 'malayalam';
      bool bIsPriority = b.language == 'tamil' || b.language == 'malayalam';
      if (aIsPriority && !bIsPriority) return -1;
      if (!aIsPriority && bIsPriority) return 1;
      return 0; // maintain original order otherwise
    });

    if (mounted) {
      // Check if this is a library-style search
      if (_isLibrarySearch(query) && results.isNotEmpty) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
        });
        // Navigate to the library view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchLibraryScreen(
              query: query,
              initialResults: results,
            ),
          ),
        );
      } else {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasSearched = true;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'What do you want to listen to?',
                  hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.black, size: 28),
                  suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {}); // update suffix icon
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (text) {
                  setState(() {}); // to toggle the clear button
                  _onSearchChanged(text);
                },
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),

          // Library search hint
          if (_searchController.text.isNotEmpty && _isLibrarySearch(_searchController.text))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _performSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor1.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.library_music, color: AppTheme.accentColor1, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Browse "${_searchController.text}" as a library',
                          style: const TextStyle(color: AppTheme.accentColor1, fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: AppTheme.accentColor1, size: 14),
                    ],
                  ),
                ),
              ),
            ),

          Expanded(
            child: _isSearching
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.accentColor1),
                        SizedBox(height: 16),
                        Text('Finding your song...', style: TextStyle(color: Color(0xFFB3B3B3))),
                      ],
                    ),
                  )
                : _searchResults.isEmpty
                    ? (provider.recentSearches.isEmpty
                        ? Center(
                            child: _hasSearched 
                                ? const Text('No results for that one. Try a different search?', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center)
                                : const Text('Search for a song, artist, or album', style: TextStyle(color: Color(0xFFB3B3B3)), textAlign: TextAlign.center),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Recent Searches', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 100),
                                  itemCount: provider.recentSearches.length,
                                  itemBuilder: (context, index) {
                                    final song = provider.recentSearches[index];
                                    return ListTile(
                                      leading: AlbumArt(
                                        song: song,
                                        width: 50,
                                        height: 50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white54),
                                        onPressed: () => provider.removeFromRecentSearches(song),
                                      ),
                                      onTap: () {
                                        provider.addToRecentSearches(song); // push to top
                                        provider.playSong(song, playlist: [song]);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final song = _searchResults[index];
                          return ListTile(
                            leading: AlbumArt(
                              song: song,
                              width: 50,
                              height: 50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              provider.addToRecentSearches(song);
                              provider.playSong(song, playlist: _searchResults);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
