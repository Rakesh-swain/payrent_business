// lib/config/theme.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryBright = Color(0xFF847BFF);
  static const Color secondary = Color(0xFF00D8FF);
  static const Color tertiary = Color(0xFFB76BFF);
  static const Color success = Color(0xFF3ED598);
  static const Color warning = Color(0xFFFFAD3B);
  static const Color error = Color(0xFFFF4D67);
  static const Color info = Color(0xFF4FD1FF);

  static const Color backgroundLight = Color(0xFFF3F5FD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF9F4FF);
  static const Color outlineLight = Color(0xFFE1E4FF);

  static const Color backgroundDark = Color(0xFF090B25);
  static const Color surfaceDark = Color(0xFF111438);
  static const Color surfaceElevatedDark = Color(0xFF1A1F45);
  static const Color outlineDark = Color(0xFF2C3270);

  static const Color textPrimaryLight = Color(0xFF1D1E33);
  static const Color textSecondaryLight = Color(0xFF5B5D7A);
  static const Color textPrimaryDark = Color(0xFFE9E9FF);
  static const Color textSecondaryDark = Color(0xFFADB1FF);
}

class AppGradients {
  const AppGradients({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.success,
    required this.error,
  });

  final LinearGradient primary;
  final LinearGradient secondary;
  final LinearGradient surface;
  final LinearGradient success;
  final LinearGradient error;
}

class AppShadows {
  const AppShadows({
    required this.level1,
    required this.level2,
    required this.glow,
  });

  final List<BoxShadow> level1;
  final List<BoxShadow> level2;
  final List<BoxShadow> glow;
}

class AppDecorations extends ThemeExtension<AppDecorations> {
  const AppDecorations({
    required this.gradients,
    required this.shadows,
    required this.surfaceBlur,
  });

  final AppGradients gradients;
  final AppShadows shadows;
  final double surfaceBlur;

  @override
  AppDecorations copyWith({
    AppGradients? gradients,
    AppShadows? shadows,
    double? surfaceBlur,
  }) {
    return AppDecorations(
      gradients: gradients ?? this.gradients,
      shadows: shadows ?? this.shadows,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
    );
  }

  @override
  ThemeExtension<AppDecorations> lerp(ThemeExtension<AppDecorations>? other, double t) {
    if (other is! AppDecorations) return this;
    return AppDecorations(
      gradients: AppGradients(
        primary: LinearGradient.lerp(gradients.primary, other.gradients.primary, t)!,
        secondary: LinearGradient.lerp(gradients.secondary, other.gradients.secondary, t)!,
        surface: LinearGradient.lerp(gradients.surface, other.gradients.surface, t)!,
        success: LinearGradient.lerp(gradients.success, other.gradients.success, t)!,
        error: LinearGradient.lerp(gradients.error, other.gradients.error, t)!,
      ),
      shadows: AppShadows(
        level1: _lerpShadows(shadows.level1, other.shadows.level1, t),
        level2: _lerpShadows(shadows.level2, other.shadows.level2, t),
        glow: _lerpShadows(shadows.glow, other.shadows.glow, t),
      ),
      surfaceBlur: lerpDouble(surfaceBlur, other.surfaceBlur, t) ?? surfaceBlur,
    );
  }

  static List<BoxShadow> _lerpShadows(List<BoxShadow> a, List<BoxShadow> b, double t) {
    final maxLength = a.length > b.length ? a.length : b.length;
    return List.generate(maxLength, (index) {
      final shadowA = index < a.length ? a[index] : BoxShadow(color: Colors.transparent);
      final shadowB = index < b.length ? b[index] : BoxShadow(color: Colors.transparent);
      return BoxShadow.lerp(shadowA, shadowB, t)!;
    });
  }
}

