import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/theme.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    required this.child,
    this.padding,
    this.margin,
    this.radius = 28,
    this.gradient,
    this.onTap,
    this.border,
    this.isInteractive = false,
    super.key,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double radius;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final bool isInteractive;

  @override
  Widget build(BuildContext context) {
    final decorations = Theme.of(context).extension<AppDecorations>();
    final surfaceGradient = gradient ?? decorations?.gradients.surface;

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: surfaceGradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.06)),
        boxShadow: decorations?.shadows.level1,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: decorations?.surfaceBlur ?? 18,
            sigmaY: decorations?.surfaceBlur ?? 18,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.82),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (isInteractive) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
