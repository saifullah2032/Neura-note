import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color oceanDeep = Color(0xFF006064);
  static const Color oceanTeal = Color(0xFF00838F);
  static const Color coralTeal = Color(0xFF4DB6AC);
  static const Color skyBlue = Color(0xFFE1F5FE);
  static const Color seaFoam = Color(0xFFB2DFDB);
  static const Color oceanWhite = Color(0xFFF8F9FA);
  static const Color deepNavy = Color(0xFF00363A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      textTheme: _oceanTextTheme,
      appBarTheme: _oceanAppBarTheme,
      elevatedButtonTheme: _oceanElevatedButtonTheme,
      outlinedButtonTheme: _oceanOutlinedButtonTheme,
      textButtonTheme: _oceanTextButtonTheme,
      inputDecorationTheme: _oceanInputDecorationTheme,
      cardTheme: _oceanCardTheme,
      floatingActionButtonTheme: _oceanFabTheme,
      bottomNavigationBarTheme: _oceanBottomNavTheme,
      snackBarTheme: _oceanSnackBarTheme,
      dialogTheme: _oceanDialogTheme,
      dividerTheme: _oceanDividerTheme,
      scaffoldBackgroundColor: oceanWhite,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      textTheme: _oceanTextTheme,
      scaffoldBackgroundColor: const Color(0xFF0D1F22),
    );
  }

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: oceanDeep,
    onPrimary: Colors.white,
    primaryContainer: coralTeal,
    onPrimaryContainer: deepNavy,
    secondary: coralTeal,
    onSecondary: Colors.white,
    secondaryContainer: seaFoam,
    onSecondaryContainer: deepNavy,
    tertiary: skyBlue,
    onTertiary: deepNavy,
    error: Color(0xFFE57373),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: deepNavy,
    surfaceContainerHighest: oceanWhite,
    onSurfaceVariant: Color(0xFF546E7A),
    outline: Color(0xFFB0BEC5),
    shadow: Color(0x33000000),
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: coralTeal,
    onPrimary: deepNavy,
    primaryContainer: oceanDeep,
    onPrimaryContainer: Colors.white,
    secondary: seaFoam,
    onSecondary: deepNavy,
    error: Color(0xFFEF9A9A),
    onError: deepNavy,
    surface: Color(0xFF0D1F22),
    onSurface: Colors.white,
    surfaceContainerHighest: Color(0xFF1A2F33),
    onSurfaceVariant: Color(0xFFB0BEC5),
    outline: Color(0xFF37474F),
    shadow: Colors.black,
  );

  static TextTheme get _oceanTextTheme {
    return TextTheme(
      displayLarge: GoogleFonts.syne(
        fontSize: 57,
        fontWeight: FontWeight.bold,
        color: deepNavy,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.syne(
        fontSize: 45,
        fontWeight: FontWeight.bold,
        color: deepNavy,
      ),
      displaySmall: GoogleFonts.syne(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: deepNavy,
      ),
      headlineLarge: GoogleFonts.syne(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: deepNavy,
      ),
      headlineMedium: GoogleFonts.syne(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: deepNavy,
      ),
      headlineSmall: GoogleFonts.syne(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: deepNavy,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: deepNavy,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: deepNavy,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: deepNavy,
        letterSpacing: 0.1,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: deepNavy,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: deepNavy,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Color(0xFF546E7A),
        letterSpacing: 0.4,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: deepNavy,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF546E7A),
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF78909C),
        letterSpacing: 0.5,
      ),
    );
  }

  static AppBarTheme get _oceanAppBarTheme {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Colors.transparent,
      foregroundColor: deepNavy,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: oceanDeep),
      titleTextStyle: GoogleFonts.syne(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: deepNavy,
      ),
      centerTitle: false,
    );
  }

  static ElevatedButtonThemeData get _oceanElevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: oceanDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: oceanDeep.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData get _oceanOutlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: oceanDeep,
        side: BorderSide(color: oceanDeep.withValues(alpha: 0.6), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextButtonThemeData get _oceanTextButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: oceanDeep,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme get _oceanInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: oceanDeep, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE57373), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
      ),
      hintStyle: GoogleFonts.dmSans(
        color: Color(0xFFB0BEC5),
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.dmSans(
        color: Color(0xFF546E7A),
        fontSize: 14,
      ),
      errorStyle: GoogleFonts.dmSans(
        color: Color(0xFFE57373),
        fontSize: 12,
      ),
    );
  }

  static CardThemeData get _oceanCardTheme {
    return CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      margin: const EdgeInsets.all(8),
    );
  }

  static FloatingActionButtonThemeData get _oceanFabTheme {
    return const FloatingActionButtonThemeData(
      backgroundColor: oceanDeep,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    );
  }

  static BottomNavigationBarThemeData get _oceanBottomNavTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: oceanDeep,
      unselectedItemColor: Color(0xFF90A4AE),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  static SnackBarThemeData get _oceanSnackBarTheme {
    return SnackBarThemeData(
      backgroundColor: deepNavy,
      contentTextStyle: GoogleFonts.dmSans(
        color: Colors.white,
        fontSize: 14,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static DialogThemeData get _oceanDialogTheme {
    return DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: GoogleFonts.syne(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: deepNavy,
      ),
      contentTextStyle: GoogleFonts.dmSans(
        fontSize: 14,
        color: Color(0xFF546E7A),
      ),
    );
  }

  static DividerThemeData get _oceanDividerTheme {
    return const DividerThemeData(
      color: Color(0xFFECEFF1),
      thickness: 1,
      space: 1,
    );
  }
}

extension OceanThemeExtensions on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  Color get primaryColor => colorScheme.primary;
  Color get backgroundColor => colorScheme.surface;
  Color get errorColor => colorScheme.error;

  static const Color oceanDeep = AppTheme.oceanDeep;
  static const Color coralTeal = AppTheme.coralTeal;
  static const Color skyBlue = AppTheme.skyBlue;
  static const Color seaFoam = AppTheme.seaFoam;
  static const Color oceanWhite = AppTheme.oceanWhite;
}
