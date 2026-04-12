import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vespera/components/add_to_playlist_modal.dart';
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
          _sliderValue =
              _audioService.position.inMilliseconds / _audioService.duration.inMilliseconds;
        }
      });
    }
  }

  Future<void> _seekToPosition(double value) async {
    final position = Duration(
      milliseconds: (value * _audioService.duration.inMilliseconds).toInt(),
    );
    await _audioService.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _copyToClipboard() {
    final url = _audioService.currentAudioUrl;
    if (url == null) return;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sourceLabel = _audioService.playSource ?? 'Your Library';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A2535), Color(0xFF0D1520)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Top bar: minimize + source label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'PLAYING FROM ${sourceLabel.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

              // Album Art
              Container(
                width: screenWidth * 0.8,
                height: screenWidth * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image:
                        _audioService.hasValidNetworkImage
                            ? NetworkImage(_audioService.currentImageUrl!)
                            : const AssetImage('assets/dandelion.jpg') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),

              // Song Title, Artist, Add-to-playlist
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MarqueeText(
                            key: ValueKey(_audioService.currentSongTitle),
                            text: _audioService.currentSongTitle ?? 'Unknown Song',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _audioService.currentArtist ?? 'Unknown Artist',
                            style: const TextStyle(color: Colors.grey, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.white, size: 30),
                      onPressed: () {
                        final currentSong = _audioService.currentSong;
                        if (currentSong != null) {
                          AddToPlaylistModal.show(context, currentSong);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No song is currently playing'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                    ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_audioService.position),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          _formatDuration(_audioService.duration),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Player Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.repeat,
                      color: _audioService.isRepeat
                          ? const Color(0xFF00BFA5)
                          : Colors.grey,
                      size: 30,
                    ),
                    onPressed: () => _audioService.toggleRepeat(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous,
                        color: Colors.white, size: 40),
                    onPressed: () => _audioService.playPreviousInPlaylist(),
                  ),
                  GestureDetector(
                    onTap: () => _audioService.togglePlayPause(),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        _audioService.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 45,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        color: Colors.white, size: 40),
                    onPressed: () => _audioService.playNextInPlaylist(),
                  ),
                  const Icon(Icons.shuffle, color: Colors.grey, size: 30),
                ],
              ),

              // Bottom row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.speaker_group_outlined, color: Colors.grey),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    tooltip: 'Copy link',
                    onPressed: _copyToClipboard,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

// ---------------------------------------------------------------------------
// Auto-scrolling marquee text
// ---------------------------------------------------------------------------
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({super.key, required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 10));
    _controller.addListener(_onAnimate);
    _controller.addStatusListener(_onStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startIfNeeded());
  }

  void _startIfNeeded() {
    if (!mounted) return;
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      _controller.forward();
    }
  }

  void _onAnimate() {
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      _scrollController.jumpTo(
          _controller.value * _scrollController.position.maxScrollExtent);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
        _controller.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(_MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _controller.stop();
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _startIfNeeded());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style),
    );
  }
}
