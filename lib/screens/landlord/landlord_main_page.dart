import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/theme_controller.dart';
import 'package:payrent_business/screens/landlord/landlord_dashboard_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_list_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_summary_page.dart';
import 'package:payrent_business/screens/landlord/property_management/manage_properties_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_list_page.dart';
import 'package:payrent_business/screens/profile/user_profile_page.dart';
import 'package:payrent_business/widgets/modern_bottom_nav.dart';

class LandlordMainPage extends StatefulWidget {
  const LandlordMainPage({super.key});

  @override
  State<LandlordMainPage> createState() => _LandlordMainPageState();
}

class _LandlordMainPageState extends State<LandlordMainPage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const LandlordDashboardPage(),
    const ManagePropertiesPage(),
    const PaymentSummaryPage(),
    const TenantListPage(),
    const UserProfilePage(isLandlord: true,),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Properties',
    'Payments',
    'Tenants',
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
                  items: LandlordBottomNavItems.items,
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