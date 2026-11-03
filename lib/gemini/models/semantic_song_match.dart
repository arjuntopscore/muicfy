/// Represents a song match identified from a natural language or semantic query.
class SemanticSongMatch {
  final String title;
  final String artist;
  final String album;
  final String releaseYear;
  final String matchReason;

  const SemanticSongMatch({
    required this.title,
    required this.artist,
    required this.album,
    required this.releaseYear,
    required this.matchReason,
  });

  /// Factory constructor to parse JSON with resilient type casting.
  factory SemanticSongMatch.fromJson(Map<String, dynamic> json) {
    return SemanticSongMatch(
      title: json['title'] as String? ?? 'Unknown Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String? ?? 'Unknown Album',
      releaseYear: json['releaseYear']?.toString() ?? 'N/A',
      matchReason: json['matchReason'] as String? ?? 'Match identified based on description.',
    );
  }

  /// Converts the model back into a JSON map.
  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'album': album,
        'releaseYear': releaseYear,
        'matchReason': matchReason,
      };
}
