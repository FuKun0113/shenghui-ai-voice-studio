import 'package:flutter_test/flutter_test.dart';
import 'package:shenghui_ai_voice_studio/src/services/release_update_service.dart';

void main() {
  test('compares semantic versions without build suffixes', () {
    expect(compareVersionStrings('0.0.2', '0.0.1'), greaterThan(0));
    expect(compareVersionStrings('0.0.1', '0.0.1'), 0);
    expect(compareVersionStrings('0.0.1+9', '0.0.1'), 0);
    expect(compareVersionStrings('0.0.1', '0.0.2'), lessThan(0));
  });

  test('normalizes release tags and partial versions', () {
    expect(normalizeVersionString('v0.0.2+15'), '0.0.2');
    expect(compareVersionStrings('v0.1', '0.0.9'), greaterThan(0));
    expect(compareVersionStrings('', '0.0.1'), lessThan(0));
  });
}
