import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';

void main() {
  test('open source repository keeps only a disabled example config', () {
    final file = File('config/shenghui-config.example.json');

    expect(file.existsSync(), isTrue);

    final config = RemoteAppConfig.fromJson(
      Map<String, Object?>.from(
        file.readAsStringSync().trim().isEmpty
            ? const <String, Object?>{}
            : _decodeJsonObject(file.readAsStringSync()),
      ),
    );

    expect(config.popupNotice.enabled, isFalse);
    expect(
      config.updatePolicy.latestVersion,
      matches(RegExp(r'^\d+\.\d+\.\d+$')),
    );
    expect(
      config.updatePolicy.minSupportedVersion,
      matches(RegExp(r'^\d+\.\d+\.\d+$')),
    );
  });

  test('production remote config is not committed to the open source repo', () {
    expect(File('config/shenghui-config.json').existsSync(), isFalse);
  });

  test('public github action does not publish production remote config', () {
    final workflow = File('.github/workflows/publish-remote-config.yml');

    expect(workflow.existsSync(), isFalse);
  });

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

  test(
    'open source repository does not include optional operations sources',
    () {
      final metricsFile = [
        'usage',
        'ana'
            'lytics',
        'service',
      ].join('_');
      expect(File('lib/src/services/$metricsFile.dart').existsSync(), isFalse);
      expect(
        File('test/services/${metricsFile}_test.dart').existsSync(),
        isFalse,
      );

      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('crypto')));

      final exampleConfig = File(
        'config/shenghui-config.example.json',
      ).readAsStringSync();
      expect(
        exampleConfig,
        isNot(
          contains(
            'ad'
            '_slots',
          ),
        ),
      );
    },
  );
}

Map<String, Object?> _decodeJsonObject(String raw) {
  return Map<String, Object?>.from(const JsonDecoder().convert(raw) as Map);
}
