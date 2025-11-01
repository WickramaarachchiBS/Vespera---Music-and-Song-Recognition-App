import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user id
  String? get _userId => _auth.currentUser?.uid;

  // Create a new playlist
  Future<void> createPlaylist(String playlistName, String imageURL) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore.collection('playlists').add({
      'name': playlistName,
      'imageURL': imageURL,
      'userId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get playlists for the current user
  Stream<QuerySnapshot> getUserPlaylists() {
    if (_userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('playlists')
        .where('userId', isEqualTo: _userId)
        .snapshots();
  }

  // Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore.collection('playlists').doc(playlistId).delete();
  }

  // Add a song to a playlist
  Future<void> addSongToPlaylist(String playlistId, Map<String, dynamic> songData) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore.collection('playlists').doc(playlistId).collection('songs').add(songData);
  }

  // Remove a song from a playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('songs')
        .doc(songId)
        .delete();
  }
}
