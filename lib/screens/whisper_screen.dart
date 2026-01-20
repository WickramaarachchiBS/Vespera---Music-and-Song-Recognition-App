import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/services/whisper_services.dart';
import 'package:vespera/components/identified_song_with_playlist_modal.dart';
import 'package:vespera/models/discovered_song.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/services/discovered_songs_service.dart';
import 'package:vespera/services/audio_service.dart';
import 'package:vespera/services/search_service.dart';

enum ListeningState { idle, listening }

class WhisperScreen extends StatefulWidget {
  const WhisperScreen({super.key});

  @override
  State<WhisperScreen> createState() => _WhisperScreenState();
}

class _WhisperScreenState extends State<WhisperScreen> with TickerProviderStateMixin {
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  final WhisperService _whisperService = WhisperService();
  final DiscoveredSongsService _discoveredSongsService = DiscoveredSongsService();
  final AudioService _audioService = AudioService();
  final SearchService _searchService = SearchService();

  ListeningState _state = ListeningState.idle;
  String? _lastSavedPath;
  List<DiscoveredSong> _discoveredSongs = [];

  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  final Uri _identifyEndpoint = Uri.parse('http://192.168.1.80:8000/api/identify');

  @override
  void initState() {
    super.initState();
    _loadDiscoveredSongs();

    // Pulse animation for idle state
    _pulseController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this)
      ..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Ripple animation for listening state
    _rippleController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);

    // Glow animation for listening state
    _glowController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    // Scale animation for button press
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  Future<void> _loadDiscoveredSongs() async {
    final songs = await _discoveredSongsService.getDiscoveredSongs();
    setState(() => _discoveredSongs = songs);
  }

  @override
  void dispose() {
    _draggableController.dispose();
    _whisperService.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _startTenSecondRecording() async {
    if (_state == ListeningState.listening) return;

    setState(() => _state = ListeningState.listening);
    _rippleController.repeat();
    _glowController.repeat(reverse: true);

    final result = await _whisperService.startTenSecondRecording();
    if (!mounted) return;

    setState(() => _state = ListeningState.idle);
    _rippleController.stop();
    _rippleController.reset();
    _glowController.stop();
    _glowController.reset();

    if (result.failure == WhisperRecordingFailure.permissionDenied) {
      _showSnackBar('Microphone permission is required to record audio.');
      return;
    }

    if (result.failure == WhisperRecordingFailure.failed) {
      _showSnackBar('Recording failed.');
      return;
    }

    setState(() => _lastSavedPath = result.savedPath);

    if (_lastSavedPath != null) {
      final identify = await _whisperService.identifySongFromFile(
        filePath: _lastSavedPath!,
        endpoint: _identifyEndpoint,
        fileField: 'audio_file',
      );
      if (!mounted) return;

      if (!identify.ok) {
        _showSnackBar(identify.error ?? 'Song identification failed.');
        return;
      }

      final title = (identify.title?.trim().isNotEmpty ?? false) ? identify.title!.trim() : 'Unknown title';
      final artist = (identify.artist?.trim().isNotEmpty ?? false) ? identify.artist!.trim() : 'Unknown artist';

      print('🎵 Identified: "$title" by "$artist"');

      // Don't process songs with unknown title
      if (title.toLowerCase() == 'unknown title') {
        _showSnackBar('Could not identify song. Please try again.', duration: 3);
        return;
      }

      // Search for the song in Firebase
      final searchResults = await _searchService.searchSongs(title);

      print('📋 Search returned ${searchResults.length} results');
      for (final song in searchResults) {
        print('   - "${song.title}" by "${song.artist}"');
      }

      if (!mounted) return;

      // Try to find a matching song in Firebase
      // Priority: 1) Title + Artist match, 2) Title match only
      Song? matchedSong;

      // First, try to find exact title match
      final titleLower = title.toLowerCase();
      final exactTitleMatches = searchResults.where((song) => song.titleLowercase == titleLower).toList();

      if (exactTitleMatches.isNotEmpty) {
        matchedSong = exactTitleMatches.first;
        print('✅ Exact title match: "${matchedSong.title}" by "${matchedSong.artist}"');
      } else {
        // Try partial title match
        final partialMatches =
            searchResults.where((song) {
              return song.titleLowercase.contains(titleLower) || titleLower.contains(song.titleLowercase);
            }).toList();

        if (partialMatches.isNotEmpty) {
          matchedSong = partialMatches.first;
          print('✅ Partial title match: "${matchedSong.title}" by "${matchedSong.artist}"');
        } else {
          print('❌ No match found in database');
        }
      }

      if (matchedSong != null) {
        // Song found in Firebase - create discovered song and show merged modal
        final discoveredSong = DiscoveredSong(
          title: matchedSong.title,
          artist: matchedSong.artist,
          confidence: identify.confidence,
          imageUrl: matchedSong.imageUrl,
          audioUrl: matchedSong.audioUrl,
        );

        await _discoveredSongsService.addDiscoveredSong(discoveredSong);
        await _loadDiscoveredSongs(); // Reload the list

        // Show the merged modal with full song data
        if (mounted) {
          IdentifiedSongWithPlaylistModal.show(context, song: matchedSong, confidence: identify.confidence);
        }
      } else {
        // Song not found in Firebase - don't show playlist option
        _showSnackBar('Song "$title" identified but not found in database. Cannot add to playlist.', duration: 4);

        // Still save to discovered songs for history
        final discoveredSong = DiscoveredSong(
          title: title,
          artist: artist,
          confidence: identify.confidence,
          imageUrl: identify.raw?['imageUrl']?.toString(),
          audioUrl: identify.raw?['audioUrl']?.toString(),
        );

        await _discoveredSongsService.addDiscoveredSong(discoveredSong);
        await _loadDiscoveredSongs();
      }
    }
  }

  void _showSnackBar(String message, {int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E27),
              const Color(0xFF1A1B3F),
              const Color(0xFF2D1B4E),
              const Color(0xFF0F0C29),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Text(
                    'Vespera',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  _buildCenterButton(),
                  const SizedBox(height: 30),
                  _buildStatusText(),
                  const Spacer(),
                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Draggable sheet
            _buildDraggableSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return SizedBox(
      height: 400,
      width: 400,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple waves for listening state
          if (_state == ListeningState.listening) ...[
            _buildRippleWave(delay: 0.0, maxSize: 280),
            _buildRippleWave(delay: 0.33, maxSize: 320),
            _buildRippleWave(delay: 0.66, maxSize: 360),
          ],

          // Outer glow circle
          AnimatedBuilder(
            animation: _state == ListeningState.listening ? _glowController : _pulseController,
            builder: (context, child) {
              return Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBlue.withOpacity(_state == ListeningState.listening ? 0.4 : 0.2),
                      blurRadius: _state == ListeningState.listening ? 40 : 30,
                      spreadRadius: _state == ListeningState.listening ? 10 : 5,
                    ),
                  ],
                ),
              );
            },
          ),

          // Main button
          GestureDetector(
            onTap: _startTenSecondRecording,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _state == ListeningState.idle ? _pulseAnimation.value : 1.0,
                  child: Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.accentBlue.withOpacity(0.8), AppColors.accentBlue.withOpacity(0.4)],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        _state == ListeningState.listening ? Icons.graphic_eq : Icons.music_note,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRippleWave({required double delay, required double maxSize}) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        final value = (_rippleController.value + delay) % 1.0;
        final opacity = (1.0 - value) * 0.5;

        return Container(
          height: maxSize * value,
          width: maxSize * value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentBlue.withOpacity(opacity), width: 2),
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _state == ListeningState.listening ? 'Listening...' : 'Tap to identify music',
        key: ValueKey(_state),
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 20,
          fontWeight: FontWeight.w400,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.15, 0.5, 0.95],
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Discovered Songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_discoveredSongs.length} Tracks',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Show discovered songs or empty state
                      if (_discoveredSongs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accentBlue.withOpacity(0.1),
                                ),
                                child: Icon(Icons.music_note, size: 48, color: AppColors.accentBlue.withOpacity(0.5)),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No discovered songs yet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the button above to identify music',
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: List.generate(_discoveredSongs.length, (index) {
                            final song = _discoveredSongs[index];
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
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                                ),
                                onDismissed: (direction) async {
                                  await _discoveredSongsService.removeDiscoveredSong(index);
                                  await _loadDiscoveredSongs();
                                  _showSnackBar('Song removed', duration: 2);
                                },
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      // Search for the song in Firebase to get full data
                                      final searchResults = await _searchService.searchSongs(song.title);

                                      // Try to find exact or partial match
                                      final titleLower = song.title.toLowerCase();
                                      Song? matchedSong =
                                          searchResults.where((s) => s.titleLowercase == titleLower).firstOrNull;

                                      if (matchedSong == null) {
                                        matchedSong =
                                            searchResults
                                                .where(
                                                  (s) =>
                                                      s.titleLowercase.contains(titleLower) ||
                                                      titleLower.contains(s.titleLowercase),
                                                )
                                                .firstOrNull;
                                      }

                                      if (matchedSong != null) {
                                        // Show modal with full Firebase data
                                        if (context.mounted) {
                                          IdentifiedSongWithPlaylistModal.show(
                                            context,
                                            song: matchedSong,
                                            confidence: song.confidence,
                                          );
                                        }
                                      } else {
                                        // Song not in Firebase database, show message
                                        _showSnackBar(
                                          'Song not found in database. Cannot add to playlist.',
                                          duration: 3,
                                        );
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
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
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
                                                          return Container(
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                begin: Alignment.topLeft,
                                                                end: Alignment.bottomRight,
                                                                colors: [
                                                                  AppColors.accentBlue.withOpacity(0.4),
                                                                  AppColors.accentBlue.withOpacity(0.2),
                                                                ],
                                                              ),
                                                            ),
                                                            child: Icon(
                                                              Icons.music_note,
                                                              color: Colors.white.withOpacity(0.7),
                                                              size: 30,
                                                            ),
                                                          );
                                                        },
                                                      )
                                                      : Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                            colors: [
                                                              AppColors.accentBlue.withOpacity(0.4),
                                                              AppColors.accentBlue.withOpacity(0.2),
                                                            ],
                                                          ),
                                                        ),
                                                        child: Icon(
                                                          Icons.music_note,
                                                          color: Colors.white.withOpacity(0.7),
                                                          size: 30,
                                                        ),
                                                      ),
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
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 12,
                                                      color: AppColors.accentBlue.withOpacity(0.7),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatDiscoveryTime(song.discoveredAt),
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
                          }),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
