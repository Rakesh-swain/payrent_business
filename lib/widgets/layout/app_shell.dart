import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../config/theme.dart';
import '../../config/theme_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _waveAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      final themeController = Get.find<ThemeController>();
      themeController.updateBrightness(SchedulerBinding.instance.platformDispatcher.platformBrightness);
    });
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: decorations?.gradients.surface,
      ),
      child: Stack(
        children: [
          if (decorations != null) ...[
            _FloatingBlob(
              animation: _waveAnimation,
              alignment: const Alignment(-1.15, -0.95),
              baseSize: const Size(220, 220),
              colors: [
                colorScheme.primary.withOpacity(0.2),
                colorScheme.secondary.withOpacity(0.14),
              ],
              blurSigma: decorations.surfaceBlur,
            ),
            _FloatingBlob(
              animation: ReverseAnimation(_waveAnimation),
              alignment: const Alignment(1.1, 0.85),
              baseSize: const Size(300, 300),
              colors: [
                colorScheme.tertiary.withOpacity(0.16),
                colorScheme.primary.withOpacity(0.12),
              ],
              blurSigma: decorations.surfaceBlur * 1.3,
            ),
          ],
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: DecoratedBox(
                key: ValueKey(widget.child.hashCode),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                ),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBlob extends StatelessWidget {
  const _FloatingBlob({
    required this.animation,
    required this.alignment,
    required this.baseSize,
    required this.colors,
    required this.blurSigma,
  });

  final Animation<double> animation;
  final Alignment alignment;
  final Size baseSize;
  final List<Color> colors;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = 1 + (math.sin(animation.value * math.pi) * 0.08);
        final offsetX = math.sin(animation.value * math.pi * 2) * 12;
        final offsetY = math.cos(animation.value * math.pi * 2) * 18;

        return Align(
          alignment: alignment,
          child: Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: baseSize.width,
        height: baseSize.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(baseSize.width / 2),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.4),
              blurRadius: blurSigma,
              spreadRadius: blurSigma / 6,
            ),
          ],
        ),
      ),
    );
  }
}
