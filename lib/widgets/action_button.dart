import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/theme_controller.dart';

class ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final LinearGradient? gradient;
  final VoidCallback onTap;
  final bool isLarge;

  const ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    this.color,
    this.gradient,
    required this.onTap,
    this.isLarge = false,
  }) : super(key: key);

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final isDark = themeController.isDarkMode;
        final buttonSize = widget.isLarge ? 60.0 : 50.0;
        final iconSize = widget.isLarge ? 28.0 : 24.0;
        
        return GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onTap();
          },
          onTapCancel: () => _controller.reverse(),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          gradient: widget.gradient,
                          color: widget.gradient == null
                              ? widget.color?.withOpacity(0.1) ?? 
                                AppTheme.primaryBlue.withOpacity(0.1)
                              : null,
                          borderRadius: BorderRadius.circular(
                            widget.isLarge ? 20 : 16,
                          ),
                          boxShadow: widget.gradient != null 
                              ? AppTheme.modernCardShadow(isDark: isDark)
                              : null,
                          border: isDark 
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                )
                              : null,
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.gradient != null
                              ? Colors.white
                              : widget.color ?? AppTheme.primaryBlue,
                          size: iconSize,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.label,
                        style: AppTheme.bodyMedium(
                          isDark: isDark,
                        ).copyWith(
                          fontSize: widget.isLarge ? 14 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ).animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }
}

// Modern button variants
class PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLarge;

  const PrimaryActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLarge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      icon: icon,
      label: label,
      gradient: AppTheme.primaryGradient,
      onTap: onTap,
      isLarge: isLarge,
    );
  }
}

class TealActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLarge;

  const TealActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLarge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      icon: icon,
      label: label,
      gradient: AppTheme.tealGradient,
      onTap: onTap,
      isLarge: isLarge,
    );
  }
}

class PurpleActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLarge;

  const PurpleActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLarge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionButton(
      icon: icon,
      label: label,
      gradient: AppTheme.purpleGradient,
      onTap: onTap,
      isLarge: isLarge,
    );
  }
}

enum ButtonStyleVariant { filled, outlined, text, gradient }
enum ButtonSizeVariant { small, medium, large }

class ModernElevatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final ButtonStyleVariant buttonStyle;
  final ButtonSizeVariant buttonSize;
  final LinearGradient? gradient;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool expandWidth;

  const ModernElevatedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.buttonStyle = ButtonStyleVariant.filled,
    this.buttonSize = ButtonSizeVariant.medium,
    this.gradient,
    this.leadingIcon,
    this.trailingIcon,
    this.expandWidth = true,
  }) : super(key: key);

  @override
  State<ModernElevatedButton> createState() => _ModernElevatedButtonState();
}

class _ModernElevatedButtonState extends State<ModernElevatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _buttonHeight {
    switch (widget.buttonSize) {
      case ButtonSizeVariant.small:
        return 40;
      case ButtonSizeVariant.medium:
        return 50;
      case ButtonSizeVariant.large:
        return 60;
    }
  }

  double get _fontSize {
    switch (widget.buttonSize) {
      case ButtonSizeVariant.small:
        return 14;
      case ButtonSizeVariant.medium:
        return 16;
      case ButtonSizeVariant.large:
        return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final isDark = themeController.isDarkMode;
        
        return GestureDetector(
          onTapDown: widget.onPressed != null && !widget.isLoading
              ? (_) => _controller.forward()
              : null,
          onTapUp: widget.onPressed != null && !widget.isLoading
              ? (_) {
                  _controller.reverse();
                  widget.onPressed!();
                }
              : null,
          onTapCancel: widget.onPressed != null && !widget.isLoading
              ? () => _controller.reverse()
              : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.expandWidth ? double.infinity : null,
                  height: _buttonHeight,
                  decoration: _getButtonDecoration(isDark),
                  child: Stack(
                    children: [
                      // Ripple effect
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _rippleAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: Colors.white.withOpacity(
                                  0.2 * _rippleAnimation.value,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Button content
                      Center(
                        child: widget.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getTextColor(isDark),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: widget.expandWidth 
                                    ? MainAxisSize.max 
                                    : MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.leadingIcon != null) ...[
                                    Icon(
                                      widget.leadingIcon,
                                      color: _getTextColor(isDark),
                                      size: _fontSize + 2,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    widget.text,
                                    style: AppTheme.bodyMedium(
                                      color: _getTextColor(isDark),
                                    ).copyWith(
                                      fontSize: _fontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (widget.trailingIcon != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      widget.trailingIcon,
                                      color: _getTextColor(isDark),
                                      size: _fontSize + 2,
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ).animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }

  BoxDecoration _getButtonDecoration(bool isDark) {
    switch (widget.buttonStyle) {
      case ButtonStyleVariant.filled:
        return BoxDecoration(
          color: widget.backgroundColor ?? AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(25),
          boxShadow: AppTheme.modernCardShadow(isDark: isDark),
        );
      
      case ButtonStyleVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: widget.backgroundColor ?? AppTheme.primaryBlue,
            width: 2,
          ),
        );
      
      case ButtonStyleVariant.text:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        );
      
      case ButtonStyleVariant.gradient:
        return BoxDecoration(
          gradient: widget.gradient ?? AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: AppTheme.elevatedShadow(isDark: isDark),
        );
    }
  }

  Color _getTextColor(bool isDark) {
    switch (widget.buttonStyle) {
      case ButtonStyleVariant.filled:
        return widget.textColor ?? Colors.white;
      
      case ButtonStyleVariant.outlined:
        return widget.textColor ?? 
               (widget.backgroundColor ?? AppTheme.primaryBlue);
      
      case ButtonStyleVariant.text:
        return widget.textColor ?? 
               (widget.backgroundColor ?? AppTheme.primaryBlue);
      
      case ButtonStyleVariant.gradient:
        return widget.textColor ?? Colors.white;
    }
  }
}