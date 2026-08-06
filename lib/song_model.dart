class Song {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final String videoId;
  final String language;
  final bool isLocal;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.videoId,
    this.language = 'unknown',
    this.isLocal = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'imageUrl': imageUrl,
      'videoId': videoId,
      'language': language,
      'isLocal': isLocal,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    String parsedTitle = map['name']?.toString() ?? map['title']?.toString() ?? 'Unknown';
    
    String parsedArtist = 'Unknown';
    if (map['artists'] != null && map['artists']['primary'] is List) {
      final primary = map['artists']['primary'] as List;
      if (primary.isNotEmpty) {
        if (primary.first is Map) {
          parsedArtist = primary.map((a) => a['name'].toString()).join(', ');
        } else {
          parsedArtist = primary.join(', ');
        }
      }
    } else {
      parsedArtist = map['artist']?.toString() ?? 'Unknown';
    }

    String parsedImage = '';
    if (map['image'] is List && (map['image'] as List).isNotEmpty) {
      parsedImage = (map['image'] as List).last['url']?.toString() ?? '';
    } else {
      parsedImage = map['img']?.toString() ?? map['imageUrl']?.toString() ?? '';
    }

    String parsedStream = '';
    if (map['downloadUrl'] is List && (map['downloadUrl'] as List).isNotEmpty) {
      parsedStream = (map['downloadUrl'] as List).last['url']?.toString() ?? '';
    }

    return Song(
      id: map['id']?.toString() ?? '',
      title: parsedTitle,
      artist: parsedArtist,
      imageUrl: parsedImage,
      videoId: parsedStream.isNotEmpty 
          ? parsedStream 
          : (map['videoId']?.toString() ?? map['streamUrl']?.toString() ?? ''),
      language: map['language']?.toString().toLowerCase() ?? 'unknown',
      isLocal: map['isLocal'] == true,
    );
  }
}
