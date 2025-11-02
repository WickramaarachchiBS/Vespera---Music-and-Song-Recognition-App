import 'package:flutter/material.dart';
import 'package:vespera/elements/music_player.dart';
import 'package:vespera/helpers/slide_up_music_player.dart';
import 'package:vespera/services/audio_service.dart';

class MiniMusicPlayer extends StatefulWidget {
  const MiniMusicPlayer({super.key});

  @override
  State<MiniMusicPlayer> createState() => _MiniMusicPlayerState();
}

class _MiniMusicPlayerState extends State<MiniMusicPlayer> {
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _audioService.addListener(_updateState);
  }

  @override
  void dispose() {
    _audioService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show mini player if no song is playing
    if (!_audioService.hasCurrentSong) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          SlideUpPageRoute(
            page: PlayerScreen(
              audioUrl: _audioService.currentAudioUrl!,
            ),
          ),
        );
      },
      child: Container(
        height: 60,
        color: Colors.blueGrey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _audioService.currentImageUrl != null
                          ? Image.network(
                              _audioService.currentImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.music_note, color: Colors.white54),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note, color: Colors.white54),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 180,
                        child: Text(
                          _audioService.currentSongTitle ?? 'Unknown Song',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _audioService.currentArtist ?? 'Unknown Artist',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Icon(
                  _audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  _audioService.togglePlayPause();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
