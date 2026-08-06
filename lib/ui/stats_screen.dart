import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../music_provider.dart';
import '../song_history_event.dart';
import 'theme.dart';
import 'dart:math';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MusicProvider>();
    final history = provider.playbackHistory;

    // Calculations
    int totalSeconds = history.fold(0, (sum, event) => sum + event.durationSeconds);
    String totalTimeStr = _formatDurationStr(totalSeconds);

    // Top Artists
    Map<String, int> artistCounts = {};
    for (var event in history) {
      if (event.artist.isNotEmpty && event.artist != 'Unknown') {
        artistCounts[event.artist] = (artistCounts[event.artist] ?? 0) + 1;
      }
    }
    
    var sortedArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topArtists = sortedArtists.take(5).toList();

    // Top Tracks
    Map<String, int> trackCounts = {};
    Map<String, SongHistoryEvent> trackDetails = {};
    for (var event in history) {
      if (event.title.isNotEmpty) {
        trackCounts[event.songId] = (trackCounts[event.songId] ?? 0) + 1;
        trackDetails[event.songId] = event;
      }
    }
    
    var sortedTracks = trackCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topTracks = sortedTracks.take(10).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Your Music Wrapped', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'Listen to more music to see your stats!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalTimeCard(totalTimeStr),
                  const SizedBox(height: 32),
                  const Text('Top Artists', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  _buildArtistsChart(topArtists),
                  const SizedBox(height: 32),
                  const Text('Most Played Tracks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  _buildTopTracksList(topTracks, trackDetails),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  String _formatDurationStr(int totalSeconds) {
    if (totalSeconds < 60) return '$totalSeconds Sec';
    int minutes = totalSeconds ~/ 60;
    if (minutes < 60) return '$minutes Min';
    int hours = minutes ~/ 60;
    int remainingMins = minutes % 60;
    return '${hours}h ${remainingMins}m';
  }

  Widget _buildTotalTimeCard(String totalTimeStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF128C3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DB954).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          const Text('Total Listening Time', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(totalTimeStr, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildArtistsChart(List<MapEntry<String, int>> topArtists) {
    if (topArtists.isEmpty) return const SizedBox.shrink();
    
    double maxY = topArtists.first.value.toDouble();
    if (maxY == 0) maxY = 1; // prevent divide by zero

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 20, right: 16, left: 0, bottom: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY + (maxY * 0.2),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${topArtists[group.x.toInt()].key}\n',
                  const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${rod.toY.toInt()} plays',
                      style: const TextStyle(color: Color(0xFF1DB954), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= topArtists.length) return const SizedBox.shrink();
                  String artist = topArtists[value.toInt()].key;
                  if (artist.length > 8) artist = '${artist.substring(0, 6)}..';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      artist,
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: topArtists.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopTracksList(List<MapEntry<String, int>> topTracks, Map<String, SongHistoryEvent> trackDetails) {
    if (topTracks.isEmpty) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topTracks.length,
        separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
        itemBuilder: (context, index) {
          final trackId = topTracks[index].key;
          final plays = topTracks[index].value;
          final details = trackDetails[trackId]!;
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Text(
              '${index + 1}',
              style: const TextStyle(color: Color(0xFF1DB954), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            title: Text(details.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(details.artist, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$plays plays', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }
}
