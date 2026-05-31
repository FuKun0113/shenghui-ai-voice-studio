String normalizeVersionString(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '0.0.0';
  final withoutPrefix = trimmed.startsWith('v')
      ? trimmed.substring(1)
      : trimmed;
  return withoutPrefix.split('+').first;
}

int compareVersionStrings(String left, String right) {
  final leftParts = _parseSemanticVersion(left);
  final rightParts = _parseSemanticVersion(right);
  for (var index = 0; index < 3; index += 1) {
    final comparison = leftParts[index].compareTo(rightParts[index]);
    if (comparison != 0) return comparison;
  }
  return 0;
}

List<int> _parseSemanticVersion(String value) {
  final clean = normalizeVersionString(value);
  final parts = clean.split('.');
  return List<int>.generate(3, (index) {
    if (index >= parts.length) return 0;
    return int.tryParse(parts[index].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  });
}
