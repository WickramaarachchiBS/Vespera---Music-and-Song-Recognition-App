import 'package:flutter/material.dart';
import 'package:vespera/colors.dart';
import 'package:vespera/services/whisper_services.dart';

class WhisperScreen extends StatefulWidget {
  const WhisperScreen({super.key});

  @override
  State<WhisperScreen> createState() => _WhisperScreenState();
}

class _WhisperScreenState extends State<WhisperScreen> {
  final DraggableScrollableController _draggableController = DraggableScrollableController();

  final WhisperService _whisperService = WhisperService();
  bool _isRecording = false;
  String? _lastSavedPath;

  // TODO: Replace with your actual Python server endpoint.
  // Example: http://10.0.2.2:8000/identify for Android emulator talking to your PC.
  final Uri _identifyEndpoint = Uri.parse('http://10.0.2.2:8000/identify');

  @override
  void dispose() {
    _draggableController.dispose();
    _whisperService.dispose();
    super.dispose();
  }

  Future<void> _startTenSecondRecording() async {
    if (_isRecording) return;

    setState(() => _isRecording = true);
    final result = await _whisperService.startTenSecondRecording();
    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _lastSavedPath = result.savedPath;
    });

    if (result.failure == WhisperRecordingFailure.permissionDenied) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Microphone permission is required to record audio.')));
      return;
    }

    if (result.failure == WhisperRecordingFailure.failed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording failed.')));
      return;
    }

    if (_lastSavedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved recording to: $_lastSavedPath')));

      final identify = await _whisperService.identifySongFromFile(
        filePath: _lastSavedPath!,
        endpoint: _identifyEndpoint,
        fileField: 'file',
      );
      if (!mounted) return;

      if (!identify.ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(identify.error ?? 'Song identification failed.')));
        return;
      }

      final title = (identify.title?.trim().isNotEmpty ?? false) ? identify.title!.trim() : 'Unknown title';
      final artist = (identify.artist?.trim().isNotEmpty ?? false) ? identify.artist!.trim() : 'Unknown artist';
      final conf = identify.confidence;
      final confText = conf == null ? '' : ' (${(conf * 100).toStringAsFixed(0)}%)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Identified: $title — $artist$confText')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRecording ? 'Listening… 10s' : 'Tap to Listen',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),
              Container(
                margin: const EdgeInsets.only(bottom: 100),
                child: Center(
                  child: GestureDetector(
                    onTap: _startTenSecondRecording,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image(image: const AssetImage('assets/whisper4.png'), height: 180, width: 180),
                        if (_isRecording)
                          Container(
                            height: 180,
                            width: 180,
                            decoration: BoxDecoration(
                              // Use withValues to avoid deprecation
                              color: const Color(0xFF000000).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.95,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF607D8B).withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.3),
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
                          color: AppColors.textPrimary.withValues(alpha: 0.3),
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
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              const Spacer(),
                              Text(
                                '15 Tracks',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
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
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(
                                  'Song Title ${index + 1}',
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('Artist Name', style: TextStyle(color: AppColors.textSecondary)),
                                trailing: Icon(Icons.more_vert, color: AppColors.textSecondary),
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
          ),
        ],
      ),
    );
  }
}
