// lib/widgets/modern_navigation_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:payrent_business/controllers/theme_controller.dart';
import 'package:payrent_business/config/theme.dart';

class ModernNavigationBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const ModernNavigationBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

class ModernNavigationBar extends StatefulWidget {
  final List<ModernNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showLabels;

  const ModernNavigationBar({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
  }) : super(key: key);

  @override
  State<ModernNavigationBar> createState() => _ModernNavigationBarState();
}

class _ModernNavigationBarState extends State<ModernNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.1),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _indicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == widget.currentIndex) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Bounce animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Slide and indicator animation
    _slideController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _slideController.reverse();
      });
    });

    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return Container(
          decoration: BoxDecoration(
            color: themeController.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: themeController.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: themeController.isDarkMode
                    ? Colors.black.withOpacity(0.1)
                    : Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, -2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Container(
              height: 85,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Stack(
                children: [
                  // Sliding active indicator background
                  AnimatedBuilder(
                    animation: _indicatorAnimation,
                    builder: (context, child) {
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: _calculateIndicatorPosition(),
                        top: 8,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _getItemWidth(),
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.15),
                                AppTheme.primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Navigation items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: widget.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isSelected = index == widget.currentIndex;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onItemTapped(index),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _scaleAnimation,
                              _slideAnimation,
                            ]),
                            builder: (context, child) {
                              return Transform.scale(
                                scale: isSelected && _animationController.isAnimating
                                    ? _scaleAnimation.value
                                    : 1.0,
                                child: SlideTransition(
                                  position: isSelected && _slideController.isAnimating
                                      ? _slideAnimation
                                      : AlwaysStoppedAnimation(Offset.zero),
                                  child: _buildNavItem(
                                    item,
                                    isSelected,
                                    themeController,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    ModernNavigationBarItem item,
    bool isSelected,
    ThemeController themeController,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: Icon(
              isSelected ? item.activeIcon : item.icon,
              key: ValueKey(isSelected),
              size: 24,
              color: isSelected
                  ? AppTheme.primaryColor
                  : themeController.textTertiaryColor,
            ),
          ),

          const SizedBox(height: 4),

          // Label with slide animation
          if (widget.showLabels)
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryColor
                    : themeController.textTertiaryColor,
                letterSpacing: 0.2,
              ),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  double _calculateIndicatorPosition() {
    final itemWidth = _getItemWidth();
    final totalPadding = 16.0; // 8px padding on each side
    final availableWidth = MediaQuery.of(context).size.width - totalPadding;
    final spacing = (availableWidth - (widget.items.length * itemWidth)) / (widget.items.length - 1);
    
    return 8 + (widget.currentIndex * (itemWidth + spacing));
  }

  double _getItemWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalPadding = 16.0;
    final availableWidth = screenWidth - totalPadding;
    return availableWidth / widget.items.length;
  }
}

// Extension for easy creation of navigation items
extension NavigationItemsExtension on List<ModernNavigationBarItem> {
  static List<ModernNavigationBarItem> landlordItems = [
    const ModernNavigationBarItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/landlord/dashboard',
    ),
    const ModernNavigationBarItem(
      icon: Icons.home_work_outlined,
      activeIcon: Icons.home_work_rounded,
      label: 'Properties',
      route: '/landlord/properties',
    ),
    const ModernNavigationBarItem(
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
      label: 'Payments',
      route: '/landlord/payments',
    ),
    const ModernNavigationBarItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: 'Tenants',
      route: '/landlord/tenants',
    ),
    const ModernNavigationBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      route: '/landlord/profile',
    ),
  ];

  static List<ModernNavigationBarItem> tenantItems = [
    const ModernNavigationBarItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/tenant/dashboard',
    ),
    const ModernNavigationBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Property',
      route: '/tenant/property',
    ),
    const ModernNavigationBarItem(
      icon: Icons.payment_outlined,
      activeIcon: Icons.payment_rounded,
      label: 'Payments',
      route: '/tenant/payments',
    ),
    const ModernNavigationBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      route: '/tenant/profile',
    ),
  ];
}