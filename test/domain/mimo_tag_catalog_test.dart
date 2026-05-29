import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/mimo_tag_catalog.dart';

void main() {
  test('advanced examples are sourced from MiMo v2.5 release docs', () {
    expect(
      mimoAdvancedExamples.map((example) => example.title),
      containsAll(<String>[
        '沧桑老前辈叙事',
        '灭世神祇导演模式',
        '星际航线标签编排',
        '发射倒计时文本理解',
        '纪录片旁白音色设计',
        '北方老先生音色设计',
      ]),
    );

    for (final example in mimoAdvancedExamples) {
      expect(example.sourceLabel, contains('MiMo V2.5'));
      expect(example.audioPath, startsWith('assets/audio/examples/'));
      expect(File(example.audioPath).existsSync(), isTrue);
    }
  });
}
