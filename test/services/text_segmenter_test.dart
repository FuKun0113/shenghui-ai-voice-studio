import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/services/text_segmenter.dart';

void main() {
  test('keeps short text as a single segment', () {
    final segments = TextSegmenter(maxChars: 20).segment('第一段文本');
    expect(segments, <String>['第一段文本']);
  });

  test('splits long text by paragraphs before character length', () {
    final text = '第一段内容\n\n第二段内容很长，需要生成';
    final segments = TextSegmenter(maxChars: 8).segment(text);
    expect(segments, <String>['第一段内容', '第二段内容很长', '需要生成']);
  });
}
