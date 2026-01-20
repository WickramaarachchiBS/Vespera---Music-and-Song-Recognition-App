import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/services/audio_service.dart';
import 'package:vespera/services/playlist_service.dart';

class IdentifiedSongWithPlaylistModal {
  static void show(BuildContext context, {required Song song, double? confidence}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _IdentifiedSongWithPlaylistContent(song: song, confidence: confidence),
    );
  }
}

class _IdentifiedSongWithPlaylistContent extends StatelessWidget {
  final Song song;
  final double? confidence;
  final PlaylistService _playlistService = PlaylistService();

  _IdentifiedSongWithPlaylistContent({required this.song, this.confidence});

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1B3F), const Color(0xFF2D1B4E)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),

              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accentBlue.withOpacity(0.2)),
                child: Icon(Icons.music_note, size: 48, color: AppColors.accentBlue),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'Song Identified!',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              // Song card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Album art
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image:
                            song.imageUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(song.imageUrl), fit: BoxFit.cover)
                                : null,
                        color: song.imageUrl.isEmpty ? AppColors.accentBlue.withOpacity(0.3) : null,
                      ),
                      child:
                          song.imageUrl.isEmpty
                              ? Icon(Icons.music_note, color: Colors.white.withOpacity(0.5), size: 40)
                              : null,
                    ),

                    const SizedBox(width: 16),

                    // Song info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (confidence != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(confidence! * 100).toStringAsFixed(0)}% match',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  // Play button
                  if (song.audioUrl.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await audioService.playSong(
                            audioUrl: song.audioUrl,
                            title: song.title,
                            artist: song.artist,
                            imageUrl: song.imageUrl,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Now playing: ${song.title}'),
                                backgroundColor: AppColors.accentBlue,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),

                  if (song.audioUrl.isNotEmpty) const SizedBox(width: 12),

                  // Close button (if no audio URL)
                  if (song.audioUrl.isEmpty)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Playlist section header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add to Playlist',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              // Playlists list
              StreamBuilder<QuerySnapshot>(
                stream: _playlistService.getUserPlaylists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: AppColors.accentBlue),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No playlists yet. Create one to add songs!',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final playlists = snapshot.data!.docs;

                  return Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final data = playlist.data() as Map<String, dynamic>;
                        final playlistName = data['name'] ?? 'Unnamed Playlist';
                        final playlistImage = data['image'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child:
                                  playlistImage.isNotEmpty
                                      ? Image.network(
                                        playlistImage,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) => Container(
                                              width: 50,
                                              height: 50,
                                              color: AppColors.accentBlue.withOpacity(0.3),
                                              child: const Icon(Icons.playlist_play, color: AppColors.textPrimary),
                                            ),
                                      )
                                      : Container(
                                        width: 50,
                                        height: 50,
                                        color: AppColors.accentBlue.withOpacity(0.3),
                                        child: const Icon(Icons.playlist_play, color: AppColors.textPrimary),
                                      ),
                            ),
                            title: Text(
                              playlistName,
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600),
                            ),
                            trailing: Icon(Icons.add, color: AppColors.accentBlue),
                            onTap: () => _addToPlaylist(context, playlist.id, playlistName),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Close button at bottom
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
