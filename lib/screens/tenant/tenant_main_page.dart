import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payrent_business/config/theme.dart';
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Properties',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment_outlined),
              activeIcon: Icon(Icons.payment),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build),
              label: 'Maintenance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          elevation: 0,
        ),
      ),
    );
  }
}