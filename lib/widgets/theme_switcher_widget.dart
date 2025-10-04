import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/theme_controller.dart';

class ThemeSwitcherWidget extends StatelessWidget {
  const ThemeSwitcherWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: isDarkMode ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDarkMode ? AppTheme.primaryColorLight : AppTheme.primaryColor)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  color: isDarkMode ? AppTheme.primaryColorLight : AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Choose your preferred theme',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Theme Options
          Obx(() {
            return Column(
              children: [
                _buildThemeOption(
                  context: context,
                  title: 'Light',
                  subtitle: 'Use light theme',
                  icon: Icons.light_mode,
                  isSelected: themeController.themeMode == ThemeMode.light,
                  onTap: () => themeController.setLightMode(),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildThemeOption(
                  context: context,
                  title: 'Dark',
                  subtitle: 'Use dark theme',
                  icon: Icons.dark_mode,
                  isSelected: themeController.themeMode == ThemeMode.dark,
                  onTap: () => themeController.setDarkMode(),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildThemeOption(
                  context: context,
                  title: 'System',
                  subtitle: 'Follow system settings',
                  icon: Icons.brightness_auto,
                  isSelected: themeController.themeMode == ThemeMode.system,
                  onTap: () => themeController.setSystemMode(),
                  isDarkMode: isDarkMode,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    final selectedColor = isDarkMode ? AppTheme.primaryColorLight : AppTheme.primaryColor;
    final backgroundColor = isDarkMode ? AppTheme.darkBackground : AppTheme.lightBackground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected 
              ? selectedColor.withOpacity(0.12) 
              : backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected 
                ? selectedColor 
                : (isDarkMode ? AppTheme.darkDivider : AppTheme.lightDivider),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? selectedColor.withOpacity(0.2) 
                    : (isDarkMode 
                        ? AppTheme.darkDivider 
                        : AppTheme.lightDivider).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? selectedColor 
                    : (isDarkMode 
                        ? AppTheme.darkTextSecondary 
                        : AppTheme.lightTextSecondary),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected 
                          ? selectedColor 
                          : (isDarkMode 
                              ? AppTheme.darkTextPrimary 
                              : AppTheme.lightTextPrimary),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // Selected Indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: selectedColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
