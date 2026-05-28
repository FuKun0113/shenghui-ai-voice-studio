enum AudioFormat {
  mp3,
  wav,
  unsupported;

  static AudioFormat fromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp3')) return AudioFormat.mp3;
    if (lower.endsWith('.wav')) return AudioFormat.wav;
    return AudioFormat.unsupported;
  }
}
