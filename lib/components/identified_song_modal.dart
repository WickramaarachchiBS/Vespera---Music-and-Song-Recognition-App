import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/components/add_to_playlist_modal.dart';
import 'package:vespera/services/audio_service.dart';

class IdentifiedSongModal {
  static void show(
    BuildContext context, {
    required String title,
    required String artist,
    double? confidence,
    String? imageUrl,
    String? audioUrl,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _IdentifiedSongContent(
        title: title,
        artist: artist,
        confidence: confidence,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
      ),
    );
  }
}

class _IdentifiedSongContent extends StatelessWidget {
  final String title;
  final String artist;
  final double? confidence;
  final String? imageUrl;
  final String? audioUrl;

  const _IdentifiedSongContent({
    required this.title,
    required this.artist,
    this.confidence,
    this.imageUrl,
    this.audioUrl,
  });

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1B3F),
            const Color(0xFF2D1B4E),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Success icon with animation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentBlue.withOpacity(0.2),
            ),
            child: Icon(
              Icons.music_note,
              size: 48,
              color: AppColors.accentBlue,
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            'Song Identified!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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
                    image: imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: imageUrl == null ? AppColors.accentBlue.withOpacity(0.3) : null,
                  ),
                  child: imageUrl == null
                      ? Icon(
                          Icons.music_note,
                          color: Colors.white.withOpacity(0.5),
                          size: 40,
                        )
                      : null,
                ),

                const SizedBox(width: 16),

                // Song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
                        artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
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
              if (audioUrl != null && audioUrl!.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await audioService.playSong(
                        audioUrl: audioUrl!,
                        title: title,
                        artist: artist,
                        imageUrl: imageUrl,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Now playing: $title'),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              if (audioUrl != null && audioUrl!.isNotEmpty) const SizedBox(width: 12),

              // Add to playlist button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Create a Song object for the identified song
                    final song = Song(
                      id: audioUrl?.hashCode.toString() ?? title.hashCode.toString(),
                      title: title,
                      artist: artist,
                      album: '',
                      duration: '0:00',
                      imageUrl: imageUrl ?? '',
                      audioUrl: audioUrl ?? '',
                      titleLowercase: title.toLowerCase(),
                      artistLowercase: artist.toLowerCase(),
                    );

                    // Show add to playlist modal
                    Navigator.pop(context); // Close current modal
                    AddToPlaylistModal.show(context, song);
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Add to Playlist'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Close button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}