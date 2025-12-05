import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vespera/models/song.dart';

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _currentSongTitle;
  String? _currentArtist;
  String? _currentImageUrl;
  String? _currentAudioUrl;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  String? get currentSongTitle => _currentSongTitle;
  String? get currentArtist => _currentArtist;
  String? get currentImageUrl => _currentImageUrl;
  String? get currentAudioUrl => _currentAudioUrl;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get hasCurrentSong => _currentAudioUrl != null;

  List<Song> _currentSongs = const [];
  int _currentIndex = 0;

  // Get current song as Song object
  Song? get currentSong {
    if (_currentSongs.isNotEmpty && _currentIndex >= 0 && _currentIndex < _currentSongs.length) {
      return _currentSongs[_currentIndex];
    }
    // If no playlist context, create a minimal Song from current data
    if (_currentAudioUrl != null && _currentSongTitle != null) {
      return Song(
        id: _currentAudioUrl!.hashCode.toString(),
        title: _currentSongTitle ?? 'Unknown',
        artist: _currentArtist ?? 'Unknown',
        album: '',
        duration: '0:00',
        imageUrl: _currentImageUrl ?? '',
        audioUrl: _currentAudioUrl!,
        titleLowercase: (_currentSongTitle ?? '').toLowerCase(),
        artistLowercase: (_currentArtist ?? '').toLowerCase(),
      );
    }
    return null;
  }

  Future<void> playSong({
    required String audioUrl,
    String? title,
    String? artist,
    String? imageUrl,
  }) async {
    try {
      // Update current song details
      _currentAudioUrl = audioUrl;
      _currentSongTitle = title;
      _currentArtist = artist;
      _currentImageUrl = imageUrl;

      // Load audio from URL
      await _audioPlayer.setUrl(audioUrl);

      // Listen to duration changes
      _audioPlayer.durationStream.listen((duration) {
        _duration = duration ?? Duration.zero;
        notifyListeners();
      });

      // Listen to position changes
      _audioPlayer.positionStream.listen((position) {
        _position = position;
        notifyListeners();
      });

      // Listen to player state
      _audioPlayer.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        notifyListeners();
      });

      // Start playing immediately
      await _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
      print('Paused');
    } else {
      print('Playing');
      await _audioPlayer.play();
      _isPlaying = true;
      
    }
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playSongs({
    required List<Song> playlist,
    required int startIndex,
  }) async {
    if (playlist.isEmpty || startIndex < 0 || startIndex >= playlist.length) return;

    _currentSongs = playlist;
    _currentIndex = startIndex;

    final current = _currentSongs[_currentIndex];
    if (current.audioUrl.isEmpty) return;

    // Reuse your existing single-track play
    await playSong(
      audioUrl: current.audioUrl,
      title: current.title,
      artist: current.artist,
      imageUrl: current.imageUrl,
    );
  }

  // Optionally add next/prev using _currentSongs and _currentIndex
}
