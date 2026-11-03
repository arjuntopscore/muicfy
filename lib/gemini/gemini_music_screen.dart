import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_service.dart';
import '../music_provider.dart';
import '../song_model.dart';
import '../ui/mini_player.dart';
import '../ui/queue_screen.dart';
import 'gemini_music_service.dart';
import 'models/semantic_song_match.dart';
import 'models/vibe_playlist.dart';

/// Ultra-modern, Glassmorphism-styled screen for Gemini AI music generation & search.
/// Fully integrated with the app's audio playback and queue system.
class GeminiMusicScreen extends StatefulWidget {
  final String geminiApiKey;

  const GeminiMusicScreen({
    super.key,
    required this.geminiApiKey,
  });

  @override
  State<GeminiMusicScreen> createState() => _GeminiMusicScreenState();
}

class _GeminiMusicScreenState extends State<GeminiMusicScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final GeminiMusicService _musicService;
  final ApiService _apiService = ApiService();

  // Controllers
  final TextEditingController _vibeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // State: Vibe Playlist
  bool _isLoadingVibe = false;
  String? _vibeError;
  VibePlaylist? _playlist;

  // State: Semantic Search
  bool _isLoadingSearch = false;
  String? _searchError;
  List<SemanticSongMatch>? _searchResults;

  // Playback & Queue State
  final Map<String, Song> _resolvedSongsCache = {};
  final Set<String> _resolvingTrackKeys = {};
  bool _isQueueLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _musicService = GeminiMusicService(
      apiKey: widget.geminiApiKey,
      defaultModel: 'gemini-flash-lite-latest',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vibeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // AI Request Handlers
  // ---------------------------------------------------------------------------

  Future<void> _generatePlaylist([String? promptOverride]) async {
    final query = promptOverride ?? _vibeController.text.trim();
    if (query.isEmpty) return;

    if (promptOverride != null) {
      _vibeController.text = promptOverride;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoadingVibe = true;
      _vibeError = null;
    });

    try {
      final result = await _musicService.generateVibePlaylist(query);
      setState(() {
        _playlist = result;
        _isLoadingVibe = false;
      });
    } on GeminiMusicException catch (e) {
      setState(() {
        _vibeError = e.message;
        _isLoadingVibe = false;
      });
    } catch (e) {
      setState(() {
        _vibeError = 'Failed to generate playlist. Please try again.';
        _isLoadingVibe = false;
      });
    }
  }

  Future<void> _performSemanticSearch([String? queryOverride]) async {
    final query = queryOverride ?? _searchController.text.trim();
    if (query.isEmpty) return;

    if (queryOverride != null) {
      _searchController.text = queryOverride;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoadingSearch = true;
      _searchError = null;
    });

    try {
      final results = await _musicService.searchByDescription(query);
      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    } on GeminiMusicException catch (e) {
      setState(() {
        _searchError = e.message;
        _isLoadingSearch = false;
      });
    } catch (e) {
      setState(() {
        _searchError = 'Search failed. Please try a different clue or phrase.';
        _isLoadingSearch = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Playback & Queue Integration
  // ---------------------------------------------------------------------------

  String _cacheKey(String title, String artist) =>
      '${title.toLowerCase().trim()}-${artist.toLowerCase().trim()}';

  /// Resolves an AI recommended track into a playable `Song` from the streaming API
  Future<Song?> _resolveTrack(String title, String artist) async {
    final key = _cacheKey(title, artist);
    if (_resolvedSongsCache.containsKey(key)) {
      return _resolvedSongsCache[key];
    }

    try {
      // 1. Search with title and artist
      var results = await _apiService.searchSongs('$title $artist', limit: 3);
      if (results.isEmpty) {
        // 2. Fallback to title only
        results = await _apiService.searchSongs(title, limit: 3);
      }

      if (results.isNotEmpty) {
        final song = results.first;
        _resolvedSongsCache[key] = song;
        return song;
      }
    } catch (_) {
      // Ignore API lookup errors
    }
    return null;
  }

  /// Plays a single song directly
  Future<void> _playSingleTrack(String title, String artist) async {
    final key = _cacheKey(title, artist);
    setState(() => _resolvingTrackKeys.add(key));

    final song = await _resolveTrack(title, artist);
    setState(() => _resolvingTrackKeys.remove(key));

    if (!mounted) return;
    final provider = context.read<MusicProvider>();

    if (song != null) {
      provider.playSong(song);
      _showToast('Playing "$title" 🎵');
    } else {
      _showToast('Could not find stream for "$title". Try another track.', isError: true);
    }
  }

  /// Adds a single song to the current playback queue
  Future<void> _addTrackToQueue(String title, String artist) async {
    final key = _cacheKey(title, artist);
    setState(() => _resolvingTrackKeys.add(key));

    final song = await _resolveTrack(title, artist);
    setState(() => _resolvingTrackKeys.remove(key));

    if (!mounted) return;
    final provider = context.read<MusicProvider>();

    if (song != null) {
      provider.addSongToQueue(song);
      _showToast('Added "$title" to Queue 🎧');
    } else {
      _showToast('Could not find stream for "$title".', isError: true);
    }
  }

  /// Plays the entire vibe playlist and sets it as the active playback queue
  Future<void> _playEntirePlaylistWithQueue(VibePlaylist playlist) async {
    if (playlist.songs.isEmpty) return;

    setState(() => _isQueueLoading = true);
    final provider = context.read<MusicProvider>();

    // Step 1: Resolve the very first track and start playing immediately
    final firstVibe = playlist.songs.first;
    final firstSong = await _resolveTrack(firstVibe.title, firstVibe.artist);

    if (!mounted) return;

    if (firstSong != null) {
      provider.playSong(firstSong);
      _showToast('Playing "${firstSong.title}" & building queue... 🚀');
    }

    // Step 2: Resolve remaining songs in parallel and build the full queue
    final List<Song> resolvedQueue = [];
    if (firstSong != null) resolvedQueue.add(firstSong);

    for (int i = 1; i < playlist.songs.length; i++) {
      final item = playlist.songs[i];
      final song = await _resolveTrack(item.title, item.artist);
      if (song != null && !resolvedQueue.any((s) => s.id == song.id)) {
        resolvedQueue.add(song);
        provider.addSongToQueue(song);
      }
    }

    if (mounted) {
      setState(() => _isQueueLoading = false);
      _showToast('Queued ${resolvedQueue.length} tracks from your vibe playlist! ✨');
    }
  }

  /// Saves the current AI playlist into User Playlists
  Future<void> _savePlaylist(VibePlaylist playlist) async {
    final provider = context.read<MusicProvider>();
    final List<Song> resolvedSongs = [];

    _showToast('Resolving tracks to save playlist...');
    for (final song in playlist.songs) {
      final s = await _resolveTrack(song.title, song.artist);
      if (s != null) resolvedSongs.add(s);
    }

    if (resolvedSongs.isNotEmpty) {
      provider.createPlaylist(playlist.prompt, initialSongs: resolvedSongs);
      _showToast('Saved "${playlist.prompt}" with ${resolvedSongs.length} tracks! 📁');
    } else {
      _showToast('Could not resolve tracks to save.', isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1DB954),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build Method & Modern UI Layout
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MusicProvider>();
    final queueLength = provider.currentPlaylist.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C14) : const Color(0xFFF7F8FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: (isDark ? const Color(0xFF0C0C14) : Colors.white)
            .withValues(alpha: 0.75),
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'Gemini AI Studio',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Open Queue Screen Button
          IconButton(
            tooltip: 'View Queue',
            icon: Badge(
              isLabelVisible: queueLength > 0,
              label: Text('$queueLength'),
              backgroundColor: const Color(0xFF1DB954),
              child: const Icon(Icons.queue_music),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => QueueScreen(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildModernTabBar(isDark),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVibePlaylistTab(isDark),
                _buildSemanticSearchTab(isDark),
              ],
            ),
          ),
          // Integrated MiniPlayer at bottom of screen
          const MiniPlayer(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Modern Segmented Tab Bar
  // ---------------------------------------------------------------------------

  Widget _buildModernTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8A2387), Color(0xFFE94057)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE94057).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune, size: 16),
                SizedBox(width: 6),
                Text('Vibe Playlist'),
              ],
            ),
          ),
          Tab(
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.saved_search, size: 18),
                SizedBox(width: 6),
                Text('Semantic Search'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Vibe Playlist
  // ---------------------------------------------------------------------------

  Widget _buildVibePlaylistTab(bool isDark) {
    return SafeArea(
      top: true,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          // Prompt Input Card
          _buildGlassContainer(
            isDark: isDark,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What vibe are you chasing?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _vibeController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. 45-minute playlist for a rainy commute to work...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onSubmitted: (_) => _generatePlaylist(),
                ),
                const SizedBox(height: 12),

                // Quick Inspiration Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModernChip(
                        '🌧️ Rainy Commute (45 min)',
                        () => _generatePlaylist('Create a 45-minute playlist for a rainy commute to work'),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildModernChip(
                        '☕ Sunday Coffee (30 min)',
                        () => _generatePlaylist('Chill acoustic vibes for a cozy Sunday morning coffee (30 min)'),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildModernChip(
                        '⚡ Synthwave Workout (40 min)',
                        () => _generatePlaylist('High energy fast-paced synthwave for a 40 min run'),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildModernChip(
                        '🌙 Late Night Focus (1 hr)',
                        () => _generatePlaylist('Deep focus ambient lo-fi for 1 hour of coding'),
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE94057).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingVibe ? null : () => _generatePlaylist(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: _isLoadingVibe
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      label: Text(
                        _isLoadingVibe ? 'Curating Tracks with Gemini...' : 'Generate Vibe Playlist',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Playlist Result Content Area
          if (_isLoadingVibe) ...[
            _buildLoadingState('Gemini is tailoring song durations to match your vibe...'),
          ] else if (_vibeError != null) ...[
            _buildErrorState(_vibeError!, () => _generatePlaylist()),
          ] else if (_playlist != null) ...[
            _buildPlaylistHeaderCard(_playlist!, isDark),
            const SizedBox(height: 16),
            ..._playlist!.songs.asMap().entries.map((entry) {
              return _buildVibeSongTile(entry.key, entry.value, _playlist!, isDark);
            }),
          ] else ...[
            _buildEmptyState(
              icon: Icons.graphic_eq_rounded,
              title: 'No playlist created yet',
              subtitle: 'Type a mood, vibe, or target minutes to let Gemini curate your tracklist.',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaylistHeaderCard(VibePlaylist playlist, bool isDark) {
    return _buildGlassContainer(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.prompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.trackCount} Tracks • Total Duration: ${playlist.totalDurationFormatted}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Play All & Save Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: _isQueueLoading
                      ? null
                      : () => _playEntirePlaylistWithQueue(playlist),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: _isQueueLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    _isQueueLoading ? 'Queuing Tracks...' : 'Play All with Queue',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _savePlaylist(playlist),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVibeSongTile(int index, VibeSong song, VibePlaylist playlist, bool isDark) {
    final provider = context.watch<MusicProvider>();
    final key = _cacheKey(song.title, song.artist);
    final isResolving = _resolvingTrackKeys.contains(key);
    final isCurrentlyPlaying = provider.currentSong != null &&
        provider.currentSong!.title.toLowerCase() == song.title.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: _buildGlassContainer(
        isDark: isDark,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderColor: isCurrentlyPlaying
            ? const Color(0xFF1DB954).withValues(alpha: 0.8)
            : null,
        child: Row(
          children: [
            // Track Index or Equalizer Wave
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrentlyPlaying
                    ? const Color(0xFF1DB954).withValues(alpha: 0.15)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isCurrentlyPlaying
                    ? const Icon(Icons.equalizer_rounded, color: Color(0xFF1DB954), size: 18)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCurrentlyPlaying ? const Color(0xFF1DB954) : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${song.artist} • ${song.album}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A11CB).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          song.genre,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9D65F3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        song.formattedDuration,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions: Play Now & Add To Queue
            if (isResolving) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ] else ...[
              IconButton(
                tooltip: 'Add to Queue',
                icon: const Icon(Icons.queue_music, size: 20),
                onPressed: () => _addTrackToQueue(song.title, song.artist),
              ),
              IconButton(
                tooltip: 'Play Song',
                icon: Icon(
                  isCurrentlyPlaying && provider.audioPlayer.playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 32,
                  color: const Color(0xFF1DB954),
                ),
                onPressed: () {
                  if (isCurrentlyPlaying) {
                    if (provider.audioPlayer.playing) {
                      provider.audioPlayer.pause();
                    } else {
                      provider.audioPlayer.play();
                    }
                  } else {
                    _playSingleTrack(song.title, song.artist);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Semantic Audio Search
  // ---------------------------------------------------------------------------

  Widget _buildSemanticSearchTab(bool isDark) {
    return SafeArea(
      top: true,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          // Search Input Card
          _buildGlassContainer(
            isDark: isDark,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search with memories, scenes, or sound',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. the song from the end of Fight Club...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onSubmitted: (_) => _performSemanticSearch(),
                ),
                const SizedBox(height: 12),

                // Quick Clue Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModernChip(
                        '🎬 End of Fight Club',
                        () => _performSemanticSearch('the song from the end of Fight Club'),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildModernChip(
                        '🎹 80s synth-pop heavy bass',
                        () => _performSemanticSearch('that 80s synth-pop song with the heavy bassline'),
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildModernChip(
                        '🤠 Whistling Western duel',
                        () => _performSemanticSearch('famous whistling theme song from western standoff duel'),
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2575FC), Color(0xFF6A11CB)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2575FC).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingSearch ? null : () => _performSemanticSearch(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: _isLoadingSearch
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.manage_search_rounded, color: Colors.white, size: 22),
                      label: Text(
                        _isLoadingSearch ? 'Identifying Song Clues...' : 'Find Matches with Gemini',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Search Results
          if (_isLoadingSearch) ...[
            _buildLoadingState('Scouring soundtrack databases and musical archives...'),
          ] else if (_searchError != null) ...[
            _buildErrorState(_searchError!, () => _performSemanticSearch()),
          ] else if (_searchResults != null) ...[
            ..._searchResults!.asMap().entries.map((entry) {
              return _buildSemanticMatchCard(entry.key, entry.value, isDark);
            }),
          ] else ...[
            _buildEmptyState(
              icon: Icons.search_rounded,
              title: 'Discover songs by description',
              subtitle: 'Describe an instrument, movie moment, or forgotten lyric to identify it.',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSemanticMatchCard(int index, SemanticSongMatch match, bool isDark) {
    final isTopMatch = index == 0;
    final key = _cacheKey(match.title, match.artist);
    final isResolving = _resolvingTrackKeys.contains(key);
    final provider = context.watch<MusicProvider>();
    final isCurrentlyPlaying = provider.currentSong != null &&
        provider.currentSong!.title.toLowerCase() == match.title.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: _buildGlassContainer(
        isDark: isDark,
        padding: const EdgeInsets.all(16),
        borderColor: isTopMatch
            ? const Color(0xFF1DB954).withValues(alpha: 0.8)
            : (isCurrentlyPlaying ? const Color(0xFF6A11CB) : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Confidence Badge & Release Year
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: isTopMatch
                        ? const LinearGradient(colors: [Color(0xFF1DB954), Color(0xFF1ED760)])
                        : null,
                    color: isTopMatch
                        ? null
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isTopMatch ? '★ Best Match #1' : 'Candidate #${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isTopMatch ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
                Text(
                  'Year: ${match.releaseYear}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title & Artist
            Text(
              match.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCurrentlyPlaying ? const Color(0xFF1DB954) : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${match.artist} • ${match.album}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // AI Match Reason Callout Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.matchReason,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Play & Queue Actions
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isResolving
                        ? null
                        : () => _playSingleTrack(match.title, match.artist),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: isResolving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      isCurrentlyPlaying && provider.audioPlayer.playing ? 'Now Playing' : 'Play Song',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: isResolving
                      ? null
                      : () => _addTrackToQueue(match.title, match.artist),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                  icon: const Icon(Icons.queue_music, size: 18),
                  label: const Text('Add to Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Modern Reusable Helpers
  // ---------------------------------------------------------------------------

  Widget _buildGlassContainer({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? borderColor,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141422) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ??
              (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
          width: borderColor != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildModernChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
        child: Column(
          children: [
            Icon(
              icon,
              size: 56,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
