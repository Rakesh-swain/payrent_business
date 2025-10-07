// lib/widgets/modern_components.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payrent_business/controllers/theme_controller.dart';
import 'package:payrent_business/config/theme.dart';

// 🎨 Modern Card Component
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool withShadow;
  final bool isGlass;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ModernCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.withShadow = true,
    this.isGlass = false,
    this.gradientColors,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        BoxDecoration decoration;

        if (gradientColors != null) {
          decoration = AppTheme.gradientDecoration(
            colors: gradientColors!,
            withShadow: withShadow,
            borderRadius: borderRadius,
          );
        } else if (isGlass) {
          decoration = AppTheme.glassDecoration(
            isDark: themeController.isDarkMode,
            opacity: 0.1,
          );
        } else {
          decoration = AppTheme.modernCardDecoration(
            isDark: themeController.isDarkMode,
            withShadow: withShadow,
          );
        }

        Widget cardWidget = Container(
          width: width,
          height: height,
          margin: margin,
          decoration: decoration,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        );

        if (onTap != null) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap!();
            },
            child: cardWidget,
          );
        }

        return cardWidget;
      },
    );
  }
}

// 🎯 Modern Button Component
class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isText;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;
  final double borderRadius;

  const ModernButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isText = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.padding,
    this.gradientColors,
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        Widget buttonChild = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOutlined || isText
                        ? AppTheme.primaryColor
                        : Colors.white,
                  ),
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );

        if (gradientColors != null && !isOutlined && !isText) {
          return Container(
            width: width,
            height: height ?? 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: AppTheme.modernElevatedShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : () {
                  if (onPressed != null) {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  }
                },
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  padding: padding ?? const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: buttonChild,
                ),
              ),
            ),
          );
        }

        if (isText) {
          return TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: foregroundColor ?? AppTheme.primaryColor,
              padding: padding ?? const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: buttonChild,
          );
        }

        if (isOutlined) {
          return OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: foregroundColor ?? AppTheme.primaryColor,
              side: BorderSide(
                color: foregroundColor ?? AppTheme.primaryColor,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              padding: padding ?? const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
            child: buttonChild,
          );
        }

        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppTheme.primaryColor,
            foregroundColor: foregroundColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            minimumSize: Size(width ?? 0, height ?? 52),
          ),
          child: buttonChild,
        );
      },
    );
  }
}

// 📱 Modern Text Field Component
class ModernTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final FocusNode? focusNode;

  const ModernTextField({
    Key? key,
    this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
  }) : super(key: key);

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });

    if (hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.label != null) ...[
                    Text(
                      widget.label!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeController.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Focus(
                    onFocusChange: _handleFocusChange,
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      onChanged: widget.onChanged,
                      onFieldSubmitted: widget.onSubmitted,
                      validator: widget.validator,
                      readOnly: widget.readOnly,
                      maxLines: widget.maxLines,
                      maxLength: widget.maxLength,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: themeController.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        helperText: widget.helperText,
                        prefixIcon: widget.prefixIcon != null
                            ? Icon(
                                widget.prefixIcon,
                                color: _isFocused
                                    ? AppTheme.primaryColor
                                    : themeController.textTertiaryColor,
                              )
                            : null,
                        suffixIcon: widget.suffixIcon,
                        filled: true,
                        fillColor: themeController.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: _isFocused
                                ? AppTheme.primaryColor
                                : themeController.isDarkMode
                                    ? const Color(0xFF3A3A3C)
                                    : const Color(0xFFE0E7FF),
                            width: _isFocused ? 2 : 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: themeController.isDarkMode
                                ? const Color(0xFF3A3A3C)
                                : const Color(0xFFE0E7FF),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppTheme.errorColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// 🎚️ Modern Theme Toggle Component
class ModernThemeToggle extends StatelessWidget {
  final bool showLabel;
  final double size;

  const ModernThemeToggle({
    Key? key,
    this.showLabel = true,
    this.size = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GestureDetector(
          onTap: () => themeController.toggleTheme(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeController.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.modernCardShadow,
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    themeController.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    key: ValueKey(themeController.isDarkMode),
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(width: 12),
                  Text(
                    themeController.themeModeDisplayName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeController.textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// 📊 Modern Stat Card Component
class ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? trend;

  const ModernStatCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.gradientColors,
    this.onTap,
    this.showTrend = false,
    this.trend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      gradientColors: gradientColors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              if (showTrend && trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trend! >= 0
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend! >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: trend! >= 0
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trend!.abs()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: trend! >= 0
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GetBuilder<ThemeController>(
            builder: (themeController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: gradientColors != null
                          ? Colors.white
                          : themeController.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: gradientColors != null
                          ? Colors.white.withOpacity(0.8)
                          : themeController.textSecondaryColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: gradientColors != null
                            ? Colors.white.withOpacity(0.6)
                            : themeController.textTertiaryColor,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}