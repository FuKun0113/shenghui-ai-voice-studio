import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

abstract interface class AudioPlaybackController {
  ValueListenable<AudioPlaybackSnapshot> get playbackState;
  Future<void> playFile(String path);
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}

class AudioPlaybackSnapshot {
  const AudioPlaybackSnapshot({
    this.path,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration,
  });

  final String? path;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;

  double get progress {
    final total = duration?.inMilliseconds ?? 0;
    if (path == null || total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0, 1).toDouble();
  }

  bool isPlayingPath(String audioPath) => path == audioPath && isPlaying;

  AudioPlaybackSnapshot copyWith({
    String? path,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool clearPath = false,
    bool clearDuration = false,
  }) {
    return AudioPlaybackSnapshot(
      path: clearPath ? null : path ?? this.path,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: clearDuration ? null : duration ?? this.duration,
    );
  }
}

class AudioEngineState {
  const AudioEngineState({required this.playing, this.completed = false});

  final bool playing;
  final bool completed;
}

abstract interface class AudioPlayerAdapter {
  Stream<AudioEngineState> get stateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Future<void> setAsset(String path);
  Future<void> setFilePath(String path);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioPlayerAdapter implements AudioPlayerAdapter {
  JustAudioPlayerAdapter([AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<AudioEngineState> get stateStream => _player.playerStateStream.map(
    (state) => AudioEngineState(
      playing: state.playing,
      completed: state.processingState == ProcessingState.completed,
    ),
  );

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Future<void> setAsset(String path) async {
    await _player.setAsset(path);
  }

  @override
  Future<void> setFilePath(String path) async {
    await _player.setFilePath(path);
  }

  @override
  Future<void> play() {
    return _player.play();
  }

  @override
  Future<void> pause() {
    return _player.pause();
  }

  @override
  Future<void> stop() {
    return _player.stop();
  }

  @override
  Future<void> dispose() {
    return _player.dispose();
  }
}

class AudioPlaybackService implements AudioPlaybackController {
  AudioPlaybackService({AudioPlayerAdapter? player})
    : _player = player ?? JustAudioPlayerAdapter() {
    _stateSubscription = _player.stateStream.listen(_handleEngineState);
    _positionSubscription = _player.positionStream.listen(_handlePosition);
    _durationSubscription = _player.durationStream.listen(_handleDuration);
  }

  static final AudioPlaybackService instance = AudioPlaybackService();

  final AudioPlayerAdapter _player;
  final ValueNotifier<AudioPlaybackSnapshot> _playbackState =
      ValueNotifier<AudioPlaybackSnapshot>(const AudioPlaybackSnapshot());
  late final StreamSubscription<AudioEngineState> _stateSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;

  @override
  ValueListenable<AudioPlaybackSnapshot> get playbackState => _playbackState;

  @override
  Future<void> playFile(String path) async {
    await _player.stop();
    _playbackState.value = AudioPlaybackSnapshot(path: path);
    if (path.startsWith('assets/')) {
      await _player.setAsset(path);
    } else {
      await _player.setFilePath(path);
    }
    await _player.play();
    _playbackState.value = _playbackState.value.copyWith(
      path: path,
      isPlaying: true,
      position: Duration.zero,
    );
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _playbackState.value = _playbackState.value.copyWith(isPlaying: false);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _playbackState.value = const AudioPlaybackSnapshot();
  }

  @override
  Future<void> dispose() async {
    await _stateSubscription.cancel();
    await _positionSubscription.cancel();
    await _durationSubscription.cancel();
    _playbackState.dispose();
    await _player.dispose();
  }

  void _handleEngineState(AudioEngineState state) {
    final current = _playbackState.value;
    if (state.completed) {
      _playbackState.value = current.copyWith(
        isPlaying: false,
        position: current.duration ?? current.position,
        clearPath: true,
        clearDuration: true,
      );
      return;
    }
    _playbackState.value = current.copyWith(isPlaying: state.playing);
  }

  void _handlePosition(Duration position) {
    final current = _playbackState.value;
    if (current.path == null) return;
    final duration = current.duration;
    final normalized = duration != null && position > duration
        ? duration
        : position;
    _playbackState.value = current.copyWith(position: normalized);
  }

  void _handleDuration(Duration? duration) {
    final current = _playbackState.value;
    _playbackState.value = current.copyWith(
      duration: duration,
      clearDuration: duration == null,
    );
  }
}
