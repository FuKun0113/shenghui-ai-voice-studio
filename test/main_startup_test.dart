import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/main.dart' as app;

void main() {
  test(
    'firebase startup initialization times out instead of blocking startup',
    () async {
      final neverCompletes = Completer<void>();

      final initialized = await app.initializeFirebaseForStartup(
        initialize: () => neverCompletes.future,
        timeout: const Duration(milliseconds: 1),
        logFailures: false,
      );

      expect(initialized, isFalse);
    },
  );

  test(
    'firebase startup initialization reports success when it completes',
    () async {
      final initialized = await app.initializeFirebaseForStartup(
        initialize: () async {},
        timeout: const Duration(milliseconds: 1),
      );

      expect(initialized, isTrue);
    },
  );
}
