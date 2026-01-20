import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/services/whisper_services.dart';

enum ListeningState { idle, listening }

class WhisperScreen extends StatefulWidget {
  const WhisperScreen({super.key});

  @override
  State<WhisperScreen> createState() => _WhisperScreenState();
}

class _WhisperScreenState extends State<WhisperScreen> with TickerProviderStateMixin {
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  final WhisperService _whisperService = WhisperService();
  
  ListeningState _state = ListeningState.idle;
  String? _lastSavedPath;

  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  final Uri _identifyEndpoint = Uri.parse('http://192.168.1.80:8000/api/identify');

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for idle state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ripple animation for listening state
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Glow animation for listening state
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Scale animation for button press
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
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
      final conf = identify.confidence;
      final confText = conf == null ? '' : ' (${(conf * 100).toStringAsFixed(0)}%)';
      _showSnackBar('Identified: $title — $artist$confText', duration: 4);
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
                      color: AppColors.accentBlue.withOpacity(
                        _state == ListeningState.listening ? 0.4 : 0.2,
                      ),
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
                        colors: [
                          AppColors.accentBlue.withOpacity(0.8),
                          AppColors.accentBlue.withOpacity(0.4),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
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
            border: Border.all(
              color: AppColors.accentBlue.withOpacity(opacity),
              width: 2,
            ),
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
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          '15 Tracks',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: List.generate(15, (index) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accentBlue,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'Song Title ${index + 1}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Artist Name',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          trailing: Icon(
                            Icons.more_vert,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
