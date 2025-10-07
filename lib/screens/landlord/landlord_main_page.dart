import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:payrent_business/controllers/theme_controller.dart';
import 'package:payrent_business/widgets/modern_navigation_bar.dart';
import 'package:payrent_business/screens/landlord/landlord_dashboard_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_list_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_summary_page.dart';
import 'package:payrent_business/screens/landlord/property_management/manage_properties_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_list_page.dart';
import 'package:payrent_business/screens/profile/user_profile_page.dart';

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

  final List<ModernNavigationBarItem> _navItems = NavigationItemsExtension.landlordItems;
  
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