import 'package:flutter/material.dart';
import 'package:payrent_business/config/theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final bool isGradient;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.isGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDarkMode ? AppTheme.primaryColorLight : AppTheme.primaryColor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: isDarkMode ? AppTheme.cardShadowDark : AppTheme.cardShadowLight,
        gradient: isGradient ? LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isGradient 
                        ? Colors.white.withOpacity(0.9) 
                        : (isDarkMode 
                            ? AppTheme.darkTextSecondary 
                            : AppTheme.lightTextSecondary),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGradient 
                      ? Colors.white.withOpacity(0.2)
                      : cardColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isGradient ? Colors.white : cardColor,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: isGradient 
                  ? Colors.white 
                  : (isDarkMode 
                      ? AppTheme.darkTextPrimary 
                      : AppTheme.lightTextPrimary),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isGradient 
                    ? Colors.white.withOpacity(0.8) 
                    : (isDarkMode 
                        ? AppTheme.darkTextSecondary 
                        : AppTheme.lightTextSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}