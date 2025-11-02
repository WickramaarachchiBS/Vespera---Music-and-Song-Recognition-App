import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/create_playlist_modal.dart';
import 'package:vespera/screens/playlist_detail_screen.dart';
import 'package:vespera/services/playlist_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final PlaylistService _playlistService = PlaylistService();

  // Create playlist
  Future<void> _createPlaylist(String playlistName) async {
    try {
      await _playlistService.createPlaylist(playlistName, 'assets/dandelion.jpg');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Playlist "$playlistName" created!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating playlist: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Your Library',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.textPrimary),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 15.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: CircleAvatar(backgroundImage: AssetImage('assets/profilePic.jpg')),
          ),
        ),
        actions: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 8.0),
                child: IconButton(
                  //USE A CUSTOM ICON FOR THIS
                  icon: const Icon(Icons.search_rounded, size: 30, color: AppColors.textPrimary),
                  // Handle search button press
                  onPressed: () {},
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 8.0),
                child: IconButton(
                  //USE A CUSTOM ICON FOR THIS
                  icon: const Icon(Icons.add, size: 35, color: AppColors.textPrimary),
                  // Handle add button press
                  onPressed: () {
                    CreatePlaylistModal.show(context, _createPlaylist);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.green, width: 2.0))),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text(
                    'Playlists',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),

            // Display playlists from firebase
            StreamBuilder<QuerySnapshot>(
              stream: _playlistService.getUserPlaylists(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error loading playlists: ${snapshot.error}',
                        style: TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_music_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No playlists yet',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first playlist!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var playlist = snapshot.data!.docs[index];
                    var playlistData = playlist.data() as Map<String, dynamic>;
                    String playlistId = playlist.id;
                    String name = playlistData['name'] ?? 'Untitled';
                    String imageURL = playlistData['imageURL'] ?? '';

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                      color: AppColors.textMuted.withOpacity(0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                      child: ListTile(
                        style: ListTileStyle.drawer,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Image.asset(
                            imageURL,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: AppColors.textMuted.withOpacity(0.3),
                                child: Icon(Icons.music_note, color: AppColors.textMuted),
                              );
                            },
                          ),
                        ),
                        title: Text(name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text('Playlist', style: TextStyle(color: AppColors.textMuted)),
                        onTap: () {
                          Navigator.of(context, rootNavigator: false).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => PlaylistDetailScreen(
                                    playlistId: playlistId,
                                    playlistName: name,
                                  ),
                            ),
                          );

                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
