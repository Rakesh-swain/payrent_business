// lib/config/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // PayRent Primary Color
  static const Color primaryColor = Color(0xFF0056D2);
  static const Color primaryBlue = Color(0xFF0056D2); // Alias for backward compatibility
  
  // Modern Color Palette
  static const Color tealPrimary = Color(0xFF26C6DA);
  static const Color tealSecondary = Color(0xFF00BCD4);
  static const Color purplePrimary = Color(0xFF9C27B0);
  static const Color purpleSecondary = Color(0xFF673AB7);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B737A);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBg = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF757575);
  
  // Status Colors
  static const Color successColor = Color(0xFF00E676);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color infoColor = Color(0xFF29B6F6);
  
  // Backward compatibility aliases
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textLight = lightTextTertiary;
  static const Color backgroundColor = lightBackground;
  static const Color cardColor = lightCardBg;
  static const Color accentColor = successColor;
  static const Color dividerColor = Color(0xFFEEEEEE);
  
  // Static shadow lists for backward compatibility
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get bottomNavShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 15,
      offset: const Offset(0, -3),
    ),
  ];
  
  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF4A90E2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient tealGradient = LinearGradient(
    colors: [tealPrimary, tealSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [purplePrimary, purpleSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFE53E3E), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Glass Morphism Effects
  static BoxDecoration glassCard({bool isDark = false}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: isDark 
          ? Colors.white.withOpacity(0.1)
          : Colors.white.withOpacity(0.8),
      border: Border.all(
        color: isDark 
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.3),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
  
  // Enhanced Shadows (modern versions)
  static List<BoxShadow> modernCardShadow({bool isDark = false}) {
    return [
      BoxShadow(
        color: isDark 
            ? Colors.black.withOpacity(0.4)
            : Colors.black.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: -2,
      ),
      BoxShadow(
        color: isDark 
            ? Colors.black.withOpacity(0.2)
            : Colors.black.withOpacity(0.04),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }
  
  static List<BoxShadow> elevatedShadow({bool isDark = false}) {
    return [
      BoxShadow(
        color: isDark 
            ? Colors.black.withOpacity(0.6)
            : Colors.black.withOpacity(0.12),
        blurRadius: 30,
        offset: const Offset(0, 12),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: isDark 
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.06),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }
  
  static List<BoxShadow> modernBottomNavShadow({bool isDark = false}) {
    return [
      BoxShadow(
        color: isDark 
            ? Colors.black.withOpacity(0.6)
            : Colors.black.withOpacity(0.1),
        blurRadius: 25,
        offset: const Offset(0, -8),
        spreadRadius: -2,
      ),
    ];
  }
  
  // Typography Methods
  static TextStyle headingLarge({Color? color, bool isDark = false}) {
    return GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: color ?? (isDark ? darkTextPrimary : lightTextPrimary),
    );
  }
  
  static TextStyle headingMedium({Color? color, bool isDark = false}) {
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: color ?? (isDark ? darkTextPrimary : lightTextPrimary),
    );
  }
  
  static TextStyle titleLarge({Color? color, bool isDark = false}) {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: color ?? (isDark ? darkTextPrimary : lightTextPrimary),
    );
  }
  
  static TextStyle bodyLarge({Color? color, bool isDark = false}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color ?? (isDark ? darkTextPrimary : lightTextPrimary),
    );
  }
  
  static TextStyle bodyMedium({Color? color, bool isDark = false}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color ?? (isDark ? darkTextSecondary : lightTextSecondary),
    );
  }
}

// Extensions for convenient access to theme colors
extension AppThemeExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  Color get primaryColor => colorScheme.primary;
  Color get backgroundColor => colorScheme.background;
  Color get surfaceColor => colorScheme.surface;
  Color get textPrimaryColor => colorScheme.onSurface;
  Color get textSecondaryColor => isDarkMode 
      ? AppTheme.darkTextSecondary 
      : AppTheme.lightTextSecondary;
}