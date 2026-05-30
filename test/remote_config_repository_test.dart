import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/domain/remote_app_config.dart';

void main() {
  test('versioned remote config file is valid app config', () {
    final file = File('config/shenghui-config.json');

    expect(file.existsSync(), isTrue);

    final config = RemoteAppConfig.fromJson(
      Map<String, Object?>.from(
        file.readAsStringSync().trim().isEmpty
            ? const <String, Object?>{}
            : _decodeJsonObject(file.readAsStringSync()),
      ),
    );

    expect(
      config.enabledAdSlots.map((slot) => slot.placement),
      containsAll([
        'settings_footer',
        'voice_service',
        'text_optimization_service',
      ]),
    );
    expect(config.popupNotice.id, isNotEmpty);
    expect(
      config.updatePolicy.latestVersion,
      matches(RegExp(r'^\d+\.\d+\.\d+$')),
    );
    expect(
      config.updatePolicy.minSupportedVersion,
      matches(RegExp(r'^\d+\.\d+\.\d+$')),
    );
  });

  test('github action publishes versioned remote config to r2', () {
    final workflow = File('.github/workflows/publish-remote-config.yml');

    expect(workflow.existsSync(), isTrue);

    final yaml = workflow.readAsStringSync();
    expect(yaml, contains('config/shenghui-config.json'));
    expect(yaml, contains('jq empty config/shenghui-config.json'));
    expect(yaml, contains('aws s3 cp'));
    expect(yaml, contains('R2_ACCESS_KEY_ID'));
    expect(yaml, contains('R2_SECRET_ACCESS_KEY'));
    expect(yaml, contains('R2_BUCKET'));
  });
}

Map<String, Object?> _decodeJsonObject(String raw) {
  return Map<String, Object?>.from(const JsonDecoder().convert(raw) as Map);
}
