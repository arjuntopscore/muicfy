import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../music_provider.dart';
import '../song_history_event.dart';
import 'theme.dart';
import 'artist_screen.dart';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: history.isEmpty
          ? _buildEmptyState(context)
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'Your Wrapped',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    background: _buildHeroHeader(context, totalTimeStr),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStatsRow(
                        context,
                        totalSeconds: totalSeconds,
                        totalArtists: topArtists.length,
                        totalTracks: trackCounts.length,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader(context, 'Top Music Directors', 'Tap to explore'),
                      const SizedBox(height: 16),
                      _buildTopArtistsStrip(context, topArtists),
                      const SizedBox(height: 32),
                      _buildSectionHeader(context, 'Most Played', '${topTracks.length} tracks'),
                      const SizedBox(height: 12),
                      _buildTopTracksList(context, topTracks, trackDetails),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                  colors: [AppTheme.accentColor1.withOpacity(0.25), AppTheme.accentColor2.withOpacity(0.1)],
                ),
              ),
              child: Icon(Icons.headphones_rounded, size: 48, color: AppTheme.accentColor1),
            ),
            const SizedBox(height: 20),
            Text(
              'No stats yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Listen to music and watch your wrapped come to life.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, String totalTimeStr) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8E2DE2),
                const Color(0xFF4A00E0),
                AppTheme.accentColor1,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: -30,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
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
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                Theme.of(context).scaffoldBackgroundColor,
              ],
              stops: const [0.0, 0.6, 1.0],
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
              Text(
                'TOTAL LISTENING',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                totalTimeStr,
                style: const TextStyle(
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

  Widget _buildStatsRow(BuildContext context,
      {required int totalSeconds, required int totalArtists, required int totalTracks}) {
    return Row(
      children: [
        _miniStatCard(context, Icons.person_outline_rounded, '$totalArtists', 'Artists'),
        const SizedBox(width: 10),
        _miniStatCard(context, Icons.music_note_rounded, '$totalTracks', 'Tracks'),
        const SizedBox(width: 10),
        _miniStatCard(context, Icons.local_fire_department_rounded, '${(totalSeconds / 60).ceil()}', 'Minutes'),
      ],
    );
  }

  Widget _miniStatCard(BuildContext context, IconData icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.accentColor1),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle) {
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
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTopArtistsStrip(BuildContext context, List<_DirectorEntry> topArtists) {
    if (topArtists.isEmpty) {
      return _emptyTile(context, 'No music director plays tracked yet.');
    }
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
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

  Widget _buildTopTracksList(BuildContext context, List<MapEntry<String, int>> topTracks,
      Map<String, SongHistoryEvent> trackDetails) {
    if (topTracks.isEmpty) {
      return _emptyTile(context, 'No tracks tracked yet.');
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxPlays = topTracks.first.value;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: topTracks.length,
        separatorBuilder: (context, index) => Divider(
          color: Theme.of(context).dividerColor.withOpacity(0.08),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: index < 3 ? AppTheme.accentColor1 : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        details.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
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
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$plays',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'x',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
  final VoidCallback onTap;

  const _ArtistTile({
    required this.name,
    required this.plays,
    required this.rank,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor1.withOpacity(0.25),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.accentColor1, AppTheme.accentColor2],
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardColor,
                      image: hasImage
                          ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: hasImage
                        ? null
                        : Icon(
                            Icons.person_rounded,
                            size: 46,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                  ),
                ),
                Positioned(
                  left: -4,
                  top: -4,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border.all(color: AppTheme.accentColor1, width: 2),
                    ),
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: AppTheme.accentColor1,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
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
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$plays plays',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65),
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
