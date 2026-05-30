import 'dart:convert';

import 'package:http/http.dart' as http;

class ReleaseUpdateInfo {
  const ReleaseUpdateInfo({
    required this.tagName,
    required this.version,
    required this.htmlUrl,
    this.name,
  });

  final String tagName;
  final String version;
  final String htmlUrl;
  final String? name;
}

class ReleaseUpdateResult {
  const ReleaseUpdateResult({
    required this.currentVersion,
    required this.latestRelease,
  });

  final String currentVersion;
  final ReleaseUpdateInfo latestRelease;

  bool get hasUpdate =>
      compareVersionStrings(latestRelease.version, currentVersion) > 0;
}

abstract interface class ReleaseUpdateService {
  Future<ReleaseUpdateResult> checkLatestRelease({
    required String currentVersion,
  });
}

class GitHubReleaseUpdateService implements ReleaseUpdateService {
  GitHubReleaseUpdateService({
    http.Client? client,
    this.owner = 'FuKun0113',
    this.repo = 'shenghui-ai-voice-studio',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String owner;
  final String repo;

  Uri get _latestReleaseUri =>
      Uri.https('api.github.com', '/repos/$owner/$repo/releases/latest');

  @override
  Future<ReleaseUpdateResult> checkLatestRelease({
    required String currentVersion,
  }) async {
    final response = await _client.get(
      _latestReleaseUri,
      headers: <String, String>{
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'shenghui-ai-voice-studio',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('获取最新版本失败：${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw StateError('最新版本返回格式不正确');
    }
    final latestRelease = _parseRelease(decoded);
    return ReleaseUpdateResult(
      currentVersion: normalizeVersionString(currentVersion),
      latestRelease: latestRelease,
    );
  }

  ReleaseUpdateInfo _parseRelease(Map<String, Object?> decoded) {
    final tagName = (decoded['tag_name'] as String? ?? '').trim();
    final htmlUrl = (decoded['html_url'] as String? ?? '').trim();
    if (tagName.isEmpty || htmlUrl.isEmpty) {
      throw StateError('最新版本信息不完整');
    }
    final version = normalizeVersionString(tagName);
    return ReleaseUpdateInfo(
      tagName: tagName,
      version: version,
      htmlUrl: htmlUrl,
      name: (decoded['name'] as String?)?.trim(),
    );
  }
}

String normalizeVersionString(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '0.0.0';
  final withoutPrefix = trimmed.startsWith('v') ? trimmed.substring(1) : trimmed;
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
