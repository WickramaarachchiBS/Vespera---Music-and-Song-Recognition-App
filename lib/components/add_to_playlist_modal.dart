import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/services/playlist_service.dart';

class AddToPlaylistModal {
  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddToPlaylistContent(song: song),
    );
  }
}

class _AddToPlaylistContent extends StatelessWidget {
  final Song song;
  final PlaylistService _playlistService = PlaylistService();

  _AddToPlaylistContent({required this.song});

  Future<void> _addToPlaylist(BuildContext context, String playlistId, String playlistName) async {
    try {
      await _playlistService.addSongToPlaylistModel(playlistId, song);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${song.title}" to "$playlistName"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding song to playlist: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add to Playlist',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Song info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child:
                        song.imageUrl.isNotEmpty
                            ? Image.network(
                              song.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.music_note, color: Colors.white),
                                  ),
                            )
                            : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note, color: Colors.white),
                            ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: TextStyle(
                            color: AppColors.textPrimary.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Playlists list
            const Text(
              'Select Playlist',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _playlistService.getUserPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error loading playlists',
                        style: TextStyle(color: Colors.red[300]),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.playlist_add,
                            size: 48,
                            color: AppColors.textPrimary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No playlists yet',
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a playlist from the Library screen',
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var playlist = snapshot.data!.docs[index];
                      var playlistData = playlist.data() as Map<String, dynamic>;
                      String playlistName = playlistData['name'] ?? 'Untitled';
                      String imageUrl = playlistData['imageURL'] ?? '';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child:
                              imageUrl.isNotEmpty
                                  ? Image.asset(
                                    imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.library_music,
                                            color: Colors.white,
                                          ),
                                        ),
                                  )
                                  : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.library_music, color: Colors.white),
                                  ),
                        ),
                        title: Text(
                          playlistName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.green,
                          size: 28,
                        ),
                        onTap: () => _addToPlaylist(context, playlist.id, playlistName),
                      );
                    },
                  ),
              );
            },
          ),
        ],
      ),
    ),
      ),
    );
  }
}