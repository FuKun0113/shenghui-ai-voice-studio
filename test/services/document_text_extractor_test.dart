import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/services/document_text_extractor.dart';

void main() {
  test('extracts UTF-8 text files', () async {
    final directory = await Directory.systemTemp.createTemp('mimo-doc-test');
    final file = File('${directory.path}/script.txt');
    await file.writeAsString('第一段台词\n第二段台词');

    final text = await DocumentTextExtractor().extractTextFromPath(file.path);

    expect(text, contains('第一段台词'));
    expect(text, contains('第二段台词'));
  });
}
