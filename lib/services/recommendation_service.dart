import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/models/playlist.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get recommended songs based on recently played songs
  Stream<List<Song>> getRecommendedSongs({int limit = 10}) {
    // For now, return random songs from the database
    // You can enhance this with actual recommendation logic later
    return _firestore
        .collection('songs')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Song.fromDoc(doc)).toList());
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
