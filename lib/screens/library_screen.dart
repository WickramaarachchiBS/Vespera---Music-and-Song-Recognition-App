import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/appbar_profile_avatar.dart';
import 'package:vespera/components/create_playlist_modal.dart';
import 'package:vespera/helpers/app_notification.dart';
import 'package:vespera/screens/playlist_detail_screen.dart';
import 'package:vespera/services/playlist_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final PlaylistService _playlistService = PlaylistService();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Create playlist
  Future<void> _createPlaylist(String playlistName) async {
    try {
      await _playlistService.createPlaylist(playlistName, 'assets/dandelion.jpg');

      if (mounted) {
        AppNotification.showSuccess(context, 'Playlist "$playlistName" created!');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Error creating playlist: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Row(
          children: [
            if (!_isSearching) ...[
              const AppBarProfileAvatar(),
              const SizedBox(width: 8),
              const Text(
                'Your Library',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.textPrimary),
              ),
            ] else ...[
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search playlists...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search_rounded, size: 30, color: AppColors.textPrimary),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) _searchController.clear();
                    });
                  },
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
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.green, width: 2.0)),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text(
                    'Playlists',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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
                          Icon(
                            Icons.library_music_outlined,
                            size: 64,
                            color: AppColors.textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No playlists yet',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                // Apply client-side filtering based on search query
                final query = _searchController.text.toLowerCase();
                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(query);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('No playlists match your search.', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var playlist = docs[index];
                    var playlistData = playlist.data() as Map<String, dynamic>;
                    String playlistId = playlist.id;
                    String name = playlistData['name'] ?? 'Untitled';
                    String imageURL = playlistData['imageURL'] ?? 'err';
                    final imageUri = Uri.tryParse(imageURL);
                    final isNetworkImage =
                      imageUri != null &&
                      (imageUri.scheme == 'http' || imageUri.scheme == 'https') &&
                      imageUri.host.isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                      ),
                      child: Dismissible(
                        key: Key('playlist_$playlistId'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                backgroundColor: AppColors.backgroundDark,
                                title: Text(
                                  'Delete playlist',
                                  style: TextStyle(color: AppColors.textPrimary),
                                ),
                                content: Text(
                                  'Are you sure you want to delete "$name"? This cannot be undone.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: AppColors.textPrimary),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ) ?? false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white, size: 28),
                        ),
                        onDismissed: (direction) async {
                          try {
                            await _playlistService.deletePlaylist(playlistId);
                            if (mounted) {
                              AppNotification.showSuccess(context, 'Deleted playlist "$name"');
                            }
                          } catch (e) {
                            if (mounted) {
                              AppNotification.showError(context, 'Error deleting playlist: $e');
                            }
                          }
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              print('\x1B[32mPlaylist tapped: $name\x1B[0m');
                              Navigator.of(context, rootNavigator: false).push(
                                MaterialPageRoute(
                                  builder: (context) => PlaylistDetailScreen(
                                    playlistId: playlistId,
                                    playlistName: name,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: imageURL.isEmpty || imageURL == 'err'
                                        ? Image.asset(
                                            'assets/errorLoading.jpg',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          )
                                        : isNetworkImage
                                        ? Image.network(
                                            imageURL,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/errorLoading.jpg',
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            imageURL,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/errorLoading.jpg',
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        StreamBuilder<int>(
                                          stream: _playlistService.getPlaylistSongCountStream(playlistId),
                                          builder: (context, songSnapshot) {
                                            if (songSnapshot.connectionState == ConnectionState.waiting) {
                                              return Text(
                                                'Loading...',
                                                style: TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 13,
                                                ),
                                              );
                                            }
                                            final songCount = songSnapshot.data ?? 0;
                                            return Text(
                                              '$songCount ${songCount == 1 ? 'song' : 'songs'}',
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 13,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textMuted.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
