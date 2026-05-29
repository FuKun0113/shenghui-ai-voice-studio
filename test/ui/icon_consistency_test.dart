import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ui layer uses the unified Hugeicons icon set', () {
    final offenders = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains('material_symbols_icons'),
        )
        .map((file) => file.path)
        .toList();

    expect(
      offenders,
      isEmpty,
      reason: 'Do not mix Material Symbols with the Hugeicons visual system.',
    );
  });
}
