import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================================
/// NEO-BRUTALIST OCEAN THEME
/// ============================================================================
/// High contrast, industrial-tactile design with Ocean color palette
/// Features: Thick black borders, hard shadows, minimal rounding (4px)
/// ============================================================================

class AppTheme {
  AppTheme._();

  // ============================================================================
  // NEO-BRUTALIST OCEAN COLOR PALETTE
  // ============================================================================

  // Primary: Sky Blue
  static const Color primarySkyBlue = Color(0xFFC6E7FF);

  // Secondary/Surface: Seafoam Mist
  static const Color secondarySeafoam = Color(0xFFD4F6FF);

  // Background: Pure Salt
  static const Color backgroundPureSalt = Color(0xFFFBFBFB);

  // Accent/CTA: Sand Gold
  static const Color accentSandGold = Color(0xFFFFDDAE);

  // Stroke/Shadow: Pure Black
  static const Color strokePureBlack = Color(0xFF000000);

  // Supporting Colors
  static const Color textBlack = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);

  // Legacy/Fallback
  static const Color darkGrey = Color(0xFF333333);
  static const Color lightGrey = Color(0xFFEEEEEE);

  // ============================================================================
  // BACKWARDS-COMPATIBLE COLOR ALIASES (for migration from old theme)
  // ============================================================================
  static const Color primaryOceanTeal = Color(0xFFC6E7FF); // Sky Blue
  static const Color primarySteelBlue = Color(0xFFC6E7FF); // Sky Blue
  static const Color butterSmooth = Color(0xFFD4F6FF); // Seafoam
  static const Color secondaryMint = Color(0xFFD4F6FF); // Seafoam
  static const Color textPrimary = Color(0xFF000000); // Black
  static const Color textSecondary = Color(0xFF333333); // Dark Grey
  static const Color backgroundBeachSand = Color(0xFFFBFBFB); // Pure Salt
  static const Color glassSoftTeal = Color(0xFFD4F6FF); // Seafoam
  static const Color glassLightPeach = Color(0xFFFFDDAE); // Sand Gold
  static const Color actionCoral = Color(0xFFFFDDAE); // Sand Gold
  static const Color divider = Color(0xFF000000); // Black

  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================

  static const Curve brutalistSnap = Curves.easeInOut;
  static const Curve heavyPress = Curves.easeOutQuart;

  // ============================================================================
  // TYPOGRAPHY - SYNE (Headlines) & DM SANS (Body)
  // ============================================================================

  static TextTheme get _neoBrutalistTextTheme {
    return TextTheme(
      // DISPLAY - Syne (Black, Uppercase, Hard)
      displayLarge: _syne(57, FontWeight.w900),
      displayMedium: _syne(45, FontWeight.w900),
      displaySmall: _syne(36, FontWeight.w900),

      // HEADLINES - Syne (Black, Uppercase, Hard)
      headlineLarge: _syne(32, FontWeight.w900),
      headlineMedium: _syne(28, FontWeight.w900),
      headlineSmall: _syne(24, FontWeight.w900),

      // TITLES - Syne/DM Sans (Bold)
      titleLarge: _syne(22, FontWeight.w900),
      titleMedium: _dmSans(16, FontWeight.w700),
      titleSmall: _dmSans(14, FontWeight.w700),

      // BODY - DM Sans (Bold, Heavy Weight)
      bodyLarge: _dmSans(16, FontWeight.w700),
      bodyMedium: _dmSans(14, FontWeight.w700),
      bodySmall: _dmSans(12, FontWeight.w700),

      // LABELS - DM Sans (Bold)
      labelLarge: _dmSans(14, FontWeight.w700),
      labelMedium: _dmSans(12, FontWeight.w700),
      labelSmall: _dmSans(11, FontWeight.w700),
    );
  }

  // Syne - For Headlines (Black, Uppercase, Hard Kerning)
  static TextStyle _syne(double fontSize, FontWeight fontWeight) {
    return TextStyle(
      fontFamily: 'Syne',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: textBlack,
      height: 1.1,
      letterSpacing: -0.5,
    );
  }

  // DM Sans - For Body (Bold)
  static TextStyle _dmSans(double fontSize, FontWeight fontWeight) {
    return TextStyle(
      fontFamily: 'DM Sans',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: textBlack,
      height: 1.4,
      letterSpacing: 0.2,
    );
  }

  // ============================================================================
  // COLOR SCHEME - NEO-BRUTALIST OCEAN
  // ============================================================================

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primarySkyBlue, // #C6E7FF
    onPrimary: textBlack,
    primaryContainer: secondarySeafoam,
    onPrimaryContainer: textBlack,
    secondary: secondarySeafoam, // #D4F6FF
    onSecondary: textBlack,
    secondaryContainer: accentSandGold,
    onSecondaryContainer: textBlack,
    tertiary: accentSandGold, // #FFDDAE
    onTertiary: textBlack,
    tertiaryContainer: primarySkyBlue,
    onTertiaryContainer: textBlack,
    error: error,
    onError: white,
    errorContainer: Color(0xFFFFE5E5),
    onErrorContainer: error,
    surface: backgroundPureSalt, // #FBFBFB
    onSurface: textBlack,
    surfaceContainerHighest: backgroundPureSalt,
    onSurfaceVariant: darkGrey,
    outline: strokePureBlack,
    outlineVariant: lightGrey,
    shadow: strokePureBlack,
    scrim: Color(0xFF000000),
    inverseSurface: textBlack,
    onInverseSurface: white,
    inversePrimary: accentSandGold,
  );

  // ============================================================================
  // PAGE TRANSITIONS
  // ============================================================================

  static PageTransitionsBuilder get _neoBrutalistPageTransition {
    return const _HardCutPageTransitionsBuilder();
  }

  // ============================================================================
  // THEME DATA - NEO-BRUTALIST OCEAN
  // ============================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      textTheme: _neoBrutalistTextTheme,
      scaffoldBackgroundColor: backgroundPureSalt, // #FBFBFB
      appBarTheme: _neoBrutalistAppBarTheme,
      elevatedButtonTheme: _neoBrutalistElevatedButtonTheme,
      outlinedButtonTheme: _neoBrutalistOutlinedButtonTheme,
      textButtonTheme: _neoBrutalistTextButtonTheme,
      inputDecorationTheme: _neoBrutalistInputDecorationTheme,
      cardTheme: _neoBrutalistCardTheme,
      floatingActionButtonTheme: _neoBrutalistFabTheme,
      bottomNavigationBarTheme: _neoBrutalistBottomNavTheme,
      snackBarTheme: _neoBrutalistSnackBarTheme,
      dialogTheme: _neoBrutalistDialogTheme,
      dividerTheme: _neoBrutalistDividerTheme,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _neoBrutalistPageTransition,
          TargetPlatform.iOS: _neoBrutalistPageTransition,
        },
      ),
    );
  }

  // ============================================================================
  // COMPONENT THEMES - NEO-BRUTALIST STYLING
  // ============================================================================

  static AppBarTheme get _neoBrutalistAppBarTheme {
    return const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundPureSalt,
      foregroundColor: textBlack,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: textBlack),
      titleTextStyle: TextStyle(
        fontFamily: 'Syne',
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: textBlack,
      ),
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  static ElevatedButtonThemeData get _neoBrutalistElevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentSandGold, // #FFDDAE
        foregroundColor: textBlack,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Hard corners
          side: const BorderSide(
            color: strokePureBlack,
            width: 3.0, // Thick black border
          ),
        ),
        textStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData get _neoBrutalistOutlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textBlack,
        side: const BorderSide(
          color: strokePureBlack,
          width: 3.0, // Thick black border
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Hard corners
        ),
        textStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static TextButtonThemeData get _neoBrutalistTextButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textBlack,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static InputDecorationTheme get _neoBrutalistInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: secondarySeafoam, // #D4F6FF - Seafoam fill
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4), // Hard corners
        borderSide: const BorderSide(
          color: strokePureBlack,
          width: 3.0, // Thick black border
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(
          color: strokePureBlack,
          width: 3.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(
          color: strokePureBlack,
          width: 3.0,
        ),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'DM Sans',
        color: darkGrey,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'DM Sans',
        color: textBlack,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static CardThemeData get _neoBrutalistCardTheme {
    return CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      color: backgroundPureSalt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // Hard corners
        side: const BorderSide(
          color: strokePureBlack,
          width: 3.0, // Thick black border
        ),
      ),
      margin: const EdgeInsets.all(8),
    );
  }

  static FloatingActionButtonThemeData get _neoBrutalistFabTheme {
    return const FloatingActionButtonThemeData(
      backgroundColor: accentSandGold, // #FFDDAE
      foregroundColor: textBlack,
      elevation: 0,
      extendedPadding: EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        side: BorderSide(
          color: strokePureBlack,
          width: 3.0,
        ),
      ),
    );
  }

  static BottomNavigationBarThemeData get _neoBrutalistBottomNavTheme {
    return const BottomNavigationBarThemeData(
      backgroundColor: backgroundPureSalt,
      selectedItemColor: textBlack,
      unselectedItemColor: darkGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static SnackBarThemeData get _neoBrutalistSnackBarTheme {
    return SnackBarThemeData(
      backgroundColor: accentSandGold, // #FFDDAE
      contentTextStyle: const TextStyle(
        fontFamily: 'DM Sans',
        color: textBlack,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(
          color: strokePureBlack,
          width: 3.0,
        ),
      ),
    );
  }

  static DialogThemeData get _neoBrutalistDialogTheme {
    return DialogThemeData(
      backgroundColor: backgroundPureSalt,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(
          color: strokePureBlack,
          width: 3.0,
        ),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Syne',
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: textBlack,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: 16,
        height: 1.6,
        color: darkGrey,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static DividerThemeData get _neoBrutalistDividerTheme {
    return const DividerThemeData(
      color: strokePureBlack,
      thickness: 3.0, // Thick dividers
      space: 16,
    );
  }
}

// ============================================================================
// HARD CUT PAGE TRANSITIONS (NEO-BRUTALIST MOTION)
// ============================================================================

class _HardCutPageTransitionsBuilder extends PageTransitionsBuilder {
  const _HardCutPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _HardCutTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _HardCutTransition extends StatelessWidget {
  const _HardCutTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

// ============================================================================
// THEME EXTENSIONS
// ============================================================================

extension NeoBrutalistThemeExtensions on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  Color get primaryColor => colorScheme.primary;
  Color get backgroundColor => colorScheme.surfaceContainerHighest;

  Color get skyBlue => AppTheme.primarySkyBlue;
  Color get seafoam => AppTheme.secondarySeafoam;
  Color get sandGold => AppTheme.accentSandGold;
  Color get pureBlack => AppTheme.strokePureBlack;
}
