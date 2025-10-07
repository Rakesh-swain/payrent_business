import 'package:flutter/material.dart';
import 'package:payrent_business/screens/landlord/landlord_dashboard_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_list_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_summary_page.dart';
import 'package:payrent_business/screens/landlord/property_management/manage_properties_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_list_page.dart';
import 'package:payrent_business/screens/profile/user_profile_page.dart';
import 'package:payrent_business/widgets/navigation/animated_bottom_bar.dart';

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
        },
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
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Tenants',
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