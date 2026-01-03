import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

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
    // You can hook this to your playlist logic
    print('Skip to next');
  }

  @override
  Future<void> skipToPrevious() async {
    // You can hook this to your playlist logic
    print('Skip to previous');
  }
}
