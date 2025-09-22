// lib/modules/tenant/tenant_main_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/profile/user_profile_page.dart';
import 'package:payrent_business/screens/tenant/maintenance_request/maintenance_request_page.dart';
import 'package:payrent_business/screens/tenant/payment/payment_history_page.dart';
import 'package:payrent_business/screens/tenant/tenant_dashboard_page.dart';
import 'package:payrent_business/screens/tenant/tenant_property_page.dart';

class TenantMainPage extends StatefulWidget {
  const TenantMainPage({super.key});

  @override
  State<TenantMainPage> createState() => _TenantMainPageState();
}

class _TenantMainPageState extends State<TenantMainPage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const TenantDashboardPage(),
    const PaymentHistoryPage(),
    const TenantPropertyPage(),
    const MaintenanceRequestPage(),
    const UserProfilePage(isLandlord: false,),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Payments',
    'My Property',
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
              icon: Icon(Icons.payment_outlined),
              activeIcon: Icon(Icons.payment),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Property',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_repair_service_outlined),
              activeIcon: Icon(Icons.home_repair_service),
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