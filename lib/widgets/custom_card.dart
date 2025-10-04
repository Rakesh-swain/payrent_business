import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/theme_controller.dart';

class CustomCard extends StatefulWidget {
  final String? title;
  final Widget child;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final bool useGlassMorphism;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool showTitleDivider;
  final Widget? titleSuffix;

  const CustomCard({
    Key? key,
    this.title,
    required this.child,
    this.gradient,
    this.backgroundColor,
    this.useGlassMorphism = false,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.showTitleDivider = false,
    this.titleSuffix,
  }) : super(key: key);

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
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
        
        return GestureDetector(
          onTapDown: widget.onTap != null 
              ? (_) {
                  setState(() => _isPressed = true);
                  _controller.forward();
                }
              : null,
          onTapUp: widget.onTap != null 
              ? (_) {
                  setState(() => _isPressed = false);
                  _controller.reverse();
                  widget.onTap!();
                }
              : null,
          onTapCancel: widget.onTap != null 
              ? () {
                  setState(() => _isPressed = false);
                  _controller.reverse();
                }
              : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: double.infinity,
                  decoration: widget.useGlassMorphism
                      ? AppTheme.glassCard(isDark: isDark)
                      : BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: widget.gradient,
                          color: widget.gradient == null 
                              ? widget.backgroundColor ?? 
                                (isDark ? AppTheme.darkCardBg : Colors.white)
                              : null,
                          boxShadow: AppTheme.modernCardShadow(isDark: isDark),
                          border: isDark 
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                )
                              : null,
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null) ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            widget.padding.left,
                            widget.padding.top,
                            widget.padding.right,
                            widget.showTitleDivider ? 8 : 0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title!,
                                  style: AppTheme.titleLarge(
                                    color: widget.gradient != null 
                                        ? Colors.white
                                        : null,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              if (widget.titleSuffix != null)
                                widget.titleSuffix!,
                            ],
                          ),
                        ),
                        if (widget.showTitleDivider)
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: widget.padding.left,
                              vertical: 8,
                            ),
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  (widget.gradient != null 
                                      ? Colors.white 
                                      : isDark 
                                          ? AppTheme.darkTextTertiary 
                                          : AppTheme.lightTextTertiary
                                  ).withOpacity(0.1),
                                  (widget.gradient != null 
                                      ? Colors.white 
                                      : isDark 
                                          ? AppTheme.darkTextTertiary 
                                          : AppTheme.lightTextTertiary
                                  ).withOpacity(0.5),
                                  (widget.gradient != null 
                                      ? Colors.white 
                                      : isDark 
                                          ? AppTheme.darkTextTertiary 
                                          : AppTheme.lightTextTertiary
                                  ).withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                      ],
                      Padding(
                        padding: widget.title != null 
                            ? EdgeInsets.fromLTRB(
                                widget.padding.left,
                                widget.showTitleDivider ? 8 : 0,
                                widget.padding.right,
                                widget.padding.bottom,
                              )
                            : widget.padding,
                        child: widget.child,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ).animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }
}

// Specialized cards for different use cases
class GradientCard extends StatelessWidget {
  final String title;
  final Widget child;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const GradientCard({
    Key? key,
    required this.title,
    required this.child,
    required this.gradient,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      title: title,
      gradient: gradient,
      onTap: onTap,
      child: child,
    );
  }
}

class GlassCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final VoidCallback? onTap;

  const GlassCard({
    Key? key,
    this.title,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      title: title,
      useGlassMorphism: true,
      onTap: onTap,
      child: child,
    );
  }
}