import 'package:flutter/material.dart';

/// Design Tokens based on UI_GUIDELINES.md
/// All colors, spacing, typography must use these tokens
class DesignTokens {
  // ============ Colors ============

  // Backgrounds
  static const Color bg = Color(0xFFFFFFFF);
  static const Color bgSubtle = Color(0xFFFAFAFA);

  // Borders
  static const Color border = Color(0xFFE5E7EB);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Brand & Status
  static const Color brand = Color(0xFF0EA5E9);
  static const Color accent = Color(0xFF10B981);
  static const Color warn = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color focusRing = Color(0xFF93C5FD);

  // Text on colored backgrounds (inverse)
  static const Color textOnInverse = Color(0xFFFFFFFF);

  // Overlay & Scrim
  static const Color overlayScrim = Color(0x4D000000); // 30% black for modals/overlays

  // ============ Typography ============

  static const double fs2xl = 24.0;  // 1.5rem
  static const double fsXl = 20.0;   // 1.25rem
  static const double fsLg = 18.0;   // 1.125rem
  static const double fsMd = 16.0;   // 1rem
  static const double fsSm = 14.0;   // 0.875rem
  static const double fsXs = 12.0;   // 0.75rem

  // ============ Spacing (8pt grid) ============

  static const double sp0 = 0;
  static const double sp1 = 4.0;
  static const double sp2 = 8.0;
  static const double sp3 = 12.0;
  static const double sp4 = 16.0;
  static const double sp5 = 20.0;
  static const double sp6 = 24.0;
  static const double sp8 = 32.0;
  static const double sp10 = 40.0;
  static const double sp12 = 48.0;

  // ============ Border Radius ============

  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 16.0;

  // ============ Shadows ============

  static final BoxShadow shadowSm = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 2,
    offset: const Offset(0, 1),
  );

  static final BoxShadow shadowMd = BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  static final BoxShadow shadowLg = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 30,
    offset: const Offset(0, 10),
  );

  // ============ Animation Duration ============

  static const Duration durFast = Duration(milliseconds: 120);
  static const Duration durBase = Duration(milliseconds: 180);
  static const Duration durSlow = Duration(milliseconds: 240);

  // ============ Animation Curves ============

  static const Curve easeStandard = Curves.easeOut;

  // ============ Typography Stack ============
  // [UI_GUIDELINES.md] System font stack with Noto Sans TC
  static const List<String> fontFamilyStack = [
    'ui-sans-serif',
    'system-ui',
    '-apple-system',
    'Noto Sans TC',
    'Segoe UI',
    'Roboto',
    'Arial',
    'Apple Color Emoji',
    'Segoe UI Emoji',
  ];
}

/// Theme Data factory using Design Tokens
class ClearBoxTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: DesignTokens.bg,
      fontFamily: 'Noto Sans TC', // [UI_GUIDELINES.md] Primary font family

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: DesignTokens.brand,
        secondary: DesignTokens.accent,
        error: DesignTokens.danger,
        surface: DesignTokens.bg,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: DesignTokens.textPrimary,
      ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: DesignTokens.fs2xl,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
          height: 1.25,
        ),
        displayMedium: TextStyle(
          fontSize: DesignTokens.fsXl,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          fontSize: DesignTokens.fsMd,
          color: DesignTokens.textPrimary,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: DesignTokens.fsSm,
          color: DesignTokens.textSecondary,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: DesignTokens.fsXs,
          color: DesignTokens.textMuted,
          height: 1.6,
        ),
        labelLarge: TextStyle(
          fontSize: DesignTokens.fsMd,
          fontWeight: FontWeight.w500,
          color: DesignTokens.textPrimary,
        ),
      ),

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.bg,
        foregroundColor: DesignTokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: DesignTokens.fsXl,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: DesignTokens.bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          side: const BorderSide(color: DesignTokens.border),
        ),
        margin: const EdgeInsets.all(DesignTokens.sp2),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.sp6,
            vertical: DesignTokens.sp3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: DesignTokens.fsMd,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.brand,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.sp4,
            vertical: DesignTokens.sp2,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.textPrimary,
          side: const BorderSide(color: DesignTokens.border),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.sp6,
            vertical: DesignTokens.sp3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.sp4,
          vertical: DesignTokens.sp3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.brand, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.danger),
        ),
        hintStyle: const TextStyle(color: DesignTokens.textMuted),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: DesignTokens.border,
        thickness: 1,
        space: DesignTokens.sp4,
      ),

      // Tab Bar
      tabBarTheme: const TabBarTheme(
        labelColor: DesignTokens.textPrimary,
        unselectedLabelColor: DesignTokens.textSecondary,
        indicatorColor: DesignTokens.brand,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }
}

