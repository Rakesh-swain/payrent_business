import 'package:flutter/material.dart';
import 'package:payrent_business/screens/tenant/tenant_dashboard_page.dart';
import 'package:payrent_business/screens/tenant/tenant_properties_page.dart';
import 'package:payrent_business/screens/tenant/tenant_payments_page.dart';
import 'package:payrent_business/screens/tenant/tenant_maintenance_page.dart';
import 'package:payrent_business/screens/tenant/tenant_profile_page.dart';
import 'package:payrent_business/widgets/animated_bottom_nav.dart';

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

  final List<AnimatedBottomNavItem> _navItems = [
    AnimatedBottomNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    AnimatedBottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Properties',
    ),
    AnimatedBottomNavItem(
      icon: Icons.payment_outlined,
      activeIcon: Icons.payment,
      label: 'Payments',
    ),
    AnimatedBottomNavItem(
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
      label: 'Maintenance',
    ),
    AnimatedBottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _navItems,
      ),
    );
  }
}