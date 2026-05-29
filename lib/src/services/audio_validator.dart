import 'dart:io';

import '../domain/audio_format.dart';

class UnsupportedAudioFormatException implements Exception {
  const UnsupportedAudioFormatException(this.path);

  final String path;

  @override
  String toString() => 'Unsupported audio format: $path';
}

class AudioValidator {
  static const int maxReferenceFileBytes = 5 * 1024 * 1024;
  static const int maxBase64Bytes = 10 * 1024 * 1024;

  static AudioFormat detectFormat(String path) {
    return AudioFormat.fromPath(path);
  }

  static String requireSupported(String path) {
    final format = detectFormat(path);
    if (format == AudioFormat.unsupported) {
      throw UnsupportedAudioFormatException(path);
    }
    return path;
  }

  static Future<AudioValidationResult> validateReferenceFile(
    String path,
  ) async {
    final file = File(path);
    if (!await file.exists()) {
      return const AudioValidationResult.invalid('文件不存在，请重新选择音频');
    }
    final format = detectFormat(path);
    if (format == AudioFormat.unsupported) {
      return const AudioValidationResult.invalid('仅支持 mp3 或 wav 音频');
    }
    final fileBytes = await file.length();
    if (fileBytes > maxReferenceFileBytes) {
      return const AudioValidationResult.invalid('参考音频需小于 5 MB');
    }
    final estimatedBase64Bytes = ((fileBytes + 2) ~/ 3) * 4;
    if (estimatedBase64Bytes > maxBase64Bytes) {
      return const AudioValidationResult.invalid('参考音频超过 10 MB Base64 限制');
    }
    return AudioValidationResult.valid(path);
  }
}

class AudioValidationResult {
  const AudioValidationResult.valid(this.path)
    : isValid = true,
      message = '音频可用';

  const AudioValidationResult.invalid(this.message)
    : isValid = false,
      path = null;

  final bool isValid;
  final String message;
  final String? path;
}
