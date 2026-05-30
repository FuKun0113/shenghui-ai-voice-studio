import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shenghui_ai_voice_studio/src/services/release_update_service.dart';

void main() {
  test('compares semantic versions without build suffixes', () {
    expect(compareVersionStrings('0.0.2', '0.0.1'), greaterThan(0));
    expect(compareVersionStrings('0.0.1', '0.0.1'), 0);
    expect(compareVersionStrings('0.0.1+9', '0.0.1'), 0);
    expect(compareVersionStrings('0.0.1', '0.0.2'), lessThan(0));
  });

  test('parses the latest GitHub release and marks updates correctly', () async {
    Uri? capturedUrl;
    final service = GitHubReleaseUpdateService(
      client: MockClient((request) async {
        capturedUrl = request.url;
        expect(request.headers['Accept'], 'application/vnd.github+json');
        expect(request.headers['User-Agent'], 'shenghui-ai-voice-studio');
        return http.Response(
          jsonEncode(<String, Object?>{
            'tag_name': 'v0.0.2',
            'html_url': 'https://github.com/FuKun0113/shenghui-ai-voice-studio/releases/tag/v0.0.2',
            'name': '声绘 0.0.2',
          }),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }),
      owner: 'FuKun0113',
      repo: 'shenghui-ai-voice-studio',
    );

    final result = await service.checkLatestRelease(currentVersion: '0.0.1');

    expect(
      capturedUrl.toString(),
      'https://api.github.com/repos/FuKun0113/shenghui-ai-voice-studio/releases/latest',
    );
    expect(result.currentVersion, '0.0.1');
    expect(result.latestRelease.tagName, 'v0.0.2');
    expect(result.latestRelease.version, '0.0.2');
    expect(result.latestRelease.htmlUrl, contains('/releases/tag/v0.0.2'));
    expect(result.hasUpdate, isTrue);
  });
}
