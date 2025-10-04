import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/theme_controller.dart';
import 'package:payrent_business/screens/tenant/tenant_dashboard_page.dart';
import 'package:payrent_business/screens/tenant/tenant_payments_page.dart';
import 'package:payrent_business/screens/tenant/tenant_properties_page.dart';
import 'package:payrent_business/screens/tenant/maintenance_request/maintenance_request_page.dart';
import 'package:payrent_business/screens/profile/user_profile_page.dart';
import 'package:payrent_business/widgets/modern_bottom_nav.dart';

class TenantMainPage extends StatefulWidget {
  const TenantMainPage({super.key});

  @override
  State<TenantMainPage> createState() => _TenantMainPageState();
}

class _TenantMainPageState extends State<TenantMainPage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const TenantDashboardPage(),
    const TenantPropertiesPage(),
    const TenantPaymentsPage(),
    const MaintenanceRequestPage(),
    const UserProfilePage(isLandlord: false),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Properties',
    'Payments',
    'Maintenance',
    'Profile',
  ];
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final isDark = themeController.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          body: Stack(
            children: [
              // Main content with animated page transitions
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey<int>(_selectedIndex),
                  child: _pages[_selectedIndex],
                ),
              ),
              
              // Modern bottom navigation overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ModernBottomNav(
                  currentIndex: _selectedIndex,
                  items: TenantBottomNavItems.items,
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ).animate()
                  .slideY(
                    begin: 1,
                    end: 0,
                    duration: 600.ms,
                    delay: 300.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fadeIn(
                    duration: 500.ms,
                    delay: 300.ms,
                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}