// lib/config/theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 VIBRANT COLOR SYSTEM
  // Primary Colors
  static const Color primaryColor = Color(0xFF6C63FF);  // Vibrant Purple
  static const Color primaryLight = Color(0xFF8B82FF);
  static const Color primaryDark = Color(0xFF5A52E6);
  
  // Status Colors  
  static const Color successColor = Color(0xFF32D39B);  // Emerald Green
  static const Color warningColor = Color(0xFFFF6584);  // Coral Pink
  static const Color errorColor = Color(0xFFFF6B85);
  static const Color infoColor = Color(0xFF60A5FA);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2D3748);
  static const Color lightTextSecondary = Color(0xFF718096);
  static const Color lightTextTertiary = Color(0xFFA0AEC0);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFFA0AEC0);
  static const Color darkTextTertiary = Color(0xFF718096);
  
  // 🎨 GRADIENT DEFINITIONS
  static const List<Color> primaryGradient = [
    Color(0xFF6C63FF),
    Color(0xFF8B82FF),
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF32D39B),
    Color(0xFF10B981),
  ];
  
  static const List<Color> warningGradient = [
    Color(0xFFFF6584),
    Color(0xFFFF8FB8),
  ];
  
  static const List<Color> darkGradient = [
    Color(0xFF1E1E1E),
    Color(0xFF2D2D30),
  ];

  // ✨ MODERN SHADOWS & EFFECTS
  static List<BoxShadow> get modernCardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get modernElevatedShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: primaryColor.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get glowEffect => [
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 0),
      spreadRadius: 0,
    ),
  ];

  // 🌟 LIGHT THEME
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: primaryLight,
        onSecondary: Colors.white,
        surface: lightSurface,
        onSurface: lightText,
        background: lightBackground,
        onBackground: lightText,
        error: errorColor,
        onError: Colors.white,
        outline: Color(0xFFE0E7FF),
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
        iconTheme: const IconThemeData(color: primaryColor, size: 24),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: lightText,
        displayColor: lightText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.all(
            Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E7FF), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E7FF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: GoogleFonts.poppins(
          color: lightTextSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: lightTextTertiary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(0),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextTertiary,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // 🌙 DARK THEME
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: primaryLight,
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: darkText,
        background: darkBackground,
        onBackground: darkText,
        error: errorColor,
        onError: Colors.white,
        outline: Color(0xFF3A3A3C),
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        iconTheme: const IconThemeData(color: primaryColor, size: 24),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.all(
            Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: GoogleFonts.poppins(
          color: darkTextSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: darkTextTertiary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(0),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkTextTertiary,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // 🎨 MODERN DECORATION HELPERS
  static BoxDecoration modernCardDecoration({
    Color? color,
    bool isDark = false,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? darkSurface : lightSurface),
      borderRadius: BorderRadius.circular(20),
      boxShadow: withShadow ? modernCardShadow : null,
    );
  }

  static BoxDecoration gradientDecoration({
    required List<Color> colors,
    BorderRadius? borderRadius,
    bool withShadow = false,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      boxShadow: withShadow ? modernCardShadow : null,
    );
  }

  static BoxDecoration glassDecoration({
    bool isDark = false,
    double opacity = 0.1,
  }) {
    return BoxDecoration(
      color: isDark 
          ? Colors.white.withOpacity(opacity)
          : Colors.white.withOpacity(opacity + 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: modernCardShadow,
    );
  }
}

// Extensions for text styles
extension TextStyleExtensions on BuildContext {
  TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppTheme.lightText,
  );
  
  TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppTheme.lightText,
  );
  
  TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.lightText,
  );
  
  TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppTheme.lightText,
  );
  
  TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.lightText,
  );
  
  TextStyle get titleSmall => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.lightText,
  );
  
  TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppTheme.lightText,
  );
  
  TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppTheme.lightText,
  );
  
  TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppTheme.lightTextSecondary,
  );
}