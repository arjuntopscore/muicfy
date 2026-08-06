import 'song_model.dart';

class Playlist {
  final String id;
  String name;
  List<Song> songs;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    List<Song>? songs,
    DateTime? createdAt,
  })  : songs = songs ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed',
      songs: (map['songs'] as List?)?.map((s) => Song.fromMap(s)).toList() ?? [],
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
    );
  }
}
