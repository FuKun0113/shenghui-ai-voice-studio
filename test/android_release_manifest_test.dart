import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release Android manifest declares internet permission', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.INTERNET'));
  });

  test('Android release config uses production identity and API 35 target', () {
    final buildGradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final mainActivity = File(
      'android/app/src/main/kotlin/com/yunque/shenghui/MainActivity.kt',
    );

    expect(buildGradle, contains('namespace = "com.yunque.shenghui"'));
    expect(buildGradle, contains('compileSdk = 36'));
    expect(buildGradle, contains('applicationId = "com.yunque.shenghui"'));
    expect(buildGradle, contains('targetSdk = 35'));
    expect(manifest, contains('android:label="声绘"'));
    expect(mainActivity.existsSync(), isTrue);
    expect(
      mainActivity.readAsStringSync(),
      contains('package com.yunque.shenghui'),
    );
  });
}
