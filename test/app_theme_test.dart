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
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(theme.snackBarTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.bottomSheetTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.popupMenuTheme.shape, isA<RoundedRectangleBorder>());
  });

  test('light theme uses a consistent product typography scale', () {
    final textTheme = AppTheme.light().textTheme;

    expect(textTheme.titleLarge?.fontSize, 22);
    expect(textTheme.titleMedium?.fontSize, 18);
    expect(textTheme.titleSmall?.fontSize, 16);
    expect(textTheme.bodyLarge?.fontSize, 16);
    expect(textTheme.bodyMedium?.fontSize, 15);
    expect(textTheme.bodySmall?.fontSize, 13);
    expect(textTheme.labelLarge?.fontSize, 15);
    expect(textTheme.labelMedium?.fontSize, 13);
    expect(textTheme.labelSmall?.fontSize, 12);
  });

  test('app bar title stays below page-title scale', () {
    final titleStyle = AppTheme.light().appBarTheme.titleTextStyle;

    expect(titleStyle?.fontSize, 20);
    expect(titleStyle?.fontWeight, FontWeight.w800);
    expect(AppTheme.light().appBarTheme.leadingWidth, 44);
    expect(AppTheme.light().appBarTheme.titleSpacing, 4);
  });
}
