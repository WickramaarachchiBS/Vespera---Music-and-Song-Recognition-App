import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/dialogs/edit_playlist_dialog.dart';
import 'package:vespera/helpers/app_notification.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/screens/common_screen.dart';
import 'package:vespera/services/audio_service.dart';
import 'package:vespera/services/playlist_service.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailScreen({super.key, required this.playlistId, required this.playlistName});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistService _playlistService = PlaylistService();
  final AudioService _audioService = AudioService();
  String _sortBy = 'dateAdded'; // 'dateAdded', 'titleAZ', 'titleZA', 'duration'

  Stream<List<Song>> _getPlaylistSongs() {
    return _playlistService.getPlaylistSongs(widget.playlistId);
  }

  Future<void> _playPlaylist(List<Song> songs, int startIndex, String playlistName) async {
    await _audioService.playSongs(playlist: songs, startIndex: startIndex, playlistName: playlistName);
  }

  // Method to delete a song
  Future<void> _deleteSong(String songId, String songTitle) async {
    try {
      await _playlistService.removeSongFromPlaylist(widget.playlistId, songId);
      if (mounted) {
        AppNotification.showSuccess(context, 'Removed "$songTitle" from playlist');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Error removing song: $e');
      }
    }
  }

  // Method to sort songs based on the selected sort option
  List<Song> _sortSongs(List<Song> songs) {
    final sorted = List<Song>.from(songs);
    
    switch (_sortBy) {
      case 'titleAZ':
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'titleZA':
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case 'duration':
        sorted.sort((a, b) {
          // Parse duration strings (e.g., "3:45" -> seconds)
          int getDurationInSeconds(String duration) {
            final parts = duration.split(':');
            if (parts.length == 2) {
              return int.parse(parts[0]) * 60 + int.parse(parts[1]);
            }
            return 0;
          }
          return getDurationInSeconds(a.duration).compareTo(getDurationInSeconds(b.duration));
        });
        break;
      case 'dateAdded':
      default:
        // Keep original order (already sorted by Firebase)
        break;
    }
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _playlistService.getPlaylistDetails(widget.playlistId),
        builder: (context, playlistSnapshot) {
          final playlistData = playlistSnapshot.data?.data() as Map<String, dynamic>?;
          final imageUrl = playlistData?['imageURL'] ?? '';
          final currentPlaylistName = playlistData?['name'] ?? widget.playlistName;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.backgroundDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.textPrimary, size: 20,),
                    onPressed: () {
                      EditPlaylistDialog.show(
                        context,
                        playlistId: widget.playlistId,
                        currentName: currentPlaylistName,
                        onSuccess: () {
                          // No need to setState - StreamBuilder will auto-update from Firestore
                        },
                      );
                    },
                    tooltip: 'Edit Playlist',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 28,),
                    onPressed: () {
                      // Navigate back to CommonScreen with search tab selected (index 1)
                      Navigator.of(context, rootNavigator: true).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const CommonScreen(initialIndex: 1),
                        ),
                      );
                    },
                    tooltip: 'Add Song',
                  ),
                ],
                centerTitle: true,
                title: Text(
                  currentPlaylistName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.backgroundDark,
                          AppColors.backgroundDark.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl.isEmpty || imageUrl == 'err'
                                ? Image.asset(
                                    'assets/errorLoading.jpg',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    imageUrl,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/errorLoading.jpg',
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Sort chips widget
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Date Added'),
                        selected: _sortBy == 'dateAdded',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortBy = 'dateAdded');
                          }
                        },
                        backgroundColor: AppColors.backgroundMedium,
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: _sortBy == 'dateAdded' ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: _sortBy == 'dateAdded' ? Colors.green : AppColors.backgroundLight,
                          width: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      FilterChip(
                        label: const Text('A-Z'),
                        selected: _sortBy == 'titleAZ',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortBy = 'titleAZ');
                          }
                        },
                        backgroundColor: AppColors.backgroundMedium,
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: _sortBy == 'titleAZ' ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: _sortBy == 'titleAZ' ? Colors.green : AppColors.backgroundLight,
                          width: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      FilterChip(
                        label: const Text('Z-A'),
                        selected: _sortBy == 'titleZA',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortBy = 'titleZA');
                          }
                        },
                        backgroundColor: AppColors.backgroundMedium,
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: _sortBy == 'titleZA' ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: _sortBy == 'titleZA' ? Colors.green : AppColors.backgroundLight,
                          width: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      FilterChip(
                        label: const Text('Duration'),
                        selected: _sortBy == 'duration',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortBy = 'duration');
                          }
                        },
                        backgroundColor: AppColors.backgroundMedium,
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: _sortBy == 'duration' ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: _sortBy == 'duration' ? Colors.green : AppColors.backgroundLight,
                          width: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: StreamBuilder<List<Song>>(
                  stream: _getPlaylistSongs(),
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
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: Colors.green),
                        ),
                      );
                    }

                    final songs = snapshot.data ?? const <Song>[];
                    if (songs.isEmpty) {
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
                                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Apply sorting to songs
                    final sortedSongs = _sortSongs(songs);

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedSongs.length,
                      itemBuilder: (context, index) {
                        final song = sortedSongs[index];

                        return Card(
                          color: AppColors.backgroundMedium,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              if (song.audioUrl.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Audio URL missing for this song')),
                                );
                                return;
                              }
                              print('\x1B[32m${song.title}\x1B[0m');
                              print('\x1B[32m${song.artist}\x1B[0m');
                              print('\x1B[32m${song.audioUrl}\x1B[0m');
                              _playPlaylist(sortedSongs, index, currentPlaylistName);
                            },
                            child: ListTile(
                              leading: SizedBox(
                                width: 50.0,
                                height: 50.0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: Image.network(
                                    song.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container();
                                    },
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                song.artist + (song.album.isNotEmpty ? ' • ${song.album}' : ''),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    song.duration,
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.textMuted),
                                    color: AppColors.backgroundDark,
                                    onSelected: (value) {
                                      if (value == 'remove') {
                                        _deleteSong(song.id, song.title);
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
                            ),
                          ),
                        );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
    );
  }
}
