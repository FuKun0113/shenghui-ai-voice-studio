import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class AppTheme {
  static ThemeData light() {
    final base = FlexThemeData.light(
      scheme: FlexScheme.tealM3,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 4,
      scaffoldBackground: const Color(0xFFF6F8FB),
      appBarStyle: FlexAppBarStyle.scaffoldBackground,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 8,
        cardRadius: 8,
        filledButtonRadius: 8,
        fabRadius: 8,
        bottomSheetRadius: 8,
        bottomSheetModalElevation: 8,
        inputDecoratorRadius: 8,
        inputDecoratorIsFilled: true,
        inputDecoratorFillColor: Color(0xFFFFFFFF),
        inputDecoratorBorderType: FlexInputBorderType.outline,
        navigationBarHeight: 72,
        navigationBarIndicatorRadius: 8,
        navigationBarIndicatorOpacity: 0.18,
      ),
      useMaterial3: true,
    );

    final scheme = base.colorScheme.copyWith(
      primary: const Color(0xFF007F73),
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFFD8F7F1),
      onPrimaryContainer: const Color(0xFF082F2A),
      secondary: const Color(0xFF5067F2),
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: const Color(0xFFE8EBFF),
      onSecondaryContainer: const Color(0xFF111B55),
      tertiary: const Color(0xFFFF7A59),
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFFFE3DA),
      onTertiaryContainer: const Color(0xFF5B1708),
      surface: const Color(0xFFFFFFFF),
      surfaceContainerHighest: const Color(0xFFEAF0F5),
      outlineVariant: const Color(0xFFD7DEE5),
    );
    final flatInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF6F8FB),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF172426),
        displayColor: const Color(0xFF172426),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: base.colorScheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHighest.withValues(
            alpha: 0.58,
          ),
          foregroundColor: scheme.onSurface,
          side: BorderSide.none,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        height: 72,
        elevation: 0,
        indicatorColor: scheme.primary,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
          );
        }),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: flatInputBorder,
        enabledBorder: flatInputBorder,
        focusedBorder: flatInputBorder,
        disabledBorder: flatInputBorder,
        errorBorder: flatInputBorder,
        focusedErrorBorder: flatInputBorder,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
