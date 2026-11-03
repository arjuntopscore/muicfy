/// Represents an individual song recommended in a vibe-based playlist.
class VibeSong {
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int durationInSeconds;

  const VibeSong({
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.durationInSeconds,
  });

  /// Factory constructor to parse JSON with defensive type casting.
  factory VibeSong.fromJson(Map<String, dynamic> json) {
    return VibeSong(
      title: json['title'] as String? ?? 'Unknown Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String? ?? 'Unknown Album',
      genre: json['genre'] as String? ?? 'Various',
      durationInSeconds: (json['durationInSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts the model back into a JSON map.
  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'album': album,
        'genre': genre,
        'durationInSeconds': durationInSeconds,
      };

  /// Returns the song duration formatted as "m:ss" (e.g. 3:45).
  String get formattedDuration {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Represents the full vibe-generated playlist along with total duration metrics.
class VibePlaylist {
  final String prompt;
  final List<VibeSong> songs;

  const VibePlaylist({
    required this.prompt,
    required this.songs,
  });

  /// Total duration in seconds across all tracks.
  int get totalDurationInSeconds =>
      songs.fold<int>(0, (total, song) => total + song.durationInSeconds);

  /// Human-readable total duration (e.g., "45m 12s" or "1h 15m").
  String get totalDurationFormatted {
    final totalSeconds = totalDurationInSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds > 0 ? '${seconds}s' : ''}'.trim();
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  /// Number of tracks in the playlist.
  int get trackCount => songs.length;
}
