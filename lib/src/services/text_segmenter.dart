class TextSegmenter {
  const TextSegmenter({this.maxChars = 500});

  final int maxChars;

  List<String> segment(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) return const <String>[];
    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n|\r\n\s*\r\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);
    final result = <String>[];
    for (final paragraph in paragraphs) {
      result.addAll(_splitParagraph(paragraph));
    }
    return result;
  }

  List<String> _splitParagraph(String paragraph) {
    if (paragraph.length <= maxChars) return <String>[paragraph];
    final result = <String>[];
    var remaining = paragraph.trim();
    while (remaining.length > maxChars) {
      final breakpoint = _findBreakpoint(remaining);
      final segment = remaining.substring(0, breakpoint).trim();
      if (segment.isNotEmpty) result.add(segment);
      remaining = remaining
          .substring(_skipBreakPunctuation(remaining, breakpoint))
          .trim();
    }
    if (remaining.isNotEmpty) result.add(remaining);
    return result;
  }

  int _findBreakpoint(String text) {
    final scanEnd = maxChars.clamp(1, text.length);
    for (var index = scanEnd - 1; index > 0; index--) {
      if (_isBreakPunctuation(text[index])) return index;
    }
    return scanEnd;
  }

  int _skipBreakPunctuation(String text, int index) {
    var next = index;
    while (next < text.length && _isBreakPunctuation(text[next])) {
      next++;
    }
    return next;
  }

  bool _isBreakPunctuation(String value) {
    return '，。！？；,.!?;'.contains(value);
  }
}
