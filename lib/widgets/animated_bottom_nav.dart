import 'package:flutter/material.dart';
import 'package:payrent_business/config/theme.dart';

class AnimatedBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  AnimatedBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class AnimatedBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<AnimatedBottomNavItem> items;

  const AnimatedBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _bounceAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ),
      );
    }).toList();

    _bounceAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ),
      );
    }).toList();

    // Animate the initially selected item
    if (widget.currentIndex < _controllers.length) {
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Reverse animation for previously selected item
      if (oldWidget.currentIndex < _controllers.length) {
        _controllers[oldWidget.currentIndex].reverse();
      }
      // Forward animation for newly selected item
      if (widget.currentIndex < _controllers.length) {
        _controllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface;
    final selectedColor = isDarkMode ? AppTheme.primaryColorLight : AppTheme.primaryColor;
    final unselectedColor = isDarkMode ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: isDarkMode ? AppTheme.bottomNavShadowDark : AppTheme.bottomNavShadowLight,
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              final isSelected = widget.currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onTap(index);
                    // Add a quick bounce effect
                    _controllers[index].forward().then((_) {
                      if (!isSelected) {
                        _controllers[index].reverse();
                      }
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: _controllers[index],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimations[index].value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Animated Icon with pill background
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Animated pill background
                                if (isSelected)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    width: 56,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: selectedColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                
                                // Icon
                                Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  color: isSelected ? selectedColor : unselectedColor,
                                  size: 24,
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // Label with animated opacity and slide
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              style: TextStyle(
                                color: isSelected ? selectedColor : unselectedColor,
                                fontSize: isSelected ? 12 : 11,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
