import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HydroTheme {
  static ThemeData light(Color accent) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      primary: accent,
      secondary: const Color(0xFF1FB6FF),
      tertiary: const Color(0xFF00C2A8),
      surface: const Color(0xFFF7FAFC),
      surfaceContainerHighest: const Color(0xFFEDF2F7),
    );
    return _base(scheme);
  }

  static ThemeData dark(Color accent) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      primary: accent,
      secondary: const Color(0xFF5CCBFF),
      tertiary: const Color(0xFF39E5D3),
      surface: const Color(0xFF0D151C),
      surfaceContainerHighest: const Color(0xFF1A242D),
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      platform: TargetPlatform.iOS,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: scheme.brightness == Brightness.light
          ? const Color(0xFFF2F2F7) // iOS systemGroupedBackground light
          : const Color(0xFF1C1C1E), // iOS systemGroupedBackground dark
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.brightness == Brightness.light
            ? const Color(0xFFFFFFFF) // iOS systemBackground light
            : const Color(0xFF2C2C2E), // iOS secondarySystemGroupedBackground dark
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(56, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.light
            ? const Color(0x0A000000)
            : const Color(0x1AFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme),
    );
  }
}

