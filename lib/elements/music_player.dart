import 'package:flutter/material.dart';
import 'package:vespera/services/audio_service.dart';

class PlayerScreen extends StatefulWidget {
  final String audioUrl;
  const PlayerScreen({super.key, required this.audioUrl});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioService _audioService = AudioService();
  double _sliderValue = 0.0;

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
      setState(() {
        if (_audioService.duration.inMilliseconds > 0) {
          _sliderValue = _audioService.position.inMilliseconds / _audioService.duration.inMilliseconds;
        }
      });
    }
  }

  Future<void> _seekToPosition(double value) async {
    final position = Duration(milliseconds: (value * _audioService.duration.inMilliseconds).toInt());
    await _audioService.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Top buttons: Minimize and More
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                    onPressed: () {
                      // This pops the current screen off the navigation stack
                      Navigator.pop(context);
                    },
                  ),
                  const Text('PLAYING FROM YOUR LIBRARY', style: TextStyle(color: Colors.white, fontSize: 12)),
                  const Icon(Icons.more_vert, color: Colors.white, size: 30),
                ],
              ),

              // Album Art
              Container(
                width: screenWidth * 0.8,
                height: screenWidth * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: _audioService.currentImageUrl != null ? NetworkImage(_audioService.currentImageUrl!) : const AssetImage('assets/dandelion.jpg') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
              ),

              // Song Title and Artist
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _audioService.currentSongTitle ?? 'Unknown Song',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _audioService.currentArtist ?? 'Unknown Artist',
                          style: const TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                    const Column(children: [Icon(Icons.add_circle_outline, color: Colors.white, size: 30)]),
                  ],
                ),
              ),

              // Seek Bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _sliderValue.clamp(0.0, 1.0),
                      min: 0,
                      max: 1,
                      activeColor: Colors.white,
                      inactiveColor: Colors.grey[700],
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _seekToPosition(value);
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_audioService.position), style: const TextStyle(color: Colors.grey)),
                        Text(_formatDuration(_audioService.duration), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),

              // Player Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Icon(Icons.shuffle, color: Colors.grey, size: 30),
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                    onPressed: () async {
                      await _audioService.seekTo(Duration.zero);
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      _audioService.togglePlayPause();
                    },
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        _audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 45,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                    onPressed: () async {
                      // TODO: Implement next track functionality.
                    },
                  ),
                  const Icon(Icons.repeat, color: Colors.grey, size: 30),
                ],
              ),

              // Bottom Icons
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.speaker_group_outlined, color: Colors.grey),
                  Icon(Icons.share_outlined, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
