// test/models/discovered_song_test.dart
//
// Unit tests for DiscoveredSong – JSON serialisation round-trip,
// field mapping, and default value behaviour.

import 'package:flutter_test/flutter_test.dart';
import 'package:vespera/models/discovered_song.dart';

void main() {
  group('DiscoveredSong – construction', () {
    test('all required fields are stored correctly', () {
      final DateTime ts = DateTime(2025, 3, 15, 12, 0, 0);
      final DiscoveredSong song = DiscoveredSong(
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        confidence: 88.5,
        matchCount: 112,
        queriedPeakCount: 340,
        imageUrl: 'https://example.com/image.jpg',
        audioUrl: 'https://example.com/audio.mp3',
        discoveredAt: ts,
      );

      expect(song.title, 'Blinding Lights');
      expect(song.artist, 'The Weeknd');
      expect(song.confidence, closeTo(88.5, 0.001));
      expect(song.matchCount, 112);
      expect(song.queriedPeakCount, 340);
      expect(song.imageUrl, 'https://example.com/image.jpg');
      expect(song.audioUrl, 'https://example.com/audio.mp3');
      expect(song.discoveredAt, ts);
    });

    test('optional fields default to null', () {
      final DiscoveredSong song = DiscoveredSong(
        title: 'Title',
        artist: 'Artist',
      );
      expect(song.confidence, isNull);
      expect(song.matchCount, isNull);
      expect(song.queriedPeakCount, isNull);
      expect(song.imageUrl, isNull);
      expect(song.audioUrl, isNull);
    });

    test('discoveredAt defaults to now when not provided', () {
      final DateTime before = DateTime.now();
      final DiscoveredSong song = DiscoveredSong(
        title: 'T',
        artist: 'A',
      );
      final DateTime after = DateTime.now();
      expect(
        song.discoveredAt.isAfter(before) ||
            song.discoveredAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        song.discoveredAt.isBefore(after) ||
            song.discoveredAt.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });

  group('DiscoveredSong – toJson / fromJson round-trip', () {
    test('full round-trip preserves all values', () {
      final DateTime ts = DateTime.utc(2025, 6, 1, 10, 30, 0);
      final DiscoveredSong original = DiscoveredSong(
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        confidence: 95.0,
        matchCount: 200,
        queriedPeakCount: 420,
        imageUrl: 'https://img.example.com/soy.jpg',
        audioUrl: 'https://audio.example.com/soy.mp3',
        discoveredAt: ts,
      );

      final Map<String, dynamic> json = original.toJson();
      final DiscoveredSong restored = DiscoveredSong.fromJson(json);

      expect(restored.title, original.title);
      expect(restored.artist, original.artist);
      expect(restored.confidence, original.confidence);
      expect(restored.matchCount, original.matchCount);
      expect(restored.queriedPeakCount, original.queriedPeakCount);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.audioUrl, original.audioUrl);
      expect(restored.discoveredAt.toIso8601String(),
          original.discoveredAt.toIso8601String());
    });

    test('round-trip with null optional fields', () {
      final DateTime ts = DateTime.utc(2025, 1, 1);
      final DiscoveredSong original = DiscoveredSong(
        title: 'Unknown',
        artist: 'Unknown',
        discoveredAt: ts,
      );
      final DiscoveredSong restored =
          DiscoveredSong.fromJson(original.toJson());
      expect(restored.confidence, isNull);
      expect(restored.matchCount, isNull);
      expect(restored.imageUrl, isNull);
      expect(restored.audioUrl, isNull);
    });

    test('toJson emits all expected keys', () {
      final DiscoveredSong song = DiscoveredSong(
        title: 'T',
        artist: 'A',
        discoveredAt: DateTime.utc(2025),
      );
      final Set<String> keys = song.toJson().keys.toSet();
      expect(keys, containsAll(<String>[
        'title',
        'artist',
        'confidence',
        'matchCount',
        'queriedPeakCount',
        'imageUrl',
        'audioUrl',
        'discoveredAt',
      ]));
    });

    test('fromJson handles matchCount as string integer', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'title': 'T',
        'artist': 'A',
        'confidence': null,
        'matchCount': '77',
        'queriedPeakCount': '300',
        'imageUrl': null,
        'audioUrl': null,
        'discoveredAt': DateTime.utc(2025).toIso8601String(),
      };
      final DiscoveredSong song = DiscoveredSong.fromJson(json);
      expect(song.matchCount, 77);
      expect(song.queriedPeakCount, 300);
    });

    test('fromJson handles matchCount as native int', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'title': 'T',
        'artist': 'A',
        'confidence': 50.0,
        'matchCount': 55,
        'queriedPeakCount': 200,
        'imageUrl': null,
        'audioUrl': null,
        'discoveredAt': DateTime.utc(2025).toIso8601String(),
      };
      final DiscoveredSong song = DiscoveredSong.fromJson(json);
      expect(song.matchCount, 55);
    });
  });
}
