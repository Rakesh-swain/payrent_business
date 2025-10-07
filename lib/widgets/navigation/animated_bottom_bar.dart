import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/theme.dart';

class AnimatedNavBarItem {
  const AnimatedNavBarItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
    this.heroTag,
    super.key,
  }) : assert(items.length > 1, 'AnimatedBottomNavBar requires at least two items.');

  final List<AnimatedNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final decorations = Theme.of(context).extension<AppDecorations>();
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = Theme.of(context).textTheme.labelMedium?.color ?? colorScheme.onSurface;

    final double alignment = items.length == 1
        ? 0
        : (currentIndex / (items.length - 1)) * 2 - 1;

    return Hero(
      tag: heroTag ?? 'payrent-nav-bar',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: decorations?.shadows.level2,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: decorations?.surfaceBlur ?? 18, sigmaY: decorations?.surfaceBlur ?? 18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: decorations?.gradients.surface,
                  border: Border.all(color: colorScheme.primary.withOpacity(0.08)),
                ),
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.elasticOut,
                      alignment: Alignment(alignment, 0),
                      child: FractionallySizedBox(
                        widthFactor: 1 / items.length,
                        heightFactor: 0.92,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: decorations?.gradients.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: decorations?.shadows.glow,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (int index = 0; index < items.length; index++)
                          Expanded(
                            child: _AnimatedNavBarTile(
                              item: items[index],
                              isSelected: index == currentIndex,
                              colorScheme: colorScheme,
                              secondaryText: secondaryText,
                              onTap: () => onItemSelected(index),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavBarTile extends StatefulWidget {
  const _AnimatedNavBarTile({
    required this.item,
    required this.isSelected,
    required this.colorScheme,
    required this.secondaryText,
    required this.onTap,
  });

  final AnimatedNavBarItem item;
  final bool isSelected;
  final ColorScheme colorScheme;
  final Color secondaryText;
  final VoidCallback onTap;

  @override
  State<_AnimatedNavBarTile> createState() => _AnimatedNavBarTileState();
}

class _AnimatedNavBarTileState extends State<_AnimatedNavBarTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    if (widget.isSelected) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedNavBarTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 + (_controller.value * 0.08);
          final color = Color.lerp(widget.secondaryText, widget.colorScheme.onPrimary, _controller.value)!;
          final iconData = widget.isSelected && widget.item.activeIcon != null
              ? widget.item.activeIcon
              : widget.item.icon;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: scale,
                curve: Curves.easeOut,
                child: Icon(
                  iconData,
                  color: color,
                  size: 26 + (_controller.value * 4),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Text(
                  widget.item.label,
                  key: ValueKey(widget.isSelected),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: widget.isSelected
                            ? widget.colorScheme.onPrimary
                            : widget.secondaryText.withOpacity(0.9),
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
