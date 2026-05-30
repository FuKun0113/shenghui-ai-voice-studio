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

    expect(config.enabledAdSlots, isEmpty);
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
}

Map<String, Object?> _decodeJsonObject(String raw) {
  return Map<String, Object?>.from(const JsonDecoder().convert(raw) as Map);
}
