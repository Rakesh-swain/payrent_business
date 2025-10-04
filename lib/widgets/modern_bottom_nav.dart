import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/theme_controller.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const ModernBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final isDark = themeController.isDarkMode;
        
        return Container(
          height: 80,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: AppTheme.modernBottomNavShadow(isDark: isDark),
            border: isDark 
                ? Border.all(color: Colors.white.withOpacity(0.1))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == currentIndex;
                
                return Expanded(
                  child: _NavItem(
                    item: item,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => onTap(index),
                    animationDelay: Duration(milliseconds: index * 50),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final Duration animationDelay;

  const _NavItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.animationDelay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: isSelected ? item.gradient : null,
          color: !isSelected 
              ? Colors.transparent 
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected 
                    ? Colors.white
                    : isDark 
                        ? AppTheme.darkTextSecondary 
                        : AppTheme.lightTextSecondary,
                size: 22,
              ),
            ),
            
            // Animated label
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 65),
                        child: Text(
                          item.label,
                          style: AppTheme.bodyMedium(
                            color: Colors.white,
                          ).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ).animate()
                        .fadeIn(duration: 200.ms, delay: 100.ms)
                        .slideX(begin: 0.3, end: 0, duration: 300.ms),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ).animate(delay: animationDelay)
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 300.ms),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final LinearGradient gradient;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.gradient,
  });
}

// Predefined navigation items for landlords
class LandlordBottomNavItems {
  static List<BottomNavItem> get items => [
    BottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      gradient: AppTheme.primaryGradient,
    ),
    BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Properties',
      gradient: AppTheme.tealGradient,
    ),
    BottomNavItem(
      icon: Icons.payment_outlined,
      activeIcon: Icons.payment,
      label: 'Payments',
      gradient: AppTheme.purpleGradient,
    ),
    BottomNavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Tenants',
      gradient: AppTheme.successGradient,
    ),
    BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      gradient: AppTheme.warningGradient,
    ),
  ];
}

// Predefined navigation items for tenants
class TenantBottomNavItems {
  static List<BottomNavItem> get items => [
    BottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      gradient: AppTheme.primaryGradient,
    ),
    BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Property',
      gradient: AppTheme.tealGradient,
    ),
    BottomNavItem(
      icon: Icons.payment_outlined,
      activeIcon: Icons.payment,
      label: 'Payments',
      gradient: AppTheme.purpleGradient,
    ),
    BottomNavItem(
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
      label: 'Maintenance',
      gradient: AppTheme.warningGradient,
    ),
    BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      gradient: AppTheme.successGradient,
    ),
  ];
}