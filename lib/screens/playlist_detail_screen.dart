import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/services/playlist_service.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistService _playlistService = PlaylistService();

  // Method to add a sample song (for testing)
  Future<void> _addSampleSong() async {
    try {
      await _playlistService.addSongToPlaylist(
        widget.playlistId,
        {
          'title': 'Sample Song ${DateTime.now().second}',
          'artist': 'Sample Artist',
          'album': 'Sample Album',
          'duration': '3:45',
          'imageURL': 'assets/her.jpg',
          'addedAt': FieldValue.serverTimestamp(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding song: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to delete a song
  Future<void> _deleteSong(String songId, String songTitle) async {
    try {
      await _playlistService.removeSongFromPlaylist(widget.playlistId, songId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "$songTitle" from playlist'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing song: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(
          widget.playlistName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Add sample song button
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
            onPressed: _addSampleSong,
            tooltip: 'Add Sample Song',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('playlists')
            .doc(widget.playlistId)
            .collection('songs')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error loading songs: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note_outlined,
                      size: 80,
                      color: AppColors.textMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No songs in this playlist',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add songs to start listening',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var song = snapshot.data!.docs[index];
              var songData = song.data() as Map<String, dynamic>;
              String songId = song.id;
              String title = songData['title'] ?? 'Unknown Title';
              String artist = songData['artist'] ?? 'Unknown Artist';
              String album = songData['album'] ?? '';
              String duration = songData['duration'] ?? '0:00';
              String imageURL = songData['imageURL'] ?? 'assets/dandelion.jpg';

              return Card(
                color: AppColors.backgroundMedium,
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.network(
                      imageURL,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: AppColors.textMuted.withOpacity(0.3),
                          child: const Icon(
                            Icons.music_note,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    artist + (album.isNotEmpty ? ' • $album' : ''),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        duration,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.textMuted,
                        ),
                        color: AppColors.backgroundDark,
                        onSelected: (value) {
                          if (value == 'remove') {
                            _deleteSong(songId, title);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.remove_circle, color: Colors.red),
                                SizedBox(width: 10),
                                Text(
                                  'Remove from Playlist',
                                  style: TextStyle(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Play the song
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Playing: $title')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
