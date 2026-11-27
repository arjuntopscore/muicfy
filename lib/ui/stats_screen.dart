import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../music_provider.dart';
import '../song_history_event.dart';
import 'theme.dart';
import 'artist_screen.dart';
import 'apple_music_widgets.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  bool _isLocalEvent(SongHistoryEvent e) {
    if (e.artist.trim().toLowerCase() == 'local file') return true;
    final id = e.songId;
    return id.contains('/') || id.contains('\\') || id.contains(':');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final directors = provider.topMusicDirectors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final history = provider.playbackHistory.where((e) => !_isLocalEvent(e)).toList();

    final int totalSeconds = history.fold(0, (sum, event) => sum + event.durationSeconds);
    final String totalTimeStr = _formatDurationStr(totalSeconds);

    final List<_DirectorEntry> directorEntries = [];
    for (final d in directors) {
      final name = d['name'] ?? '';
      final image = d['imageUrl'] ?? '';
      if (name.isEmpty) continue;
      final lowered = name.toLowerCase();
      int plays = 0;
      for (final event in history) {
        if (event.artist.toLowerCase().contains(lowered)) plays++;
      }
      if (plays > 0) {
        directorEntries.add(_DirectorEntry(name: name, imageUrl: image, plays: plays));
      }
    }
    directorEntries.sort((a, b) => b.plays.compareTo(a.plays));
    final topArtists = directorEntries.take(8).toList();

    final Map<String, int> trackCounts = {};
    final Map<String, SongHistoryEvent> trackDetails = {};
    for (final event in history) {
      if (event.title.isNotEmpty) {
        trackCounts[event.songId] = (trackCounts[event.songId] ?? 0) + 1;
        trackDetails[event.songId] = event;
      }
    }
    final sortedTracks = trackCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTracks = sortedTracks.take(10).toList();

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtextColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6E6E73);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: history.isEmpty
          ? _buildEmptyState(context, isDark, textColor, subtextColor)
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  backgroundColor: isDark ? const Color(0xFF0F1420) : Colors.white,
                  elevation: 0,
                  leading: FrostedCircleButton(
                    icon: CupertinoIcons.chevron_back,
                    size: 38,
                    iconSize: 20,
                    iconColor: textColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'Replay & Stats',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: textColor,
                      ),
                    ),
                    background: _buildHeroHeader(context, totalTimeStr, isDark),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStatsRow(
                        context,
                        isDark: isDark,
                        totalSeconds: totalSeconds,
                        totalArtists: topArtists.length,
                        totalTracks: trackCounts.length,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(context, 'Top Music Directors', 'Tap to explore', textColor, subtextColor),
                      const SizedBox(height: 16),
                      _buildTopArtistsStrip(context, topArtists, textColor, subtextColor),
                      const SizedBox(height: 32),
                      _buildSectionHeader(context, 'Most Played', '${topTracks.length} tracks', textColor, subtextColor),
                      const SizedBox(height: 12),
                      _buildTopTracksList(context, topTracks, trackDetails, isDark, textColor, subtextColor),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, Color textColor, Color subtextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor1.withValues(alpha: 0.25),
                    AppTheme.accentColor2.withValues(alpha: 0.10),
                  ],
                ),
              ),
              child: const Icon(CupertinoIcons.headphones, size: 48, color: AppTheme.accentColor1),
            ),
            const SizedBox(height: 20),
            Text(
              'No listening stats yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start playing your favourite music and watch\nyour personalized Replay come to life.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtextColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, String totalTimeStr, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8E2DE2),
                Color(0xFF4A00E0),
                Color(0xFFFA2D48),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: -20,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                (isDark ? Colors.black : const Color(0xFFF2F2F7)).withValues(alpha: 0.0),
                isDark ? Colors.black : const Color(0xFFF2F2F7),
              ],
              stops: const [0.0, 0.65, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TOTAL LISTENING TIME',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                totalTimeStr,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context, {
    required bool isDark,
    required int totalSeconds,
    required int totalArtists,
    required int totalTracks,
  }) {
    return Row(
      children: [
        _miniStatCard(context, isDark, CupertinoIcons.person_2_fill, '$totalArtists', 'Artists'),
        const SizedBox(width: 10),
        _miniStatCard(context, isDark, CupertinoIcons.music_note_list, '$totalTracks', 'Tracks'),
        const SizedBox(width: 10),
        _miniStatCard(context, isDark, CupertinoIcons.flame_fill, '${(totalSeconds / 60).ceil()}', 'Minutes'),
      ],
    );
  }

  Widget _miniStatCard(BuildContext context, bool isDark, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141926) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppTheme.accentColor1),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF6E6E73),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, Color textColor, Color subtextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: textColor,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: subtextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTopArtistsStrip(BuildContext context, List<_DirectorEntry> topArtists, Color textColor, Color subtextColor) {
    if (topArtists.isEmpty) {
      return _emptyTile(context, 'No music director plays tracked yet.');
    }
    return SizedBox(
      height: 185,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: topArtists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final entry = topArtists[index];
          return _ArtistTile(
            name: entry.name,
            plays: entry.plays,
            rank: index + 1,
            imageUrl: entry.imageUrl,
            textColor: textColor,
            subtextColor: subtextColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistScreen(
                    artistName: entry.name,
                    artistImageUrl: entry.imageUrl,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopTracksList(
    BuildContext context,
    List<MapEntry<String, int>> topTracks,
    Map<String, SongHistoryEvent> trackDetails,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    if (topTracks.isEmpty) {
      return _emptyTile(context, 'No tracks tracked yet.');
    }
    final maxPlays = topTracks.first.value;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141926) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: topTracks.length,
        separatorBuilder: (context, index) => Divider(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
          height: 1,
          indent: 20,
          endIndent: 20,
        ),
        itemBuilder: (context, index) {
          final trackId = topTracks[index].key;
          final plays = topTracks[index].value;
          final details = trackDetails[trackId]!;
          final progress = plays / maxPlays;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: index < 3 ? AppTheme.accentColor1 : subtextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        details.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$plays',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'plays',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyTile(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141926) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 13,
        ),
      ),
    );
  }

  String _formatDurationStr(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final minutes = totalSeconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    return '${hours}h ${remainingMins}m';
  }
}

class _DirectorEntry {
  final String name;
  final String imageUrl;
  final int plays;
  const _DirectorEntry({required this.name, required this.imageUrl, required this.plays});
}

class _ArtistTile extends StatelessWidget {
  final String name;
  final int plays;
  final int rank;
  final String imageUrl;
  final Color textColor;
  final Color subtextColor;
  final VoidCallback onTap;

  const _ArtistTile({
    required this.name,
    required this.plays,
    required this.rank,
    required this.imageUrl,
    required this.textColor,
    required this.subtextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor1.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFA2D48), Color(0xFFFF375F)],
                    ),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF141926) : Colors.white,
                      image: hasImage
                          ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: hasImage
                        ? null
                        : Icon(
                            CupertinoIcons.person_fill,
                            size: 46,
                            color: subtextColor,
                          ),
                  ),
                ),
                Positioned(
                  left: -2,
                  top: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.black : Colors.white,
                      border: Border.all(
                        color: rank == 1
                            ? const Color(0xFFFFD700)
                            : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32)),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank == 1
                            ? const Color(0xFFFFD700)
                            : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32)),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$plays plays',
              style: TextStyle(
                color: subtextColor,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
