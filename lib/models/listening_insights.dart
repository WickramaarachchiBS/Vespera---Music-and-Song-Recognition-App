import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vespera/models/top_item.dart';

class ListeningInsights {
  final Duration daily;
  final Duration weekly;
  final Duration allTime;
  final int streakDays;
  final List<TopItem> topArtistsWeek;
  final List<TopItem> topArtistsAllTime;
  final List<TopItem> topSongsWeek;
  final List<TopItem> topSongsAllTime;

  const ListeningInsights({
    required this.daily,
    required this.weekly,
    required this.allTime,
    required this.streakDays,
    required this.topArtistsWeek,
    required this.topArtistsAllTime,
    required this.topSongsWeek,
    required this.topSongsAllTime,
  });

  factory ListeningInsights.fromSessionDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final dailyThreshold = now.subtract(const Duration(days: 1));
    final weeklyThreshold = now.subtract(const Duration(days: 7));

    var dailySeconds = 0;
    var weeklySeconds = 0;
    var allTimeSeconds = 0;

    final allArtistCounts = <String, int>{};
    final weeklyArtistCounts = <String, int>{};
    final allSongCounts = <String, int>{};
    final weeklySongCounts = <String, int>{};
    final activeDays = <DateTime>{};

    for (final doc in docs) {
      final data = doc.data();
      final sessionSeconds = _extractSessionSeconds(data);
      allTimeSeconds += sessionSeconds;

      final listenedAt = _extractSessionTime(data);
      if (listenedAt != null) {
        final day = DateTime(listenedAt.year, listenedAt.month, listenedAt.day);
        activeDays.add(day);

        if (listenedAt.isAfter(weeklyThreshold)) {
          weeklySeconds += sessionSeconds;
        }

        if (listenedAt.isAfter(dailyThreshold)) {
          dailySeconds += sessionSeconds;
        }
      }

      final artist = ((data['artist'] as String?) ?? '').trim();
      if (artist.isNotEmpty) {
        allArtistCounts[artist] = (allArtistCounts[artist] ?? 0) + 1;
        if (listenedAt != null && listenedAt.isAfter(weeklyThreshold)) {
          weeklyArtistCounts[artist] = (weeklyArtistCounts[artist] ?? 0) + 1;
        }
      }

      final title = ((data['title'] as String?) ?? '').trim();
      if (title.isNotEmpty) {
        final songLabel = artist.isEmpty ? title : '$title - $artist';
        allSongCounts[songLabel] = (allSongCounts[songLabel] ?? 0) + 1;
        if (listenedAt != null && listenedAt.isAfter(weeklyThreshold)) {
          weeklySongCounts[songLabel] = (weeklySongCounts[songLabel] ?? 0) + 1;
        }
      }
    }

    return ListeningInsights(
      daily: Duration(seconds: dailySeconds),
      weekly: Duration(seconds: weeklySeconds),
      allTime: Duration(seconds: allTimeSeconds),
      streakDays: _calculateStreak(activeDays),
      topArtistsWeek: _toTopItems(weeklyArtistCounts),
      topArtistsAllTime: _toTopItems(allArtistCounts),
      topSongsWeek: _toTopItems(weeklySongCounts),
      topSongsAllTime: _toTopItems(allSongCounts),
    );
  }

  static int _calculateStreak(Set<DateTime> activeDays) {
    if (activeDays.isEmpty) return 0;

    final sorted = activeDays.toList()..sort((a, b) => b.compareTo(a));
    DateTime cursor = sorted.first;
    var streak = 0;

    while (activeDays.contains(DateTime(cursor.year, cursor.month, cursor.day))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  static List<TopItem> _toTopItems(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => TopItem(label: e.key, count: e.value)).toList();
  }

  static int _extractSessionSeconds(Map<String, dynamic> data) {
    final durationSeconds = data['durationSeconds'];
    if (durationSeconds is int) return durationSeconds;
    if (durationSeconds is double) return durationSeconds.round();

    final durationMs = data['durationMs'];
    if (durationMs is int) return (durationMs / 1000).round();
    if (durationMs is double) return (durationMs / 1000).round();

    final durationMinutes = data['durationMinutes'];
    if (durationMinutes is int) return durationMinutes * 60;
    if (durationMinutes is double) return (durationMinutes * 60).round();

    final durationString = data['duration'];
    if (durationString is String) {
      final seconds = _parseDurationString(durationString);
      if (seconds >= 0) return seconds;
    }

    return 0;
  }

  static DateTime? _extractSessionTime(Map<String, dynamic> data) {
    final listenedAt = data['listenedAt'];
    if (listenedAt is Timestamp) return listenedAt.toDate();

    final startedAt = data['startedAt'];
    if (startedAt is Timestamp) return startedAt.toDate();

    final playedAt = data['playedAt'];
    if (playedAt is Timestamp) return playedAt.toDate();

    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();

    return null;
  }

  static int _parseDurationString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return -1;

    final chunks = trimmed.split(':');
    if (chunks.length == 2) {
      final minutes = int.tryParse(chunks[0]) ?? 0;
      final seconds = int.tryParse(chunks[1]) ?? 0;
      return (minutes * 60) + seconds;
    }

    if (chunks.length == 3) {
      final hours = int.tryParse(chunks[0]) ?? 0;
      final minutes = int.tryParse(chunks[1]) ?? 0;
      final seconds = int.tryParse(chunks[2]) ?? 0;
      return (hours * 3600) + (minutes * 60) + seconds;
    }

    return int.tryParse(trimmed) ?? -1;
  }
}
