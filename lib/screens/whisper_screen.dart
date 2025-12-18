import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vespera/colors.dart';

class WhisperScreen extends StatefulWidget {
  const WhisperScreen({super.key});

  @override
  State<WhisperScreen> createState() => _WhisperScreenState();
}

class _WhisperScreenState extends State<WhisperScreen> {
  final DraggableScrollableController _draggableController = DraggableScrollableController();

  // Use AudioRecorder from record v6
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _lastSavedPath;

  @override
  void dispose() {
    _draggableController.dispose();
    super.dispose();
  }

  Future<void> _startTenSecondRecording() async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to record audio.')),
        );
      }
      return;
    }

    // Choose a discoverable directory
    final String sep = Platform.pathSeparator;
    Directory baseDir;
    if (Platform.isAndroid) {
      // Try public Music directory
      final externalDirs = await getExternalStorageDirectories(type: StorageDirectory.music);
      baseDir =
          (externalDirs != null && externalDirs.isNotEmpty)
              ? externalDirs.first
              : await getApplicationDocumentsDirectory();
    } else {
      // On iOS, Documents is visible in the Files app under the app sandbox
      baseDir = await getApplicationDocumentsDirectory();
    }
    final recordingsDir = Directory('${baseDir.path}${sep}Vespera${sep}recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final outputPath = '${recordingsDir.path}${sep}whisper_$timestamp.m4a';

    try {
      setState(() => _isRecording = true);

      // Configure and start recording
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: outputPath,
      );

      await Future.delayed(const Duration(seconds: 10));

      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _lastSavedPath = path ?? outputPath;
      });

      if (mounted && _lastSavedPath != null) {
        print('Recording Saaved to: $_lastSavedPath');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved recording to: $_lastSavedPath')));
      }
    } catch (e) {
      setState(() => _isRecording = false);
      print('Recording Failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recording failed: $e')));
      }
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
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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
                        Image(
                          image: const AssetImage('assets/whisper4.png'),
                          height: 180,
                          width: 180,
                        ),
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
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Artist Name',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
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
