import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'song_model.dart';
import 'api_service.dart';
import 'song_history_event.dart';
import 'playlist_model.dart';
import 'custom_audio_handler.dart';

import 'main.dart'; // To access scaffoldMessengerKey

enum PlaybackRepeatMode { off, all, one }

class MusicProvider extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  final ApiService _apiService = ApiService();
  CustomAudioHandler? _audioHandler;

  Song? currentSong;
  List<Song> localLibrary = [];
  List<Song> recentlyPlayed = [];
  List<Song> recentSearches = [];
  List<Song> topSongs = [];
  List<Song> favorites = [];
  List<Song> trendingTamil = [];
  List<Song> trendingMalayalam = [];
  List<Playlist> userPlaylists = [];
  String userName = '';
  List<SongHistoryEvent> playbackHistory = [];
  
  bool isLoadingLibrary = true;

  // ── Sleep Timer ──
  Timer? _sleepTimer;
  Duration? sleepTimerRemaining;
  Timer? _sleepCountdown;

  // ── Made For You ──
  List<Song> madeForYouMix = [];
  bool isLoadingMix = false;

  MusicProvider() {
    _init();
    _configureAudioSession();
    _initAudioHandler();
    
    // Automatically play next song when current finishes
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _recordPlaybackEvent();
        playNext();
      }
    });
  }

  /// Initialize the custom audio handler for notification controls.
  /// This replaces just_audio_background to give us control over
  /// skip next/previous from the notification.
  Future<void> _initAudioHandler() async {
    _audioHandler = await AudioService.init(
      builder: () => CustomAudioHandler(audioPlayer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_app.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
        notificationColor: Color(0xFF1DB954),
      ),
    );
    _audioHandler!.onSkipToNext = playNext;
    _audioHandler!.onSkipToPrevious = playPrevious;
    _audioHandler!.onStop = () {
      audioPlayer.stop();
      currentSong = null;
      notifyListeners();
    };
  }

  /// Configure audio session for proper background playback and audio focus
  /// handling. This fixes issues on Nothing CMF and similar devices where
  /// the notification background doesn't persist and audio auto-pauses.
  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
        flags: AndroidAudioFlags.none,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    ));

    bool _wasPlayingBeforeInterruption = false;

    // Handle audio interruptions (phone calls, other apps, etc.)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Lower volume temporarily instead of pausing
            audioPlayer.setVolume(0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _wasPlayingBeforeInterruption = audioPlayer.playing;
            audioPlayer.pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Restore volume
            audioPlayer.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            // Resume playback after interruption ends ONLY if it was playing before
            if (_wasPlayingBeforeInterruption) {
              audioPlayer.play();
            }
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });

    // Handle becoming noisy (e.g. headphones unplugged)
    session.becomingNoisyEventStream.listen((_) {
      audioPlayer.pause();
    });
  }

  Future<void> _init() async {
    await loadUserName();
    await loadLocalLibrary();
    await loadRecentlyPlayed();
    await loadRecentSearches();
    await loadFavorites();
    await loadTopSongs();
    await loadPlaybackHistory();
    await loadUserPlaylists();
    // Load trending regional songs in parallel
    _loadTrendingSongs();
  }

  Future<void> _loadTrendingSongs() async {
    try {
      final results = await Future.wait([
        _apiService.searchSongs('Anirudh Ravichander Tamil'),
        _apiService.searchSongs('A.R. Rahman Tamil'),
        _apiService.searchSongs('Jakes Bejoy Malayalam'),
        _apiService.searchSongs('Sushin Shyam Malayalam'),
      ]);

      // Combine and shuffle Tamil songs from Anirudh and A.R. Rahman
      final List<Song> tamilSongs = [...results[0], ...results[1]];
      tamilSongs.shuffle();
      
      // Combine and shuffle Malayalam songs from Jakes Bejoy and Sushin Shyam
      final List<Song> malayalamSongs = [...results[2], ...results[3]];
      malayalamSongs.shuffle();

      // Keep top 15 to keep the horizontal list tidy
      trendingTamil = tamilSongs.take(15).toList();
      trendingMalayalam = malayalamSongs.take(15).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading trending songs: $e');
    }
  }

  /// Call this from the welcome screen to preload home screen data
  /// while the user is reading the greeting page.
  void preloadHomeData() {
    // Fire both in parallel — don't await, let them complete in the background
    _loadTrendingSongs();
    loadTopSongs();
  }

  Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('user_name') ?? '';
    notifyListeners();
  }

  Future<void> loadLocalLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localData = prefs.getString('local_library');
    if (localData != null) {
      final List<dynamic> decoded = json.decode(localData);
      localLibrary = decoded.map((e) => Song.fromMap(e)).toList();
      notifyListeners();
    }
  }

  Future<void> saveLocalLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(localLibrary.map((e) => e.toJson()).toList());
    await prefs.setString('local_library', encoded);
  }

  Future<void> loadPlaybackHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('playback_history');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      playbackHistory = decoded.map((e) => SongHistoryEvent.fromMap(e)).toList();
      notifyListeners();
    }
  }

  Future<void> savePlaybackHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(playbackHistory.map((e) => e.toMap()).toList());
    await prefs.setString('playback_history', encoded);
  }

  void _recordPlaybackEvent() {
    if (currentSong == null) return;
    final durationSeconds = audioPlayer.duration?.inSeconds ?? 0;
    
    final event = SongHistoryEvent(
      songId: currentSong!.id,
      title: currentSong!.title,
      artist: currentSong!.artist,
      durationSeconds: durationSeconds,
      timestamp: DateTime.now(),
    );
    
    playbackHistory.add(event);
    savePlaybackHistory();
    // We don't notifyListeners here to avoid interrupting the UI unnecessarily,
    // unless the user is on the Stats page. The Stats page can re-read it.
  }

  Future<void> loadRecentlyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('recently_played');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      recentlyPlayed = decoded.map((e) => Song.fromMap(e)).toList();
      notifyListeners();
    }
  }

  Future<void> saveRecentlyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(recentlyPlayed.map((e) => e.toJson()).toList());
    await prefs.setString('recently_played', encoded);
  }

  Future<void> loadTopSongs() async {
    isLoadingLibrary = true;
    notifyListeners();
    topSongs = await _apiService.searchSongs('top songs');
    isLoadingLibrary = false;
    notifyListeners();
  }

  // ── Favorites ──────────────────────────────────────────────────────────

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('favorites');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      favorites = decoded.map((e) => Song.fromMap(e)).toList();
      notifyListeners();
    }
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(favorites.map((e) => e.toJson()).toList());
    await prefs.setString('favorites', encoded);
  }

  bool isFavorite(Song song) {
    return favorites.any((s) => s.id == song.id);
  }

  void toggleFavorite(Song song) {
    if (isFavorite(song)) {
      favorites.removeWhere((s) => s.id == song.id);
    } else {
      favorites.insert(0, song);
    }
    saveFavorites();
    notifyListeners();
  }

  // ── Top Artists (derived from recently played) ─────────────────────────

  final List<Map<String, String>> topMusicDirectors = [
    {
      'name': 'Anirudh Ravichander',
      'imageUrl': 'https://c.saavncdn.com/artists/Anirudh_Ravichander_003_20260121134149_500x500.jpg',
    },
    {
      'name': 'A.R. Rahman',
      'imageUrl': 'https://c.saavncdn.com/artists/AR_Rahman_002_20210120084455_500x500.jpg',
    },
    {
      'name': 'Harris Jayaraj',
      'imageUrl': 'https://c.saavncdn.com/artists/Harris_Jayaraj_500x500.jpg',
    },
    {
      'name': 'Yuvan Shankar Raja',
      'imageUrl': 'https://c.saavncdn.com/artists/Yuvan_Shankar_Raja_002_20180802174245_500x500.jpg',
    },
    {
      'name': 'Sushin Shyam',
      'imageUrl': 'https://c.saavncdn.com/artists/Sushin_Shyam_002_20250707125538_500x500.jpg',
    },
    {
      'name': 'Jakes Bejoy',
      'imageUrl': 'https://c.saavncdn.com/artists/Jakes_Bejoy_001_20231106102848_500x500.jpg',
    },
    {
      'name': 'G.V. Prakash Kumar',
      'imageUrl': 'https://c.saavncdn.com/artists/G_V_Prakash_Kumar_500x500.jpg',
    },
    {
      'name': 'Santhosh Narayanan',
      'imageUrl': 'https://c.saavncdn.com/artists/Santhosh_Narayanan_500x500.jpg',
    },
    {
      'name': 'Hesham Abdul Wahab',
      'imageUrl': 'https://c.saavncdn.com/artists/Hesham_Abdul_Wahab_001_20220919094035_500x500.jpg',
    },
    {
      'name': 'Sai Abhyankar',
      'imageUrl': 'https://c.saavncdn.com/artists/Sai_Abhyankkar_003_20250707122433_500x500.jpg',
    }
  ];

  /// Returns a curated list of top music directors.
  List<Map<String, String>> getTopArtists() {
    return topMusicDirectors;
  }

  void addToRecentlyPlayed(Song song) {
    recentlyPlayed.removeWhere((s) => s.id == song.id);
    recentlyPlayed.insert(0, song);
    if (recentlyPlayed.length > 20) {
      recentlyPlayed = recentlyPlayed.sublist(0, 20);
    }
    saveRecentlyPlayed();
    notifyListeners();
  }

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('recent_searches');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      recentSearches = decoded.map((e) => Song.fromMap(e)).toList();
      notifyListeners();
    }
  }

  Future<void> saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(recentSearches.map((e) => e.toJson()).toList());
    await prefs.setString('recent_searches', encoded);
  }

  void addToRecentSearches(Song song) {
    recentSearches.removeWhere((s) => s.id == song.id);
    recentSearches.insert(0, song);
    if (recentSearches.length > 20) {
      recentSearches = recentSearches.sublist(0, 20);
    }
    saveRecentSearches();
    notifyListeners();
  }

  void removeFromRecentSearches(Song song) {
    recentSearches.removeWhere((s) => s.id == song.id);
    saveRecentSearches();
    notifyListeners();
  }

  Future<void> pickLocalAudio(BuildContext context) async {
    try {
      FilePickerResult? audioResult = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (audioResult != null && audioResult.files.single.path != null) {
        final path = audioResult.files.single.path!;
        final filename = audioResult.files.single.name;
        
        String imagePath = '';
        
        // Ask user if they want to add a thumbnail
        final bool? wantsThumbnail = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF282828),
            title: const Text('Add a cover image?', style: TextStyle(color: Colors.white)),
            content: const Text('Would you like to select a thumbnail for this local song?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Skip', style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Select Image', style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (wantsThumbnail == true) {
          FilePickerResult? imageResult = await FilePicker.platform.pickFiles(
            type: FileType.image,
          );
          if (imageResult != null && imageResult.files.single.path != null) {
            imagePath = imageResult.files.single.path!;
          }
        }
        
        final localSong = Song(
          id: path,
          title: filename.replaceAll(RegExp(r'\.[^.]*$'), ''),
          artist: 'Local File',
          imageUrl: imagePath, 
          videoId: path,
          isLocal: true,
        );

        localLibrary.removeWhere((s) => s.id == localSong.id);
        localLibrary.insert(0, localSong);
        await saveLocalLibrary();
        notifyListeners();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to Your Library'),
            backgroundColor: Color(0xFF282828),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        playSong(localSong);
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> deleteLocalSong(Song song) async {
    localLibrary.removeWhere((s) => s.id == song.id);
    await saveLocalLibrary();
    if (currentSong?.id == song.id) {
      audioPlayer.stop();
      currentSong = null;
    }
    notifyListeners();
  }

  Future<void> downloadSong(Song song, BuildContext context) async {
    if (song.isLocal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song is already downloaded'), behavior: SnackBarBehavior.floating)
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${song.title}"...', style: const TextStyle(color: Color(0xFF1DB954))),
        backgroundColor: const Color(0xFF282828),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final streamUrl = await _apiService.getStreamUrl(song.videoId);
      if (streamUrl.isEmpty) throw Exception('No stream URL found');

      final dir = await getApplicationDocumentsDirectory();
      final safeTitle = song.title.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').replaceAll(' ', '_');
      final safeArtist = song.artist.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').replaceAll(' ', '_');
      final fileNameBase = '${safeTitle}_$safeArtist';
      
      // Download audio
      final audioResponse = await http.get(Uri.parse(streamUrl));
      if (audioResponse.statusCode != 200) throw Exception('Failed to download audio');
      
      final audioFile = File('${dir.path}/$fileNameBase.m4a');
      await audioFile.writeAsBytes(audioResponse.bodyBytes);
      
      // Download image
      String imagePath = '';
      if (song.imageUrl.isNotEmpty && song.imageUrl.startsWith('http')) {
        try {
          final imageResponse = await http.get(Uri.parse(song.imageUrl));
          if (imageResponse.statusCode == 200) {
            final imageFile = File('${dir.path}/${fileNameBase}_cover.jpg');
            await imageFile.writeAsBytes(imageResponse.bodyBytes);
            imagePath = imageFile.path;
          }
        } catch (e) {
          debugPrint('Failed to download image: $e');
        }
      }
      
      final localSong = Song(
        id: audioFile.path, // Use path as ID to ensure uniqueness for local files
        title: song.title,
        artist: song.artist,
        imageUrl: imagePath,
        videoId: audioFile.path,
        isLocal: true,
      );
      
      localLibrary.removeWhere((s) => s.title == localSong.title && s.artist == localSong.artist);
      localLibrary.insert(0, localSong);
      await saveLocalLibrary();
      notifyListeners();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded "${song.title}" successfully'),
            backgroundColor: const Color(0xFF1DB954),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Download error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download song'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool isResolvingAudio = false;
  DateTime _lastPlayTap = DateTime.fromMillisecondsSinceEpoch(0);

  List<Song> currentPlaylist = [];
  List<Song> originalPlaylist = [];
  int currentPlaylistIndex = -1;
  
  bool isShuffleEnabled = false;
  PlaybackRepeatMode repeatMode = PlaybackRepeatMode.off;

  void toggleShuffle() {
    isShuffleEnabled = !isShuffleEnabled;
    if (isShuffleEnabled && currentPlaylist.isNotEmpty) {
      // Create a shuffled copy but keep the current song at the current index
      final current = currentPlaylist[currentPlaylistIndex];
      currentPlaylist.shuffle();
      currentPlaylist.remove(current);
      currentPlaylist.insert(0, current);
      currentPlaylistIndex = 0;
    } else if (!isShuffleEnabled && originalPlaylist.isNotEmpty) {
      // Restore original playlist
      final current = currentPlaylist[currentPlaylistIndex];
      currentPlaylist = List.from(originalPlaylist);
      currentPlaylistIndex = currentPlaylist.indexWhere((s) => s.id == current.id);
      if (currentPlaylistIndex == -1) currentPlaylistIndex = 0;
    }
    notifyListeners();
  }

  void toggleRepeat() {
    if (repeatMode == PlaybackRepeatMode.off) {
      repeatMode = PlaybackRepeatMode.all;
    } else if (repeatMode == PlaybackRepeatMode.all) {
      repeatMode = PlaybackRepeatMode.one;
    } else {
      repeatMode = PlaybackRepeatMode.off;
    }
    notifyListeners();
  }

  void playNext() {
    if (currentPlaylist.isEmpty || currentPlaylistIndex == -1) return;
    
    if (repeatMode == PlaybackRepeatMode.one) {
      // Repeat the exact same song
      audioPlayer.seek(Duration.zero);
      audioPlayer.play();
      return;
    }
    
    if (currentPlaylistIndex < currentPlaylist.length - 1) {
      playSong(currentPlaylist[currentPlaylistIndex + 1]);
    } else if (repeatMode == PlaybackRepeatMode.all) {
      // Loop back to the first song
      playSong(currentPlaylist.first);
    } else {
      // Infinite "Radio" Autoplay
      _fetchAndPlayRecommendations();
    }
  }

  Future<void> _fetchAndPlayRecommendations() async {
    final current = currentSong;
    if (current == null) return;

    isResolvingAudio = true;
    notifyListeners();

    bool startedPlayingNewSong = false;

    try {
      String query = current.artist;
      if (query == 'Unknown' || query == 'Various Artists') {
        query = current.title;
      }
      if (current.language.isNotEmpty && current.language != 'unknown') {
        query += ' ${current.language}';
      }

      // Search for more songs by the current artist/language
      final results = await _apiService.searchSongs(query, limit: 20);
      
      // Filter out songs already in the playlist and prioritize same language
      final existingIds = originalPlaylist.map((s) => s.id).toSet();
      
      List<Song> newSongs = results.where((s) => 
        !existingIds.contains(s.id) && 
        (current.language == 'unknown' || s.language == 'unknown' || s.language == current.language)
      ).toList();

      // Fallback if language strict filtering leaves us with nothing
      if (newSongs.isEmpty) {
        newSongs = results.where((s) => !existingIds.contains(s.id)).toList();
      }

      if (newSongs.isNotEmpty) {
        if (isShuffleEnabled) {
          newSongs.shuffle();
        }

        originalPlaylist.addAll(newSongs);
        currentPlaylist.addAll(newSongs);
        
        // Play the very next song we just added
        playSong(currentPlaylist[currentPlaylistIndex + 1]);
        startedPlayingNewSong = true;
      } else {
        // Fallback: If no recommendations found, stop or restart
      }
    } catch (e) {
      debugPrint("Error fetching recommendations: $e");
    } finally {
      // Only clear loading state if we didn't start a new song,
      // because playSong() will manage its own loading state.
      if (!startedPlayingNewSong) {
        isResolvingAudio = false;
        notifyListeners();
      }
    }
  }

  void playPrevious() {
    if (currentPlaylist.isEmpty || currentPlaylistIndex == -1) return;
    
    if (audioPlayer.position.inSeconds > 3 || currentPlaylistIndex == 0) {
      // If played for more than 3 seconds or it's the first song, just restart it
      audioPlayer.seek(Duration.zero);
    } else {
      // Otherwise play the previous song
      playSong(currentPlaylist[currentPlaylistIndex - 1]);
    }
  }

  void playSong(Song song, {List<Song>? playlist}) async {
    // Debounce rapid taps
    if (DateTime.now().difference(_lastPlayTap).inMilliseconds < 1500) {
      return;
    }
    _lastPlayTap = DateTime.now();

    if (playlist != null) {
      originalPlaylist = List.from(playlist);
      if (isShuffleEnabled) {
        currentPlaylist = List.from(playlist);
        currentPlaylist.shuffle();
        currentPlaylist.removeWhere((s) => s.id == song.id);
        currentPlaylist.insert(0, song);
      } else {
        currentPlaylist = List.from(playlist);
      }
      currentPlaylistIndex = currentPlaylist.indexWhere((s) => s.id == song.id);
    } else if (currentPlaylist.isNotEmpty) {
      currentPlaylistIndex = currentPlaylist.indexWhere((s) => s.id == song.id);
    }

    currentSong = song;
    addToRecentlyPlayed(song);
    
    isResolvingAudio = true;
    notifyListeners();
    
    try {
      final mediaItem = MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        artUri: song.imageUrl.isNotEmpty 
            ? (song.imageUrl.startsWith('http') ? Uri.parse(song.imageUrl) : Uri.file(song.imageUrl)) 
            : null,
      );

      // Update the notification with current song info
      _audioHandler?.updateMediaItem(mediaItem);
      
      String streamUrl = '';
      if (song.isLocal) {
        streamUrl = song.videoId;
      } else {
        streamUrl = await _apiService.getStreamUrl(song.videoId);
      }

      if (streamUrl.isNotEmpty) {
        final audioSource = AudioSource.uri(
          song.isLocal ? Uri.file(streamUrl) : Uri.parse(streamUrl),
          tag: mediaItem,
        );

        await audioPlayer.setAudioSource(audioSource);
        
        // Update the notification MediaItem with the actual duration
        // so the progress bar and time display work correctly.
        final actualDuration = audioPlayer.duration;
        if (actualDuration != null) {
          final updatedMediaItem = mediaItem.copyWith(duration: actualDuration);
          _audioHandler?.updateMediaItem(updatedMediaItem);
        }
        
        audioPlayer.play();
      }
    } catch (e) {
      debugPrint("Error loading audio source: $e");
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      isResolvingAudio = false;
      notifyListeners();
    }
  }

  // ── User Playlists ─────────────────────────────────────────────────────

  Future<void> loadUserPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_playlists');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      userPlaylists = decoded.map((e) => Playlist.fromMap(e)).toList();
      notifyListeners();
    }
  }

  Future<void> saveUserPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(userPlaylists.map((e) => e.toJson()).toList());
    await prefs.setString('user_playlists', encoded);
  }

  void createPlaylist(String name, {List<Song>? initialSongs}) {
    final id = 'pl_${DateTime.now().millisecondsSinceEpoch}';
    final playlist = Playlist(
      id: id,
      name: name,
      songs: initialSongs ?? [],
    );
    userPlaylists.insert(0, playlist);
    saveUserPlaylists();
    notifyListeners();
  }

  void renamePlaylist(String playlistId, String newName) {
    final index = userPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      userPlaylists[index].name = newName;
      saveUserPlaylists();
      notifyListeners();
    }
  }

  void deletePlaylist(String playlistId) {
    userPlaylists.removeWhere((p) => p.id == playlistId);
    saveUserPlaylists();
    notifyListeners();
  }

  void addSongToPlaylist(String playlistId, Song song) {
    final index = userPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      // Don't add duplicates
      if (!userPlaylists[index].songs.any((s) => s.id == song.id)) {
        userPlaylists[index].songs.add(song);
        saveUserPlaylists();
        notifyListeners();
      }
    }
  }

  void removeSongFromPlaylist(String playlistId, Song song) {
    final index = userPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      userPlaylists[index].songs.removeWhere((s) => s.id == song.id);
      saveUserPlaylists();
      notifyListeners();
    }
  }

  void reorderPlaylistSong(String playlistId, int oldIndex, int newIndex) {
    final index = userPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      if (newIndex > oldIndex) newIndex--;
      final song = userPlaylists[index].songs.removeAt(oldIndex);
      userPlaylists[index].songs.insert(newIndex, song);
      saveUserPlaylists();
      notifyListeners();
    }
  }

  // ── Sleep Timer ─────────────────────────────────────────────────────

  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    sleepTimerRemaining = duration;
    
    // The main timer that actually stops playback
    _sleepTimer = Timer(duration, () {
      audioPlayer.pause();
      sleepTimerRemaining = null;
      _sleepCountdown?.cancel();
      _sleepCountdown = null;
      notifyListeners();
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Sleep timer ended — goodnight! 🌙'),
          backgroundColor: Color(0xFF282828),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    // A periodic countdown so the UI can show remaining time
    _sleepCountdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (sleepTimerRemaining != null && sleepTimerRemaining!.inSeconds > 0) {
        sleepTimerRemaining = sleepTimerRemaining! - const Duration(seconds: 1);
        notifyListeners();
      }
    });

    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepCountdown?.cancel();
    _sleepCountdown = null;
    sleepTimerRemaining = null;
    notifyListeners();
  }

  bool get isSleepTimerActive => sleepTimerRemaining != null;

  // ── Made For You Mix ────────────────────────────────────────────────

  Future<void> generateMadeForYouMix() async {
    if (isLoadingMix) return;
    isLoadingMix = true;
    notifyListeners();

    try {
      // Count artist frequency from playback history
      final Map<String, int> artistCounts = {};
      for (final event in playbackHistory) {
        for (final artist in event.artist.split(',')) {
          final trimmed = artist.trim();
          if (trimmed.isNotEmpty) {
            artistCounts[trimmed] = (artistCounts[trimmed] ?? 0) + 1;
          }
        }
      }

      // Also include favorites artists
      for (final song in favorites) {
        for (final artist in song.artist.split(',')) {
          final trimmed = artist.trim();
          if (trimmed.isNotEmpty) {
            artistCounts[trimmed] = (artistCounts[trimmed] ?? 0) + 2; // weight favorites higher
          }
        }
      }

      // Sort by frequency, take top 5 artists
      final sortedArtists = artistCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topArtists = sortedArtists
          .map((e) => e.key)
          .where((a) => a != 'Unknown' && a != 'Local File' && a.isNotEmpty)
          .take(5)
          .toList();

      if (topArtists.isEmpty) {
        // Fallback for new users
        topArtists.addAll(['Anirudh', 'A.R. Rahman', 'Sushin Shyam']);
      }

      // Fetch songs for each top artist
      final Set<String> seenIds = {};
      final List<Song> mixSongs = [];

      // Increase limit because we'll filter out non-matching artists locally
      final futures = topArtists.map((artist) => _apiService.searchSongs(artist, limit: 20));
      final results = await Future.wait(futures);

      for (int i = 0; i < topArtists.length; i++) {
        final targetArtist = topArtists[i].toLowerCase();
        final songs = results[i];
        
        for (final song in songs) {
          final songArtists = song.artist.toLowerCase();
          // Ensure the returned song is actually by the requested artist
          if (songArtists.contains(targetArtist)) {
            if (!seenIds.contains(song.id)) {
              seenIds.add(song.id);
              mixSongs.add(song);
            }
          }
        }
      }

      mixSongs.shuffle();
      madeForYouMix = mixSongs.take(30).toList();
    } catch (e) {
      debugPrint('Error generating mix: $e');
    } finally {
      isLoadingMix = false;
      notifyListeners();
    }
  }

  // ── Queue Management ────────────────────────────────────────────────

  void removeFromQueue(int index) {
    if (index < 0 || index >= currentPlaylist.length) return;
    if (index == currentPlaylistIndex) return; // Can't remove currently playing
    
    currentPlaylist.removeAt(index);
    // Adjust current index if needed
    if (index < currentPlaylistIndex) {
      currentPlaylistIndex--;
    }
    notifyListeners();
  }

  void playFromQueue(int index) {
    if (index < 0 || index >= currentPlaylist.length) return;
    playSong(currentPlaylist[index]);
  }

  /// Add a song to the end of the current queue
  void addSongToQueue(Song song) {
    if (!currentPlaylist.any((s) => s.id == song.id)) {
      currentPlaylist.add(song);
      originalPlaylist.add(song);
      notifyListeners();
    }
  }

  /// Sets the queue to a new list of songs and starts playing from [initialIndex]
  void setQueueAndPlay(List<Song> songs, {int initialIndex = 0}) {
    if (songs.isEmpty) return;
    final clampedIndex = initialIndex.clamp(0, songs.length - 1);
    playSong(songs[clampedIndex], playlist: songs);
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }
}
