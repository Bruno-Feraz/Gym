import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    final scheme = ColorScheme.dark(
      surface: AppTokens.surface,
      primary: AppTokens.accent,
      onPrimary: AppTokens.bg,
      secondary: AppTokens.textMuted,
      onSecondary: AppTokens.text,
      error: AppTokens.danger,
      onError: AppTokens.text,
      onSurface: AppTokens.text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppTokens.bg,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.bg,
        foregroundColor: AppTokens.text,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppTokens.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppTokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppTokens.textMuted,
        textColor: AppTokens.text,
      ),
      dividerTheme: const DividerThemeData(
        color: AppTokens.surfaceHigh,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppTokens.accent,
        foregroundColor: AppTokens.bg,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppTokens.bg,
        indicatorColor: AppTokens.surfaceHigh,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTokens.text : AppTokens.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppTokens.text : AppTokens.textMuted,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        hintStyle: const TextStyle(color: AppTokens.textMuted),
        labelStyle: const TextStyle(color: AppTokens.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          borderSide: const BorderSide(color: AppTokens.accent, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTokens.surfaceHigh,
        contentTextStyle: const TextStyle(color: AppTokens.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppTokens.text,
        displayColor: AppTokens.text,
      ),
    );
  }
}
