import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:payrent_business/controllers/theme_controller.dart';
import 'package:payrent_business/widgets/modern_navigation_bar.dart';
import 'package:payrent_business/screens/tenant/tenant_dashboard_page.dart';
import 'package:payrent_business/screens/tenant/tenant_properties_page.dart';
import 'package:payrent_business/screens/tenant/tenant_payments_page.dart';
import 'package:payrent_business/screens/tenant/tenant_maintenance_page.dart';
import 'package:payrent_business/screens/tenant/tenant_profile_page.dart';

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
    const TenantMaintenancePage(),
    const TenantProfilePage(),
  ];

  final List<ModernNavigationBarItem> _navItems = NavigationItemsExtension.tenantItems;
  
  void _onNavigationItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return Scaffold(
          backgroundColor: themeController.backgroundColor,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.03),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey(_selectedIndex),
              child: _pages[_selectedIndex],
            ),
          ),
          bottomNavigationBar: ModernNavigationBar(
            items: _navItems,
            currentIndex: _selectedIndex,
            onTap: _onNavigationItemTapped,
            showLabels: true,
          ),
        );
      },
    );
  }
}