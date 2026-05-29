import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ReferenceAudioStore {
  ReferenceAudioStore({this.documentsDirectory});

  final Directory? documentsDirectory;

  Future<String> persistReferenceAudio(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('参考音频文件不存在，请重新选择或录制');
    }
    if (await isManagedReferenceAudio(sourcePath)) {
      return source.path;
    }
    final directory = await _referenceDirectory();
    final extension = p.extension(sourcePath).toLowerCase();
    final file = File(
      p.join(
        directory.path,
        'reference-${DateTime.now().microsecondsSinceEpoch}$extension',
      ),
    );
    await source.copy(file.path);
    return file.path;
  }

  Future<bool> isManagedReferenceAudio(String path) async {
    final directory = await _referenceDirectory();
    final normalizedDirectory = p.normalize(directory.path);
    final normalizedPath = p.normalize(path);
    return p.equals(normalizedDirectory, p.dirname(normalizedPath)) ||
        p.isWithin(normalizedDirectory, normalizedPath);
  }

  Future<Directory> _referenceDirectory() async {
    final documents =
        documentsDirectory ?? await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'reference-audio'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
