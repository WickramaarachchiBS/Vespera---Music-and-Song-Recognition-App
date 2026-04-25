import 'package:flutter/material.dart';
import 'package:vespera/models/discovered_song.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/services/discovered_songs_service.dart';
import 'package:vespera/services/search_service.dart';
import 'package:vespera/services/whisper_services.dart';

enum ListeningState { idle, listening }

class WhisperProvider extends ChangeNotifier {
  final WhisperService _whisperService = WhisperService();
  final DiscoveredSongsService _discoveredSongsService = DiscoveredSongsService();
  final SearchService _searchService = SearchService();

  ListeningState _state = ListeningState.idle;
  List<DiscoveredSong> _discoveredSongs = [];
  String? _lastSavedPath;

  ListeningState get state => _state;
  List<DiscoveredSong> get discoveredSongs => _discoveredSongs;
  String? get lastSavedPath => _lastSavedPath;
  bool get isListening => _state == ListeningState.listening;

  WhisperProvider() {
    loadDiscoveredSongs();
  }

  Future<void> loadDiscoveredSongs() async {
    _discoveredSongs = await _discoveredSongsService.getDiscoveredSongs();
    notifyListeners();
  }

  Future<SongRecognitionResult> startRecordingAndIdentify() async {
    if (_state == ListeningState.listening) {
      return SongRecognitionResult.error('Already recording');
    }

    _state = ListeningState.listening;
    notifyListeners();

    final result = await _whisperService.startTenSecondRecording();

    _state = ListeningState.idle;
    notifyListeners();

    if (result.failure == WhisperRecordingFailure.permissionDenied) {
      return SongRecognitionResult.error('Microphone permission is required to record audio.');
    }

    if (result.failure == WhisperRecordingFailure.cancelled) {
      return SongRecognitionResult.cancelled();
    }

    if (result.failure == WhisperRecordingFailure.failed) {
      return SongRecognitionResult.error('Recording failed.');
    }

    _lastSavedPath = result.savedPath;

    if (_lastSavedPath == null) {
      return SongRecognitionResult.error('No audio recorded.');
    }

    // Identify the song
    final identify = await _whisperService.identifySongFromFile(filePath: _lastSavedPath!);

    if (!identify.ok) {
      return SongRecognitionResult.error(identify.error ?? 'Song identification failed.');
    }

    final title = (identify.title?.trim().isNotEmpty ?? false) ? identify.title!.trim() : 'Unknown title';
    final artist = (identify.artist?.trim().isNotEmpty ?? false) ? identify.artist!.trim() : 'Unknown artist';

    // Don't process songs with unknown title
    if (title.toLowerCase() == 'unknown title') {
      return SongRecognitionResult.error('Could not identify song. Please try again.');
    }

    // Search for the song in Firebase
    final matchedSong = await _searchSongInFirebase(title);

    if (matchedSong != null) {
      // Song found in Firebase - create discovered song
      final discoveredSong = DiscoveredSong(
        title: matchedSong.title,
        artist: matchedSong.artist,
        confidence: identify.confidence,
        imageUrl: matchedSong.imageUrl,
        audioUrl: matchedSong.audioUrl,
      );

      await _discoveredSongsService.addDiscoveredSong(discoveredSong);
      await loadDiscoveredSongs();

      return SongRecognitionResult.success(matchedSong, identify.confidence);
    } else {
      return SongRecognitionResult.notFoundInDatabase(title, artist);
    }
  }

  Future<Song?> _searchSongInFirebase(String title) async {
    final searchResults = await _searchService.searchSongs(title);

    debugPrint('🎵 Searching Firebase for: "$title"');
    debugPrint('📋 Search returned ${searchResults.length} results');
    for (final song in searchResults) {
      debugPrint('   - "${song.title}" by "${song.artist}"');
    }

    // Try exact title match first
    final titleLower = title.toLowerCase();
    final exactMatches = searchResults.where((song) => song.titleLowercase == titleLower).toList();

    if (exactMatches.isNotEmpty) {
      debugPrint('✅ Exact title match: "${exactMatches.first.title}"');
      return exactMatches.first;
    }

    // Try partial title match
    final partialMatches =
        searchResults.where((song) {
          return song.titleLowercase.contains(titleLower) || titleLower.contains(song.titleLowercase);
        }).toList();

    if (partialMatches.isNotEmpty) {
      debugPrint('✅ Partial title match: "${partialMatches.first.title}"');
      return partialMatches.first;
    }

    debugPrint('❌ No match found in database');
    return null;
  }

  Future<Song?> searchDiscoveredSongInFirebase(String title) async {
    return await _searchSongInFirebase(title);
  }

  Future<void> removeDiscoveredSong(int index) async {
    await _discoveredSongsService.removeDiscoveredSong(index);
    await loadDiscoveredSongs();
  }

  void cancelRecording() {
    _whisperService.cancelRecording();
  }

  @override
  void dispose() {
    _whisperService.dispose();
    super.dispose();
  }
}

class SongRecognitionResult {
  final Song? song;
  final double? confidence;
  final String? errorMessage;
  final bool isSuccess;
  final bool isNotInDatabase;

  const SongRecognitionResult._({
    this.song,
    this.confidence,
    this.errorMessage,
    required this.isSuccess,
    required this.isNotInDatabase,
  });

  factory SongRecognitionResult.success(Song song, double? confidence) {
    return SongRecognitionResult._(song: song, confidence: confidence, isSuccess: true, isNotInDatabase: false);
  }

  factory SongRecognitionResult.notFoundInDatabase(String title, String artist) {
    return SongRecognitionResult._(
      errorMessage: 'Song "$title" identified but not found in database.',
      isSuccess: false,
      isNotInDatabase: true,
    );
  }

  factory SongRecognitionResult.error(String message) {
    return SongRecognitionResult._(errorMessage: message, isSuccess: false, isNotInDatabase: false);
  }

  factory SongRecognitionResult.cancelled() {
    return const SongRecognitionResult._(isSuccess: false, isNotInDatabase: false);
  }

  bool get isCancelled => !isSuccess && errorMessage == null && !isNotInDatabase;
}
