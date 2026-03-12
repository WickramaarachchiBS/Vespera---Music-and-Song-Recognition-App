import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/models/playlist.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get recommended songs based on the user's recent search history.
  /// Falls back to random songs if no history or not logged in.
  Stream<List<Song>> getRecommendedSongs({int limit = 10}) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return _fallbackSongs(limit);
    }

    // Build a stream that first reads the user's recent artists, then
    // queries songs matching those artists plus a fallback fill.
    return Stream.fromFuture(_buildRecommendedSongs(userId, limit))
        .asyncExpand((songs) {
      // Return the initial list, then listen for live updates on the
      // songs collection so the UI stays fresh.
      if (songs.isEmpty) return _fallbackSongs(limit);
      return Stream.value(songs);
    });
  }

  Future<List<Song>> _buildRecommendedSongs(String userId, int limit) async {
    try {
      // 1. Fetch up to 20 recent searches to extract favourite artists.
      final recentSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recentSongSearches')
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .get();

      // Collect unique artist names (lowercase for matching).
      final artistSet = <String>{};
      for (final doc in recentSnap.docs) {
        final artist = (doc.data()['artist'] as String?)?.trim().toLowerCase();
        if (artist != null && artist.isNotEmpty) artistSet.add(artist);
      }

      if (artistSet.isEmpty) return [];

      // Firestore `whereIn` supports max 30 values.
      final artists = artistSet.take(10).toList();

      // 2. Query songs whose artistLowercase matches one of the user's
      //    favourite artists.
      final songsSnap = await _firestore
          .collection('songs')
          .where('artistLowercase', whereIn: artists)
          .limit(limit)
          .get();

      final songs = songsSnap.docs.map((d) => Song.fromDoc(d)).toList();

      // 3. Shuffle so the order feels fresh on every visit.
      songs.shuffle();

      return songs;
    } catch (e) {
      debugPrint('RecommendationService error: $e');
      return [];
    }
  }

  Stream<List<Song>> _fallbackSongs(int limit) {
    return _firestore
        .collection('songs')
        .limit(limit)
        .snapshots()
        .map((snap) {
      final songs = snap.docs.map((d) => Song.fromDoc(d)).toList();
      songs.shuffle();
      return songs;
    });
  }

  /// Get recommended playlists (public playlists or popular ones)
  Stream<List<Playlist>> getRecommendedPlaylists({int limit = 10}) {
    // Return public/featured playlists
    // You can add a 'featured' field to playlists in Firestore
    return _firestore
        .collection('playlists')
        .where('isPublic', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Playlist.fromDoc(doc)).toList());
  }

  /// Get recently played playlists for the current user
  Stream<List<Playlist>> getRecentPlaylists({int limit = 5}) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('playlists')
        .where('userId', isEqualTo: userId)
        .orderBy('lastModified', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Playlist.fromDoc(doc)).toList());
  }

  /// Get popular songs (you can add play count tracking to implement this)
  Stream<List<Song>> getPopularSongs({int limit = 10}) {
    // Return songs ordered by popularity (needs play count field in Firestore)
    return _firestore
        .collection('songs')
        .orderBy('playCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Song.fromDoc(doc)).toList());
  }

  /// Get songs by genre (if you have genre field)
  Stream<List<Song>> getSongsByGenre(String genre, {int limit = 10}) {
    return _firestore
        .collection('songs')
        .where('genre', isEqualTo: genre)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Song.fromDoc(doc)).toList());
  }
}
