import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'audio_validator.dart';

abstract interface class AudioInputController {
  Future<String?> pickReferenceAudio();
  Future<String> startRecording();
  Future<String?> stopRecording();
  Future<void> dispose();
}

class AudioInputService implements AudioInputController {
  AudioInputService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<String?> pickReferenceAudio() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: <String>['mp3', 'wav'],
    );
    final path = file?.path;
    if (path == null) return null;
    return AudioValidator.requireSupported(path);
  }

  @override
  Future<String> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('请允许麦克风权限后再录音');
    }
    final directory = await getTemporaryDirectory();
    final filePath = p.join(
      directory.path,
      'voice-reference-${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: filePath,
    );
    return filePath;
  }

  @override
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    return AudioValidator.requireSupported(path);
  }

  @override
  Future<void> dispose() {
    return _recorder.dispose();
  }
}
