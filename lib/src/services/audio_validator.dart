import '../domain/audio_format.dart';

class UnsupportedAudioFormatException implements Exception {
  const UnsupportedAudioFormatException(this.path);

  final String path;

  @override
  String toString() => 'Unsupported audio format: $path';
}

class AudioValidator {
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
}
