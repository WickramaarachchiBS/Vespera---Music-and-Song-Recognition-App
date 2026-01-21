import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/models/playlist.dart';

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

    return _firestore.collection('playlists').where('userId', isEqualTo: _userId).snapshots();
  }

  // Get playlists for the current user (typed)
  Stream<List<Playlist>> getUserPlaylistsTyped() {
    if (_userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('playlists')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Playlist.fromDoc(d)).toList());
  }

  // Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore.collection('playlists').doc(playlistId).delete();
  }

  // Get playlist details
  Stream<DocumentSnapshot> getPlaylistDetails(String playlistId) {
    return _firestore.collection('playlists').doc(playlistId).snapshots();
  }

  // Add a song to a playlist
  Future<void> addSongToPlaylist(String playlistId, Map<String, dynamic> songData) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _firestore.collection('playlists').doc(playlistId).collection('songs').add(songData);
  }

  // Get songs in a playlist (typed)
  Stream<List<Song>> getPlaylistSongs(String playlistId) {
    return _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('songs')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Song.fromDoc(d)).toList());
  }

  // Add a song using the model
  Future<void> addSongToPlaylistModel(String playlistId, Song song) async {
    if (_userId == null) throw Exception('User not authenticated');
    await _firestore.collection('playlists').doc(playlistId).collection('songs').add(song.toMap());
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

  // Get the count of songs in a playlist
  Future<int> getPlaylistSongCount(String playlistId) async {
    final snapshot =
        await _firestore.collection('playlists').doc(playlistId).collection('songs').get();
    return snapshot.docs.length;
  }

  // Get the count of songs in a playlist (stream)
  Stream<int> getPlaylistSongCountStream(String playlistId) {
    return _firestore
        .collection('playlists')
        .doc(playlistId)
        .collection('songs')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
