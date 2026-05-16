import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/components/discovered_songs_list.dart';
import 'package:vespera/components/identified_song_with_playlist_modal.dart';
import 'package:vespera/providers/whisper_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class WhisperScreen extends StatefulWidget {
  const WhisperScreen({super.key});

  @override
  State<WhisperScreen> createState() => _WhisperScreenState();
}

class _WhisperScreenState extends State<WhisperScreen> with TickerProviderStateMixin {
  final DraggableScrollableController _draggableController = DraggableScrollableController();

  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _glowController;
  late AnimationController _textFadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this)
      ..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _rippleController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _glowController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    _textFadeController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat(reverse: true);
    _textFadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _textFadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _draggableController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    _glowController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  Future<void> _handleRecording() async {
    final provider = Provider.of<WhisperProvider>(context, listen: false);

    if (provider.isListening) {
      provider.cancelRecording();
      return;
    }

    _rippleController.repeat();
    _glowController.repeat(reverse: true);

    final result = await provider.startRecordingAndIdentify();

    if (!mounted) return;

    _rippleController.stop();
    _rippleController.reset();
    _glowController.stop();
    _glowController.reset();

    if (result.isCancelled) return;

    if (result.isSuccess && result.song != null) {
      IdentifiedSongWithPlaylistModal.show(
        context,
        song: result.song!,
        matchCount: result.matchCount,
        queriedPeakCount: result.queriedPeakCount,
      );
    }
    // Errors displayed inline via statusMessage in _buildStatusText()
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
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildTitle(),
                  const Spacer(),
                  _buildCenterButton(),
                  const SizedBox(height: 30),
                  _buildStatusText(),
                  const Spacer(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _buildDraggableSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Discover what\'s playing',
      style: GoogleFonts.poppins(
        color: Colors.white.withOpacity(0.9),
        fontSize: 20,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCenterButton() {
    return Consumer<WhisperProvider>(
      builder: (context, provider, child) {
        final isListening = provider.state == ListeningState.listening;

        return SizedBox(
          height: 400,
          width: 400,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isListening) ...[
                _buildRippleWave(delay: 0.0, maxSize: 280),
                _buildRippleWave(delay: 0.33, maxSize: 320),
                _buildRippleWave(delay: 0.66, maxSize: 360),
              ],
              _buildGlowCircle(isListening),
              _buildMainButton(isListening),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowCircle(bool isListening) {
    return AnimatedBuilder(
      animation: isListening ? _glowController : _pulseController,
      builder: (context, child) {
        return Container(
          height: 220,
          width: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBlue.withOpacity(isListening ? 0.4 : 0.2),
                blurRadius: isListening ? 40 : 30,
                spreadRadius: isListening ? 10 : 5,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainButton(bool isListening) {
    return GestureDetector(
      onTap: _handleRecording,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: !isListening ? _pulseAnimation.value : 1.0,
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
                child: Icon(isListening ? Icons.graphic_eq : Icons.music_note, size: 80, color: Colors.white),
              ),
            ),
          );
        },
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
    return Consumer<WhisperProvider>(
      builder: (context, provider, child) {
        final isListening = provider.state == ListeningState.listening;
        final isProcessing = provider.state == ListeningState.processing;
        final statusMessage = provider.statusMessage;

        String displayText;
        Color textColor = Colors.white.withOpacity(0.8);

        if (isListening) {
          displayText = 'Listening...';
        } else if (isProcessing) {
          displayText = 'Processing...';
          textColor = Colors.white.withOpacity(0.7);
        } else if (statusMessage != null) {
          // Show minimal inline feedback; full error in terminal via debugPrint
          displayText = _getMinimalStatusText(statusMessage);
          textColor = Colors.orange.withOpacity(0.8); // Warning color for errors/no matches
        } else {
          displayText = 'Tap to identify music';
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: AnimatedBuilder(
            key: ValueKey(displayText),
            animation: _textFadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _textFadeAnimation.value,
                child: child,
              );
            },
            child: Text(
              displayText,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  /// Minimal snackbar - just logs to terminal, no UI popup.
  void _showSnackBar(String message, {int duration = 2}) {
    debugPrint('🎵 WhisperScreen: $message');
  }

  /// Converts verbose status messages to minimal inline feedback.
  String _getMinimalStatusText(String statusMessage) {
    final lower = statusMessage.toLowerCase();
    
    if (lower.contains('not found')) return 'Not found. Try again';
    if (lower.contains('no matches')) return 'No match. Try another song';
    if (lower.contains('too short')) return 'Audio clip too short';
    if (lower.contains('timeout')) return 'Request timeout. Try again';
    if (lower.contains('permission')) return 'Permission denied. Allow microphone access';
    if (lower.contains('network') || lower.contains('connection')) return 'Network error. Check your connection';
    if (lower.contains('failed')) return 'Failed. Try again';
    
    return 'Try again';
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
              SliverToBoxAdapter(child: _buildDragHandle()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Consumer<WhisperProvider>(
                    builder: (context, provider, child) {
                      return Column(
                        children: [
                          _buildHeader(provider.discoveredSongs.length),
                          const SizedBox(height: 20),
                          DiscoveredSongsList(
                            songs: provider.discoveredSongs,
                            onShowSnackBar: (message) => _showSnackBar(message, duration: 2),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      children: [
        Text(
          'Discovered Songs',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          '$count Tracks',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
