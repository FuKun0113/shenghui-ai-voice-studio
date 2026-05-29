import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../domain/generated_audio.dart';

abstract interface class AudioExportController {
  Future<String?> exportAudio(GeneratedAudio audio);
  Future<void> shareAudio(GeneratedAudio audio);
}

class AudioExportService implements AudioExportController {
  const AudioExportService();

  static const AudioExportService instance = AudioExportService();

  @override
  Future<String?> exportAudio(GeneratedAudio audio) async {
    final file = File(audio.audioPath);
    final bytes = await file.readAsBytes();
    final fileName = _fileNameFor(audio);
    final extension = p.extension(fileName).replaceFirst('.', '');
    return FilePicker.saveFile(
      dialogTitle: '保存生成语音',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: <String>[extension],
      bytes: bytes,
    );
  }

  @override
  Future<void> shareAudio(GeneratedAudio audio) async {
    final fileName = _fileNameFor(audio);
    await SharePlus.instance.share(
      ShareParams(
        title: '分享语音',
        subject: fileName,
        text: '来自声绘的生成语音：${audio.voiceName}',
        files: <XFile>[
          XFile(
            audio.audioPath,
            mimeType: lookupMimeType(audio.audioPath) ?? 'audio/wav',
            name: fileName,
          ),
        ],
        fileNameOverrides: <String>[fileName],
      ),
    );
  }

  String _fileNameFor(GeneratedAudio audio) {
    final extension = p.extension(audio.audioPath).isEmpty
        ? '.wav'
        : p.extension(audio.audioPath);
    final timestamp = audio.createdAt
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '-');
    final voiceName = audio.voiceName.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
    return 'voice-$voiceName-$timestamp$extension';
  }
}
