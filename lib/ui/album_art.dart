import 'dart:io';
import 'package:flutter/material.dart';
import '../song_model.dart';

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

    final effectiveRadius = borderRadius != null ? borderRadius! : BorderRadius.zero;
    final themeColor = Theme.of(context).iconTheme.color;
    final iconColor = themeColor != null
        ? themeColor.withValues(alpha: 0.54)
        : Colors.white54;

    Widget placeholder() {
      return Container(
        color: Theme.of(context).cardColor,
        alignment: Alignment.center,
        child: Icon(Icons.music_note, color: iconColor, size: iconSize),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: imageProvider == null
            ? placeholder()
            : Image(
                image: imageProvider,
                fit: BoxFit.cover,
                width: width,
                height: height,
                errorBuilder: (context, error, stackTrace) => placeholder(),
              ),
      ),
    );
  }
}


