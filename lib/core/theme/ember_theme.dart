import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ember_colors.dart';
import 'ember_tokens.dart';

abstract final class EmberTheme {
  static final _titleFont = GoogleFonts.bricolageGrotesqueTextTheme();
  static final _bodyFont = GoogleFonts.interTextTheme();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: EmberColors.brasaForte,
      onPrimary: Colors.white,
      secondary: EmberColors.sol,
      onSecondary: EmberColors.noite,
      surface: isLight ? EmberColors.creme : EmberColors.noiteSurface,
      onSurface: isLight ? EmberColors.noite : EmberColors.creme,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
    );

    final baseText = isLight
        ? _bodyFont.apply(
            bodyColor: EmberColors.noite,
            displayColor: EmberColors.noite,
          )
        : _bodyFont.apply(
            bodyColor: EmberColors.creme,
            displayColor: EmberColors.creme,
          );

    final titleText = isLight
        ? _titleFont.apply(
            bodyColor: EmberColors.noite,
            displayColor: EmberColors.noite,
          )
        : _titleFont.apply(
            bodyColor: EmberColors.creme,
            displayColor: EmberColors.creme,
          );

    final textTheme = baseText.copyWith(
      headlineLarge: titleText.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: titleText.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: titleText.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: titleText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: titleText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: isLight ? Colors.white : EmberColors.noiteCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight ? EmberColors.noite : const Color(0xFF4A4860),
            width: isLight ? 2.5 : 2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EmberColors.brasaForte,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.onSurface, width: 2),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : EmberColors.noiteCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: EmberColors.brasaForte, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      extensions: [
        isLight ? EmberTokens.light : EmberTokens.dark,
      ],
    );
  }
}
