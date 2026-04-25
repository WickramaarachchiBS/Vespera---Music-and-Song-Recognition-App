import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileTagsHelper {
  static List<String> buildProfileTagsFromSearches(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final artistCounts = <String, int>{};
    final moodCounts = <String, int>{};

    for (final doc in docs) {
      final data = doc.data();
      final artist = (data['artist'] as String?)?.trim() ?? '';
      final title = (data['title'] as String?)?.toLowerCase().trim() ?? '';

      if (artist.isNotEmpty) {
        artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
      }

      final moods = extractMoodsFromTitle(title);
      for (final mood in moods) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    final topArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final tags = <String>[];
    for (final artist in topArtists.take(3)) {
      tags.add('Fan of ${artist.key}');
    }
    for (final mood in topMoods.take(3)) {
      tags.add(mood.key);
    }

    if (tags.length < 5) {
      tags.add('Music Explorer');
    }

    return tags.take(6).toList();
  }

  static List<String> extractMoodsFromTitle(String title) {
    if (title.isEmpty) return const [];

    const moodMap = {
      'chill': ['chill', 'calm', 'relax', 'lofi', 'ambient'],
      'hype': ['hype', 'party', 'dance', 'club', 'drop'],
      'romantic': ['love', 'heart', 'romance', 'kiss'],
      'sad vibes': ['sad', 'lonely', 'cry', 'broken'],
      'focus': ['study', 'focus', 'work', 'instrumental'],
      'throwback': ['classic', 'retro', 'old', 'nostalgia'],
    };

    final matched = <String>[];
    for (final entry in moodMap.entries) {
      for (final keyword in entry.value) {
        if (title.contains(keyword)) {
          matched.add(entry.key);
          break;
        }
      }
    }
    return matched;
  }
}
