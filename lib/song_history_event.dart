class SongHistoryEvent {
  final String songId;
  final String title;
  final String artist;
  final int durationSeconds;
  final DateTime timestamp;

  SongHistoryEvent({
    required this.songId,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'songId': songId,
      'title': title,
      'artist': artist,
      'durationSeconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SongHistoryEvent.fromMap(Map<String, dynamic> map) {
    return SongHistoryEvent(
      songId: map['songId'] ?? '',
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      durationSeconds: map['durationSeconds']?.toInt() ?? 0,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
