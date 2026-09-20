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
  SkipCallback? onStop;

  CustomAudioHandler(this._player) {
    // Broadcast player state changes to the notification
    _player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event));
    });

    // Listen for duration changes so the notification progress bar works.
    // When just_audio resolves the actual duration, we update the MediaItem
    // with it so Android can render the seek-bar correctly.
    _player.durationStream.listen((duration) {
      final currentItem = mediaItem.valueOrNull;
      if (duration != null && currentItem != null) {
        // Only update if duration actually changed
        if (currentItem.duration != duration) {
          mediaItem.add(currentItem.copyWith(duration: duration));
          
          // CRITICAL FIX: The Android lock screen progress bar won't start visually 
          // ticking if the duration arrives AFTER the song starts playing, unless 
          // we force a fresh PlaybackState to be broadcasted with the new duration context.
          playbackState.add(_transformEvent(_player.playbackEvent));
        }
      }
    });
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
  Future<void> stop() async {
    await _player.stop();
    onStop?.call();
    // Signal to audio_service that we are done, so the notification is removed.
    await super.stop();
  }

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

  @override
  Future<void> onTaskRemoved() async {
    // Stop playback unconditionally when app is swiped from recents
    await stop();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        // The stop/close button lets the user dismiss the notification
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.stop,
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
