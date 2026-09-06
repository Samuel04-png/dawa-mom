import 'package:flutter/material.dart';

/// Visual tokens derived from the supplied DawaMom 9:16 screen references.
///
/// These intentionally live beside (rather than inside) the legacy
/// FlutterFlow theme so existing clinical and authentication logic can be
/// migrated screen-by-screen without changing its behavior.
abstract final class DawaColors {
  static const canvas = Color(0xFFFFFAF4);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1539C7);
  static const primaryDark = Color(0xFF0C2A9B);
  static const green = Color(0xFF42BE53);
  static const greenDark = Color(0xFF247A38);
  static const orange = Color(0xFFF27A3F);
  static const teal = Color(0xFF168B88);
  static const ink = Color(0xFF13255B);
  static const muted = Color(0xFF667197);
  static const line = Color(0xFFDFE4F0);
  static const softBlue = Color(0xFFF0F3FF);
  static const softGreen = Color(0xFFF0F9ED);
  static const softPink = Color(0xFFFFEEF3);
  static const softPurple = Color(0xFFF5EEFB);
  static const softOrange = Color(0xFFFFF1E8);
  static const softTeal = Color(0xFFEAF8F5);
  static const warmSurface = Color(0xFFFFFDF9);
  static const purple = Color(0xFF8751B8);
  static const pink = Color(0xFFE95D82);
  static const gold = Color(0xFFF6B81B);
  static const danger = Color(0xFFD64553);

  // Semantic aliases. New product surfaces should prefer these names so a
  // foreground/background relationship remains explicit and testable.
  static const backgroundPrimary = canvas;
  static const backgroundSecondary = softBlue;
  static const surfaceStrong = Color(0xFFF7F8FC);
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF485678);
  static const textMuted = muted;
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const border = line;
  static const borderStrong = Color(0xFFB8C0D5);
  static const primaryBlue = primary;
  static const primaryBluePressed = primaryDark;
  static const healthGreen = Color(0xFF237A37);
  static const warning = Color(0xFF8A5900);
  static const successSurface = softGreen;
  static const warningSurface = Color(0xFFFFF5DE);
  static const dangerSurface = softPink;
  static const disabledSurface = Color(0xFFE8EBF2);
  static const disabledText = Color(0xFF5F6880);
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

abstract final class DawaLayout {
  /// Height reserved for the five-destination mobile navigation surface.
  static const mobileNavigationHeight = 72.0;

  /// Decorative space above mobile navigation for the wave and Rudo launcher.
  ///
  /// The responsive shell owns this area. Individual pages must not reserve or
  /// repaint it, otherwise a second footer appears when content is scrolled.
  static const mobileNavigationWaveClearance = 46.0;

  /// Breathing room between the final interactive element and navigation.
  static const bottomContentGap = 32.0;

  /// Maximum height for decorative artwork that sits behind page content.
  static const bottomWaveHeight = 56.0;

  /// Consistent bounds keep transparent character artwork from dominating
  /// compact cards or becoming visually lost on tablets.
  static const mobileIllustrationMaxHeight = 196.0;
  static const tabletIllustrationMaxHeight = 236.0;
}

abstract final class DawaRadii {
  static const small = 12.0;
  static const medium = 18.0;
  static const large = 26.0;
  static const feature = 30.0;
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
      color: Color(0x160C2878),
      blurRadius: 24,
      offset: Offset(0, 9),
    ),
    BoxShadow(
      color: Color(0x0AFFFFFF),
      blurRadius: 2,
      offset: Offset(0, -1),
    ),
  ];

  static const floating = <BoxShadow>[
    BoxShadow(
      color: Color(0x220C2878),
      blurRadius: 30,
      offset: Offset(0, 14),
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
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: DawaColors.canvas,
        foregroundColor: DawaColors.ink,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: DawaColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: DawaColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DawaRadii.medium),
          side: const BorderSide(color: DawaColors.line),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DawaColors.canvas,
        modalBackgroundColor: DawaColors.canvas,
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DawaColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 13,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DawaRadii.medium),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: DawaColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DawaColors.disabledSurface,
          disabledForegroundColor: DawaColors.disabledText,
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
          disabledForegroundColor: DawaColors.disabledText,
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
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
      );

  TextStyle get dawaCaption => const TextStyle(
        fontFamily: 'Poppins',
        color: DawaColors.muted,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w400,
      );
}
