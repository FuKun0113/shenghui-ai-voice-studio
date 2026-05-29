import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/app/app_theme.dart';

void main() {
  test('light theme defines polished workspace tokens', () {
    final theme = AppTheme.light();

    expect(theme.inputDecorationTheme.filled, isTrue);
    final inputBorder = theme.inputDecorationTheme.border;
    expect(inputBorder, isA<OutlineInputBorder>());
    expect((inputBorder! as OutlineInputBorder).borderSide, BorderSide.none);
    expect(theme.navigationBarTheme.height, 72);
    expect(theme.navigationBarTheme.indicatorColor, theme.colorScheme.primary);
    expect(theme.cardTheme.elevation, 0);
    expect(
      theme.filledButtonTheme.style?.minimumSize?.resolve({}),
      const Size.fromHeight(52),
    );
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F8FB));
    expect(theme.colorScheme.secondary, const Color(0xFF5067F2));
    expect(theme.colorScheme.tertiary, const Color(0xFFFF7A59));
  });
}
