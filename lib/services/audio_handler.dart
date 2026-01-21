import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vespera/models/song.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  List<Song> _playlist = [];
  int _currentIndex = 0;
  
  void setPlaylist(List<Song> songs, int startIndex) {
    _playlist = songs;
    _currentIndex = startIndex;
  }

  MyAudioHandler() {
    // Listen to player state and update notification
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ));
    });

    // Listen to current position
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      final oldMediaItem = mediaItem.value;
      if (oldMediaItem != null && duration != null) {
        mediaItem.add(oldMediaItem.copyWith(duration: duration));
      }
    });
  }

  AudioPlayer get player => _player;

  // Play from URL with metadata
  Future<void> playFromUrl(
    String url, {
    required String title,
    required String artist,
    String? artUri,
  }) async {
    try {
      // Update the media item shown in the notification
      mediaItem.add(MediaItem(
        id: url,
        album: '',
        title: title,
        artist: artist,
        artUri: artUri != null ? Uri.parse(artUri) : null,
      ));

      // Load and play the audio
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      print('Error playing from URL: $e');
      rethrow;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty || _currentIndex + 1 >= _playlist.length) return;
    _currentIndex++;
    final next = _playlist[_currentIndex];
    await playFromUrl(
      next.audioUrl,
      title: next.title,
      artist: next.artist,
      artUri: next.imageUrl.isNotEmpty ? next.imageUrl : null,
    );
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty || _currentIndex - 1 < 0) return;
    _currentIndex--;
    final prev = _playlist[_currentIndex];
    await playFromUrl(
      prev.audioUrl,
      title: prev.title,
      artist: prev.artist,
      artUri: prev.imageUrl.isNotEmpty ? prev.imageUrl : null,
    );
  }
}
