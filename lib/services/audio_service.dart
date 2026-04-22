import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vespera/models/song.dart';
import 'package:vespera/services/audio_handler.dart';

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  AudioService._internal() {
    // Keep state in sync even before the handler is attached.
    _bindToPlayer(_audioPlayer);
  }

  MyAudioHandler? _audioHandler;
  
  void initializeHandler(MyAudioHandler handler) {
    _audioHandler = handler;
    _bindToPlayer(handler.player);
  }

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

  bool get hasValidNetworkImage {
    final raw = _currentImageUrl;
    if (raw == null || raw.trim().isEmpty) return false;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  String? get currentAudioUrl => _currentAudioUrl;

  bool get isPlaying => _isPlaying;

  Duration get duration => _duration;

  Duration get position => _position;

  bool get hasCurrentSong => _currentAudioUrl != null;

  List<Song> _currentSongs = const [];
  int _currentIndex = 0;
  bool _playlistMode = false;
  bool _isRepeat = false;
  String? _playSource;
  String? _activeSessionId;
  DateTime? _activeSessionStartedAt;
  bool _activeSessionFinalized = true;
  StreamSubscription<ProcessingState>? _processingStateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;

  bool get isRepeat => _isRepeat;
  String? get playSource => _playSource;

  void _bindToPlayer(AudioPlayer player) {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();

    _durationSub = player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    _positionSub = player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _playerStateSub = player.playerStateStream.listen((state) {
      _isPlaying = state.playing;

      if (state.processingState == ProcessingState.completed && !_activeSessionFinalized) {
        unawaited(_finalizeListeningSession(status: 'completed', completed: true));
      }

      notifyListeners();
    });
  }

  Future<void> toggleRepeat() async {
    _isRepeat = !_isRepeat;
    final player = _audioHandler?.player ?? _audioPlayer;
    await player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

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
    String? playSource,
  }) async {
    if (playSource != null) _playSource = playSource;

    try {
      if (!_activeSessionFinalized) {
        await _finalizeListeningSession(status: 'interrupted', completed: false);
      }

      // Update current song details
      _currentAudioUrl = audioUrl;
      _currentSongTitle = title;
      _currentArtist = artist;
      _currentImageUrl = imageUrl;
      _duration = Duration.zero;
      _position = Duration.zero;

      // Make UI react immediately (e.g. show mini player) before awaiting async loading.
      notifyListeners();

      // Increment play count in Firestore (fire-and-forget).
      _incrementPlayCount(audioUrl);
      unawaited(
        _startListeningSession(
          audioUrl: audioUrl,
          title: title,
          artist: artist,
          imageUrl: imageUrl,
        ),
      );

      // Use audio handler if available (enables background playback + notifications)
      if (_audioHandler != null) {
        _bindToPlayer(_audioHandler!.player);
        await _audioHandler!.playFromUrl(
          audioUrl,
          title: title ?? 'Unknown',
          artist: artist ?? 'Unknown',
          artUri: imageUrl,
        );
      } else {
        // Fallback to direct player (no background support)
        _bindToPlayer(_audioPlayer);
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
      }
      
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');

      // If playback failed, reflect that in UI.
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Increment the playCount field of the song document whose audioUrl matches.
  void _incrementPlayCount(String audioUrl) {
    FirebaseFirestore.instance
        .collection('songs')
        .where('audioUrl', isEqualTo: audioUrl)
        .limit(1)
        .get()
        .then((snap) {
      if (snap.docs.isNotEmpty) {
        snap.docs.first.reference.update({
          'playCount': FieldValue.increment(1),
        });
      }
    }).catchError((e) {
      debugPrint('playCount increment failed: $e');
    });
  }

  Future<void> togglePlayPause() async {
    final player = _audioHandler?.player ?? _audioPlayer;
    if (_isPlaying) {
      await player.pause();
      _isPlaying = false;
    } else {
      await player.play();
      _isPlaying = true;
    }
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    final player = _audioHandler?.player ?? _audioPlayer;
    await player.seek(position);
  }

  @override
  void dispose() {
    if (!_activeSessionFinalized) {
      unawaited(_finalizeListeningSession(status: 'stopped', completed: false));
    }

    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _processingStateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startListeningSession({
    required String audioUrl,
    String? title,
    String? artist,
    String? imageUrl,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _activeSessionId = null;
      _activeSessionStartedAt = null;
      _activeSessionFinalized = true;
      return;
    }

    final sessionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('listeningSessions')
        .doc();

    final startedAt = DateTime.now();
    _activeSessionId = sessionRef.id;
    _activeSessionStartedAt = startedAt;
    _activeSessionFinalized = false;

    try {
      await sessionRef.set({
        'audioUrl': audioUrl,
        'title': title ?? 'Unknown',
        'artist': artist ?? 'Unknown',
        'imageUrl': imageUrl ?? '',
        'playSource': _playSource ?? 'Unknown',
        'startedAt': Timestamp.fromDate(startedAt),
        'listenedAt': Timestamp.fromDate(startedAt),
        'status': 'started',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('session start failed: $e');
      _activeSessionId = null;
      _activeSessionStartedAt = null;
      _activeSessionFinalized = true;
    }
  }

  Future<void> _finalizeListeningSession({
    required String status,
    required bool completed,
  }) async {
    if (_activeSessionFinalized) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final sessionId = _activeSessionId;
    if (userId == null || sessionId == null) {
      _activeSessionFinalized = true;
      return;
    }

    final endedAt = DateTime.now();
    final elapsedFromPosition = _position.inSeconds;
    final elapsedFromTime =
        _activeSessionStartedAt == null ? 0 : endedAt.difference(_activeSessionStartedAt!).inSeconds;
    final durationSeconds = elapsedFromPosition > 0 ? elapsedFromPosition : elapsedFromTime;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('listeningSessions')
          .doc(sessionId)
          .set({
        'endedAt': Timestamp.fromDate(endedAt),
        'durationSeconds': durationSeconds < 0 ? 0 : durationSeconds,
        'completed': completed,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('session finalize failed: $e');
    } finally {
      _activeSessionFinalized = true;
      _activeSessionId = null;
      _activeSessionStartedAt = null;
    }
  }

  Future<void> playSongs({required List<Song> playlist, required int startIndex, String? playlistName}) async {
    if (playlist.isEmpty || startIndex < 0 || startIndex >= playlist.length) return;

    _currentSongs = playlist;
    _currentIndex = startIndex;
    _playlistMode = true;
    if (playlistName != null) _playSource = playlistName;

    // Pass playlist context to audio handler
    if (_audioHandler != null) {
      _audioHandler!.setPlaylist(_currentSongs, startIndex);
    }

    final current = _currentSongs[_currentIndex];
    if (current.audioUrl.isEmpty) return;

    // Reuse your existing single-track play
    await playSong(
      audioUrl: current.audioUrl,
      title: current.title,
      artist: current.artist,
      imageUrl: current.imageUrl,
    );

    // Set up auto-advance on completion
    final player = _audioHandler?.player ?? _audioPlayer;
    _processingStateSub?.cancel();
    _processingStateSub = player.processingStateStream.listen((processingState) async {
      if (!_playlistMode) return;
      if (processingState == ProcessingState.completed) {
        await _playNextInPlaylist();
      }
    });
  }

  Future<void> playNextInPlaylist() async {
    await _playNextInPlaylist();
  }

  Future<void> _playNextInPlaylist() async {
    if (_currentSongs.isEmpty) return;
    if (_currentIndex + 1 >= _currentSongs.length) {
      _playlistMode = false; // reached end
      return;
    }
    _currentIndex += 1;
    final next = _currentSongs[_currentIndex];
    if (next.audioUrl.isEmpty) {
      // Skip empty; try next
      await _playNextInPlaylist();
      return;
    }
    await playSong(
      audioUrl: next.audioUrl,
      title: next.title,
      artist: next.artist,
      imageUrl: next.imageUrl,
    );
  }

  Future<void> playPreviousInPlaylist() async {
    if (_currentSongs.isEmpty) return;
    if (_currentIndex - 1 < 0) return;
    _currentIndex -= 1;
    final prev = _currentSongs[_currentIndex];
    if (prev.audioUrl.isEmpty) return;
    await playSong(
      audioUrl: prev.audioUrl,
      title: prev.title,
      artist: prev.artist,
      imageUrl: prev.imageUrl,
    );
  }

// Optionally add next/prev using _currentSongs and _currentIndex
}
