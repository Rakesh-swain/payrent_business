import 'package:flutter/material.dart';
import 'package:payrent_business/screens/tenant/tenant_dashboard_page.dart';
import 'package:payrent_business/screens/tenant/tenant_properties_page.dart';
import 'package:payrent_business/screens/tenant/tenant_payments_page.dart';
import 'package:payrent_business/screens/tenant/tenant_maintenance_page.dart';
import 'package:payrent_business/screens/tenant/tenant_profile_page.dart';
import 'package:payrent_business/widgets/navigation/animated_bottom_bar.dart';

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

  final List<String> _titles = [
    'Dashboard',
    'Properties',
    'Payments',
    'Maintenance',
    'Profile',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
        items: const [
          AnimatedNavBarItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
          ),
          AnimatedNavBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Properties',
          ),
          AnimatedNavBarItem(
            icon: Icons.payment_outlined,
            activeIcon: Icons.payments,
            label: 'Payments',
          ),
          AnimatedNavBarItem(
            icon: Icons.build_outlined,
            activeIcon: Icons.handyman,
            label: 'Maintenance',
          ),
          AnimatedNavBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}