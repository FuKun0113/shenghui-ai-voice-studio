import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WaveformCacheStore {
  Future<File> cacheFileForAudio(String audioPath) async {
    final directory = await getApplicationSupportDirectory();
    final cacheDir = Directory(p.join(directory.path, 'waveforms'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final safeName = base64Url.encode(utf8.encode(audioPath));
    return File(p.join(cacheDir.path, '$safeName.wave'));
  }
}
