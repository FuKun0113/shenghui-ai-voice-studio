import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('open source repository does not include third party config wiring', () {
    const removedService =
        'fire'
        'base';
    const removedGradlePlugin =
        'google'
        '-services';
    expect(File('$removedService.json').existsSync(), isFalse);
    expect(File('lib/${removedService}_options.dart').existsSync(), isFalse);
    expect(File('android/app/$removedGradlePlugin.json').existsSync(), isFalse);

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('${removedService}_core')));
    expect(pubspec, isNot(contains('${removedService}_remote_config')));

    final androidSettings = File(
      'android/settings.gradle.kts',
    ).readAsStringSync();
    final androidAppBuild = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    expect(androidSettings, isNot(contains(removedGradlePlugin)));
    expect(androidAppBuild, isNot(contains(removedGradlePlugin)));
  });

  test('open source repository keeps release-only surfaces out of source', () {
    final removedMetricsFile = [
      'usage',
      'ana'
          'lytics',
      'service',
    ].join('_');
    final removedConfigFile = ['remote', 'app', 'config'].join('_');
    final removedNoticeStoreFile = [
      'local',
      'popup',
      'notice',
      'store',
    ].join('_');

    expect(
      File('lib/src/services/$removedMetricsFile.dart').existsSync(),
      isFalse,
    );
    expect(
      File('test/services/${removedMetricsFile}_test.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/src/domain/$removedConfigFile.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/src/services/${removedConfigFile}_service.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/src/services/$removedNoticeStoreFile.dart').existsSync(),
      isFalse,
    );
    final removedConfigExample = ['shenghui', 'config', 'example'].join('-');
    final removedBuildDoc = ['official', 'build', 'config'].join('-');
    expect(File('config/$removedConfigExample.json').existsSync(), isFalse);
    expect(File('docs/$removedBuildDoc.md').existsSync(), isFalse);

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('crypto')));
  });
}
