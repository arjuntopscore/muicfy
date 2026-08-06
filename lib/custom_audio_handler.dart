import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// A callback interface so the handler can tell MusicProvider to skip.
typedef SkipCallback = void Function();

/// Custom AudioHandler that wraps the AudioPlayer and delegates
/// notification skip actions back to MusicProvider.
/// This replaces just_audio_background to give full control over
/// next/previous from the notification.
class CustomAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  SkipCallback? onSkipToNext;
  SkipCallback? onSkipToPrevious;

  CustomAudioHandler(this._player) {
    // Broadcast player state changes to the notification
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  /// Update the current media item shown in the notification
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    onSkipToNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipToPrevious?.call();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
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
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
