import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/landlord_dashboard_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_summary_page.dart';
import 'package:payrent_business/screens/landlord/property_management/manage_properties_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_list_page.dart';
import 'package:payrent_business/screens/profile/user_profile_page.dart';
import 'package:animate_do/animate_do.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if web/tablet view (>= 600px)
        final bool isWeb = constraints.maxWidth >= 600;
        
        if (isWeb) {
          return _buildWebLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }
  
  Widget _buildMobileLayout() {
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
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Tenants',
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
  
  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          // Sidebar Navigation
          FadeInLeft(
            duration: const Duration(milliseconds: 600),
            child: _buildWebSidebar(),
          ),
          
          // Main Content
          Expanded(
            child: FadeInRight(
              duration: const Duration(milliseconds: 600),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
                child: _pages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWebSidebar() {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
            const Color(0xFF3B82F6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo and Brand
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.home,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Brand Text
                Text(
                  'PayRent',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Business',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSidebarItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    title: 'Dashboard',
                    isSelected: _selectedIndex == 0,
                    onTap: () => _selectPage(0),
                  ),
                  _buildSidebarItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    title: 'Properties',
                    isSelected: _selectedIndex == 1,
                    onTap: () => _selectPage(1),
                  ),
                  _buildSidebarItem(
                    icon: Icons.payment_outlined,
                    activeIcon: Icons.payment,
                    title: 'Payments',
                    isSelected: _selectedIndex == 2,
                    onTap: () => _selectPage(2),
                  ),
                  _buildSidebarItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    title: 'Tenants',
                    isSelected: _selectedIndex == 3,
                    onTap: () => _selectPage(3),
                  ),
                  _buildSidebarItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    title: 'Profile',
                    isSelected: _selectedIndex == 4,
                    onTap: () => _selectPage(4),
                  ),
                ],
              ),
            ),
          ),
          
          // User Info at Bottom
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Landlord',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Admin User',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSidebarItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.white.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isSelected 
                  ? Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}