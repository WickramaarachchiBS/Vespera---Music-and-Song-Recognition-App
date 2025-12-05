import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vespera/models/song.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all songs once
  Future<List<Song>> fetchAllSongs() async {
    try {
      final snap = await _firestore.collection('songs').get();
      return snap.docs.map((d) => Song.fromDoc(d)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('fetchAllSongs error: $e');
      return [];
    }
  }

  // Prefix search on precomputed lowercase fields
  Future<List<Song>> searchSongs(String rawQuery) async {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return [];
    final end = '$q\uf8ff';

    try {
      print('Searching for songs with query: $q');
      final titleFuture = _firestore
          .collection('songs')
          .where('titleLowercase', isGreaterThanOrEqualTo: q)
          .where('titleLowercase', isLessThanOrEqualTo: end)
          .get();

      final artistFuture = _firestore
          .collection('songs')
          .where('artistLowercase', isGreaterThanOrEqualTo: q)
          .where('artistLowercase', isLessThanOrEqualTo: end)
          .limit(25)
          .get();

      final results = await Future.wait([titleFuture, artistFuture]);

      final seen = <String>{};
      final merged = <Song>[];
      for (final r in results) {
        for (final doc in r.docs) {
          if (seen.add(doc.id)) {
            merged.add(Song.fromDoc(doc));
          }
        }
      }
      print('Found ${merged.length} songs for query: $q');
      return merged;
    } catch (e) {
      // ignore: avoid_print
      print('searchSongs error: $e');
      return [];
    }
  }

  // Optional: store recent searches per user (song-based)
  Future<void> addRecentSongSearch({
    required String userId,
    required Song song,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('recentSongSearches')
        .doc(song.id);
    await ref.set({
      'songId': song.id,
      'title': song.title,
      'artist': song.artist,
      'imageUrl': song.imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getRecentSongSearches(String userId,
      {int limit = 10}) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recentSongSearches')
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      // ignore: avoid_print
      print('getRecentSongSearches error: $e');
      return [];
    }
  }

  // Optional: store raw query terms
  Future<void> addRecentQuery({
    required String userId,
    required String query,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('recentQueries')
        .doc(query.toLowerCase());
    await docRef.set({
      'query': query,
      'queryLowercase': query.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<String>> getRecentQueries(String userId, {int limit = 8}) async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recentQueries')
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => (d.data()['query'] as String?) ?? '').where((e) => e.isNotEmpty).toList();
    } catch (e) {
      // ignore: avoid_print
      print('getRecentQueries error: $e');
      return [];
    }
  }
  
}