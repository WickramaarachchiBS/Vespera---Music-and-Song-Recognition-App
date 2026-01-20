import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/identified_song_with_playlist_modal.dart';
import 'package:vespera/models/discovered_song.dart';
import 'package:vespera/providers/whisper_provider.dart';

class DiscoveredSongsList extends StatelessWidget {
  final List<DiscoveredSong> songs;
  final Function(String) onShowSnackBar;

  const DiscoveredSongsList({super.key, required this.songs, required this.onShowSnackBar});

  String _formatDiscoveryTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WhisperProvider>(context, listen: false);

    if (songs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accentBlue.withOpacity(0.1)),
              child: Icon(Icons.music_note, size: 48, color: AppColors.accentBlue.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              'No discovered songs yet',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button above to identify music',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(songs.length, (index) {
        final song = songs[index];
        return _DiscoveredSongCard(
          song: song,
          index: index,
          onShowSnackBar: onShowSnackBar,
          formatTime: _formatDiscoveryTime,
        );
      }),
    );
  }
}

class _DiscoveredSongCard extends StatelessWidget {
  final DiscoveredSong song;
  final int index;
  final Function(String) onShowSnackBar;
  final String Function(DateTime) formatTime;

  const _DiscoveredSongCard({
    required this.song,
    required this.index,
    required this.onShowSnackBar,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WhisperProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        key: Key('${song.title}_${song.discoveredAt}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.delete, color: Colors.white, size: 28),
        ),
        onDismissed: (direction) async {
          await provider.removeDiscoveredSong(index);
          onShowSnackBar('Song removed');
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final matchedSong = await provider.searchDiscoveredSongInFirebase(song.title);

              if (matchedSong != null && context.mounted) {
                IdentifiedSongWithPlaylistModal.show(context, song: matchedSong, confidence: song.confidence);
              } else {
                onShowSnackBar('Song not found in database. Cannot add to playlist.');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Album art
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          song.imageUrl != null && song.imageUrl!.isNotEmpty
                              ? Image.network(
                                song.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage();
                                },
                              )
                              : _buildPlaceholderImage(),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: AppColors.accentBlue.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              formatTime(song.discoveredAt),
                              style: TextStyle(
                                color: AppColors.accentBlue.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (song.confidence != null) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(song.confidence! * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: AppColors.accentBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action icon
                  Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4), size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentBlue.withOpacity(0.4), AppColors.accentBlue.withOpacity(0.2)],
        ),
      ),
      child: Icon(Icons.music_note, color: Colors.white.withOpacity(0.7), size: 30),
    );
  }
}
