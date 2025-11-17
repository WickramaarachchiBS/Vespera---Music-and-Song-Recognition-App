import 'package:cloud_firestore/cloud_firestore.dart';

class SongSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search songs by title or artist
  Future<List<Map<String, dynamic>>> searchSongs(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Convert query to lowercase for case-insensitive search
      String searchQuery = query.toLowerCase();
      
      // Search by title
      QuerySnapshot titleSnapshot = await _firestore
          .collection('songs')
          .where('title_lowercase', isGreaterThanOrEqualTo: searchQuery)
          .where('title_lowercase', isLessThan: searchQuery + '\uf8ff')
          .limit(20)
          .get();

      // Search by artist
      QuerySnapshot artistSnapshot = await _firestore
          .collection('songs')
          .where('artist_lowercase', isGreaterThanOrEqualTo: searchQuery)
          .where('artist_lowercase', isLessThan: searchQuery + '\uf8ff')
          .limit(20)
          .get();

      // Combine results and remove duplicates
      Set<String> uniqueIds = {};
      List<Map<String, dynamic>> combined = [];

      for (var doc in titleSnapshot.docs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          combined.add({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }
      }

      for (var doc in artistSnapshot.docs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          combined.add({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }
      }

      return combined;
    } catch (e) {
      print('Error searching songs: $e');
      rethrow;
    }
  }

  /// Get all songs (for initial display or browse)
  Future<List<Map<String, dynamic>>> getAllSongs({int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('songs')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print('Error fetching all songs: $e');
      rethrow;
    }
  }

  /// Get song by ID
  Future<Map<String, dynamic>?> getSongById(String songId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('songs')
          .doc(songId)
          .get();

      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      print('Error fetching song by ID: $e');
      rethrow;
    }
  }

  /// Get songs by artist
  Future<List<Map<String, dynamic>>> getSongsByArtist(String artist) async {
    try {
      String artistQuery = artist.toLowerCase();
      
      QuerySnapshot snapshot = await _firestore
          .collection('songs')
          .where('artist_lowercase', isEqualTo: artistQuery)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print('Error fetching songs by artist: $e');
      rethrow;
    }
  }

  /// Add a new song (for your add button)
  Future<String> addSong({
    required String title,
    required String artist,
    String? thumbnail,
    String? audioUrl,
    String? album,
    int? duration,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('songs').add({
        'title': title,
        'title_lowercase': title.toLowerCase(),
        'artist': artist,
        'artist_lowercase': artist.toLowerCase(),
        'thumbnail': thumbnail,
        'audioUrl': audioUrl,
        'album': album,
        'duration': duration,
        'createdAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      });

      return docRef.id;
    } catch (e) {
      print('Error adding song: $e');
      rethrow;
    }
  }

  /// Update song details
  Future<void> updateSong(String songId, Map<String, dynamic> updates) async {
    try {
      // If title or artist is being updated, update lowercase versions too
      if (updates.containsKey('title')) {
        updates['title_lowercase'] = updates['title'].toString().toLowerCase();
      }
      if (updates.containsKey('artist')) {
        updates['artist_lowercase'] = updates['artist'].toString().toLowerCase();
      }

      await _firestore.collection('songs').doc(songId).update(updates);
    } catch (e) {
      print('Error updating song: $e');
      rethrow;
    }
  }

  /// Delete a song
  Future<void> deleteSong(String songId) async {
    try {
      await _firestore.collection('songs').doc(songId).delete();
    } catch (e) {
      print('Error deleting song: $e');
      rethrow;
    }
  }
}