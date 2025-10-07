import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme.dart';

class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    this.size = 56,
    this.showLabel = false,
    this.label,
    super.key,
  });

  final double size;
  final bool showLabel;
  final String? label;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decorations = Theme.of(context).extension<AppDecorations>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double rotate = _controller.value * 2 * math.pi;
              return Transform.rotate(
                angle: rotate,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: decorations?.shadows.glow,
                    gradient: SweepGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.secondary,
                        colorScheme.primary,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: widget.size * 0.68,
                      height: widget.size * 0.68,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: widget.size * 0.12,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(colorScheme.onBackground.withOpacity(0.12)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              widget.label ?? 'Loading...'.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}
