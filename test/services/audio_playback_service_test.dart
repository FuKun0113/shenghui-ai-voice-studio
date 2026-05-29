import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/audio_playback_service.dart';

void main() {
  test('stops current audio before playing another path', () async {
    final player = FakeAudioPlayerAdapter();
    final service = AudioPlaybackService(player: player);

    await service.playFile('assets/audio/previews/mimo-default.wav');
    await service.playFile('/tmp/generated.wav');

    expect(player.calls, <String>[
      'stop',
      'setAsset:assets/audio/previews/mimo-default.wav',
      'play',
      'stop',
      'setFilePath:/tmp/generated.wav',
      'play',
    ]);
  });

  test('pauses the current audio without changing source', () async {
    final player = FakeAudioPlayerAdapter();
    final service = AudioPlaybackService(player: player);

    await service.playFile('/tmp/generated.wav');
    await service.pause();

    expect(player.calls, <String>[
      'stop',
      'setFilePath:/tmp/generated.wav',
      'play',
      'pause',
    ]);
  });

  test('publishes completed playback state when audio finishes', () async {
    final player = FakeAudioPlayerAdapter();
    final service = AudioPlaybackService(player: player);

    await service.playFile('/tmp/generated.wav');

    expect(service.playbackState.value.path, '/tmp/generated.wav');
    expect(service.playbackState.value.isPlaying, isTrue);

    player.emitDuration(const Duration(seconds: 2));
    player.emitPosition(const Duration(seconds: 2));
    player.emitState(const AudioEngineState(playing: false, completed: true));
    await pumpEventQueue();

    expect(service.playbackState.value.path, isNull);
    expect(service.playbackState.value.isPlaying, isFalse);
    expect(service.playbackState.value.progress, 0);
  });
}

class FakeAudioPlayerAdapter implements AudioPlayerAdapter {
  final List<String> calls = <String>[];
  final StreamController<AudioEngineState> _stateController =
      StreamController<AudioEngineState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();

  @override
  Stream<AudioEngineState> get stateStream => _stateController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Future<void> setAsset(String path) async {
    calls.add('setAsset:$path');
  }

  @override
  Future<void> setFilePath(String path) async {
    calls.add('setFilePath:$path');
  }

  @override
  Future<void> play() async {
    calls.add('play');
  }

  void emitState(AudioEngineState state) {
    _stateController.add(state);
  }

  void emitPosition(Duration position) {
    _positionController.add(position);
  }

  void emitDuration(Duration? duration) {
    _durationController.add(duration);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
  }
}
