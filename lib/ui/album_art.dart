import 'dart:io';
import 'package:flutter/material.dart';
import '../song_model.dart';
import 'theme.dart';

class AlbumArt extends StatelessWidget {
  final Song song;
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final double iconSize;

  const AlbumArt({
    super.key,
    required this.song,
    required this.width,
    required this.height,
    this.borderRadius,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (song.imageUrl.isNotEmpty) {
      if (song.imageUrl.startsWith('http')) {
        imageProvider = NetworkImage(song.imageUrl);
      } else {
        imageProvider = FileImage(File(song.imageUrl));
      }
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: borderRadius,
        image: imageProvider != null
            ? DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageProvider == null
          ? Icon(Icons.music_note, color: Colors.white54, size: iconSize)
          : null,
    );
  }
}