class AppTheme {
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.secondary;
  static const Color accentColor = AppColors.tertiary;
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;
  static const Color errorColor = AppColors.error;
  static const Color infoColor = AppColors.info;
  static const Color backgroundColor = AppColors.backgroundLight;
  static const Color cardColor = AppColors.surfaceLight;
  static const Color dividerColor = AppColors.outlineLight;
  static const Color textPrimary = AppColors.textPrimaryLight;
  static const Color textSecondary = AppColors.textSecondaryLight;
  static const Color textLight = AppColors.textSecondaryLight;
  static const List<Color> primaryGradient = [AppColors.primary, AppColors.secondary];
  static const List<Color> successGradient = [AppColors.success, Color(0xFF25C883)];
  static const List<Color> warningGradient = [AppColors.warning, Color(0xFFFF7E36)];
  static const List<Color> errorGradient = [AppColors.error, Color(0xFFF93B55)];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.08),
          blurRadius: 26,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get bottomNavShadow => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.12),
          blurRadius: 36,
          spreadRadius: 6,
          offset: const Offset(0, 18),
        ),
      ];

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: isDark ? AppColors.secondary.withOpacity(0.85) : AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      surfaceTint: AppColors.primaryBright,
      background: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onBackground: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      onError: Colors.white,
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onBackground,
      displayColor: colorScheme.onBackground,
    );

    final cardColor = isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight;
    final outlineColor = isDark ? AppColors.outlineDark : AppColors.outlineLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: colorScheme.onBackground.withOpacity(0.85), size: 22),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          side: BorderSide(color: outlineColor.withOpacity(0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ).merge(
          ButtonStyle(
            overlayColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.pressed)
                  ? colorScheme.secondary.withOpacity(0.2)
                  : null,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withOpacity(0.4), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white.withOpacity(0.92),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: outlineColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: outlineColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: secondaryText),
        hintStyle: textTheme.bodyMedium?.copyWith(color: secondaryText.withOpacity(0.6)),
        helperStyle: textTheme.bodySmall?.copyWith(color: secondaryText.withOpacity(0.7)),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w600),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.secondary.withOpacity(isDark ? 0.16 : 0.12),
        selectedColor: colorScheme.primary.withOpacity(0.2),
        secondaryLabelStyle: textTheme.labelLarge,
        labelStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        backgroundColor: cardColor,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: secondaryText.withOpacity(0.7),
        selectedLabelStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelMedium,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primary.withOpacity(0.15),
        elevation: 0,
        iconTheme: WidgetStateProperty.all(IconThemeData(color: colorScheme.primary)),
        labelTextStyle: WidgetStateTextStyle.resolveWith(
          (states) => textTheme.labelLarge?.copyWith(
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ) ?? const TextStyle(),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: const BoxDecoration(),
        labelStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.titleMedium,
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: secondaryText,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primary.withOpacity(0.12),
        iconColor: secondaryText,
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.secondary,
        circularTrackColor: colorScheme.primary.withOpacity(0.2),
        linearTrackColor: outlineColor.withOpacity(0.2),
      ),
      dividerTheme: DividerThemeData(
        color: outlineColor.withOpacity(0.2),
        thickness: 1,
        space: 32,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        textStyle: textTheme.labelMedium,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: outlineColor.withOpacity(0.4)),
        fillColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? colorScheme.primary
              : outlineColor.withOpacity(0.3),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.all(colorScheme.primary),
      ),
      switchTheme: SwitchThemeData(
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? colorScheme.primary.withOpacity(0.45)
              : outlineColor.withOpacity(0.25),
        ),
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? colorScheme.primary
              : secondaryText.withOpacity(0.6),
        ),
      ),
      typography: Typography.material2021(platform: TargetPlatform.android),
      extensions: <ThemeExtension<dynamic>>[
        AppDecorations(
          gradients: AppGradients(
            primary: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
              begin: const Alignment(-1, -0.8),
              end: const Alignment(0.8, 1),
            ),
            secondary: LinearGradient(
              colors: [
                colorScheme.secondary,
                colorScheme.tertiary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            surface: LinearGradient(
              colors: [
                cardColor.withOpacity(isDark ? 0.95 : 0.85),
                (isDark ? AppColors.surfaceDark : AppColors.surfaceLight).withOpacity(0.92),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            success: LinearGradient(
              colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            error: LinearGradient(
              colors: [AppColors.error, AppColors.error.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          shadows: AppShadows(
            level1: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(isDark ? 0.25 : 0.18),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
            level2: [
              BoxShadow(
                color: colorScheme.secondary.withOpacity(isDark ? 0.24 : 0.16),
                blurRadius: 36,
                offset: const Offset(0, 24),
              ),
            ],
            glow: [
              BoxShadow(
                color: colorScheme.secondary.withOpacity(0.35),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          surfaceBlur: isDark ? 30 : 24,
        ),
      ],
    );
  }
}

extension TextStyleExtensions on BuildContext {
  TextStyle get headingLarge => Theme.of(this).textTheme.displaySmall!.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  TextStyle get headingMedium => Theme.of(this).textTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  TextStyle get headingSmall => Theme.of(this).textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w600,
      );

  TextStyle get titleLarge => Theme.of(this).textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w600,
      );

  TextStyle get titleMedium => Theme.of(this).textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w600,
      );

  TextStyle get titleSmall => Theme.of(this).textTheme.titleSmall!.copyWith(
        fontWeight: FontWeight.w600,
      );

  TextStyle get bodyLarge => Theme.of(this).textTheme.bodyLarge!.copyWith(
        fontWeight: FontWeight.w500,
      );

  TextStyle get bodyMedium => Theme.of(this).textTheme.bodyMedium!;

  TextStyle get bodySmall => Theme.of(this).textTheme.bodySmall!.copyWith(
        fontWeight: FontWeight.w500,
      );

  TextStyle get caption => Theme.of(this).textTheme.labelLarge!.copyWith(
        letterSpacing: 0.4,
      );
}