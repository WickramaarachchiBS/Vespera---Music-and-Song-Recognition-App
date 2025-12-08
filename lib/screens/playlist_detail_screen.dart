import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/models/song.dart';
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

  Stream<List<Song>> _getPlaylistSongs() {
    return _playlistService.getPlaylistSongs(widget.playlistId);
  }

  Future<void> _playPlaylist(List<Song> songs, int startIndex) async {
    await _audioService.playSongs(playlist: songs, startIndex: startIndex);
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
          SnackBar(content: Text('Error removing song: $e'), backgroundColor: Colors.red),
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
            onPressed: () {},
            tooltip: 'Add Sample Song',
          ),
        ],
      ),
      body: StreamBuilder<List<Song>>(
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
            return const Center(child: CircularProgressIndicator(color: Colors.green));
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

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];

              return Card(
                color: AppColors.backgroundMedium,
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                        itemBuilder:
                            (context) => [
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
                    if (song.audioUrl.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Audio URL missing for this song')),
                      );
                      return;
                    }
                    print('\x1B[32m${song.title}\x1B[0m');
                    print('\x1B[32m${song.artist}\x1B[0m');
                    print('\x1B[32m${song.audioUrl}\x1B[0m');
                    _playPlaylist(songs, index);
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
