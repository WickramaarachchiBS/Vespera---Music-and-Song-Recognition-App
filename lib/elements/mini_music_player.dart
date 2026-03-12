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

  double get _progress {
    final duration = _audioService.duration;
    if (duration == Duration.zero) return 0.0;
    return (_audioService.position.inMilliseconds / duration.inMilliseconds)
        .clamp(0.0, 1.0);
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A2535), Color(0xFF111B27)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4)),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: _audioService.currentImageUrl != null
                                    ? Image.network(
                                        _audioService.currentImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const ColoredBox(
                                            color: Color(0xFF1E2D3D),
                                            child: Icon(Icons.music_note,
                                                color: Colors.white54),
                                          );
                                        },
                                      )
                                    : const ColoredBox(
                                        color: Color(0xFF1E2D3D),
                                        child: Icon(Icons.music_note,
                                            color: Colors.white54),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _audioService.currentSongTitle ??
                                        'Unknown Song',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _audioService.currentArtist ??
                                        'Unknown Artist',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: IconButton(
                        icon: Icon(
                          _audioService.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
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
              LinearProgressIndicator(
                value: _progress,
                minHeight: 2,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00BFA5)),
              ),
            ],
          ),
        ),
    );
  }
}
