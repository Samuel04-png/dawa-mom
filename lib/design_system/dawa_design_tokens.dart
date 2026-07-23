import 'package:flutter/material.dart';

/// Visual tokens derived from the supplied Dawa Mom 9:16 screen references.
///
/// These intentionally live beside (rather than inside) the legacy
/// FlutterFlow theme so existing clinical and authentication logic can be
/// migrated screen-by-screen without changing its behavior.
abstract final class DawaColors {
  static const canvas = Color(0xFFFFFCF8);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1539C7);
  static const primaryDark = Color(0xFF0C2A9B);
  static const green = Color(0xFF42BE53);
  static const ink = Color(0xFF13255B);
  static const muted = Color(0xFF667197);
  static const line = Color(0xFFE3E7F2);
  static const softBlue = Color(0xFFF1F4FF);
  static const softGreen = Color(0xFFF1FAEF);
  static const softPink = Color(0xFFFFF1F4);
  static const softPurple = Color(0xFFF5F0FB);
  static const purple = Color(0xFF8751B8);
  static const pink = Color(0xFFE95D82);
  static const gold = Color(0xFFF6B81B);
  static const danger = Color(0xFFD64553);
}

abstract final class DawaSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class DawaRadii {
  static const small = 10.0;
  static const medium = 16.0;
  static const large = 22.0;
  static const pill = 999.0;
}

abstract final class DawaBreakpoints {
  static const mobile = 700.0;
  static const desktop = 1100.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static double pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return 32;
    if (width >= mobile) return 24;
    return 16;
  }
}

abstract final class DawaShadows {
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x100C2878),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}

abstract final class DawaTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: DawaColors.primary,
      brightness: Brightness.light,
      primary: DawaColors.primary,
      secondary: DawaColors.green,
      surface: DawaColors.surface,
      error: DawaColors.danger,
    );
    final base = ThemeData(
      colorScheme: scheme,
      brightness: Brightness.light,
      useMaterial3: false,
      scaffoldBackgroundColor: DawaColors.canvas,
      fontFamily: 'Poppins',
      focusColor: DawaColors.primary.withValues(alpha: 0.12),
      hoverColor: DawaColors.primary.withValues(alpha: 0.06),
      splashColor: DawaColors.primary.withValues(alpha: 0.08),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: DawaColors.ink,
        displayColor: DawaColors.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DawaColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: DawaColors.muted, fontSize: 14),
        prefixIconColor: DawaColors.primary,
        suffixIconColor: DawaColors.primary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          borderSide: const BorderSide(color: DawaColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          borderSide: const BorderSide(color: DawaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          borderSide: const BorderSide(color: DawaColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          borderSide: const BorderSide(color: DawaColors.danger, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: DawaColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DawaRadii.medium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          foregroundColor: DawaColors.primary,
          side: const BorderSide(color: DawaColors.primary),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DawaRadii.medium),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: DawaColors.surface,
        selectedColor: DawaColors.primary,
        side: const BorderSide(color: DawaColors.line),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: DawaColors.ink,
          fontSize: 12,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DawaRadii.pill),
        ),
      ),
    );
  }
}

extension DawaTextStyles on BuildContext {
  TextStyle get dawaDisplay => const TextStyle(
        fontFamily: 'Poppins',
        color: DawaColors.primaryDark,
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w600,
      );

  TextStyle get dawaTitle => const TextStyle(
        fontFamily: 'Poppins',
        color: DawaColors.primaryDark,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
      );

  TextStyle get dawaSectionTitle => const TextStyle(
        fontFamily: 'Poppins',
        color: DawaColors.primaryDark,
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w600,
      );

  TextStyle get dawaBody => const TextStyle(
        fontFamily: 'Poppins',
        color: DawaColors.ink,
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
      );

  TextStyle get dawaCaption => const TextStyle(
        fontFamily: 'Poppins',
        color: DawaColors.muted,
        fontSize: 11,
        height: 1.35,
        fontWeight: FontWeight.w400,
      );
}
