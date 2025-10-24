import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/routes/app_routes.dart';
import 'package:payrent_business/controllers/auth_controller.dart';
import 'package:payrent_business/widgets/logout_dialog.dart';

class WebSidebar extends StatelessWidget {
  final String userType;
  final String selectedRoute;
  final Function(String) onRouteSelected;
  final bool isCollapsed;
  final double width;
  final bool isMobile;

  const WebSidebar({
    super.key,
    required this.userType,
    required this.selectedRoute,
    required this.onRouteSelected,
    required this.isCollapsed,
    required this.width,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final landlordMenuItems = [
      SidebarMenuItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        route: 'dashboard',
      ),
      SidebarMenuItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Properties',
        route: 'properties',
      ),
      SidebarMenuItem(
        icon: Icons.payment_outlined,
        activeIcon: Icons.payment,
        label: 'Payments',
        route: 'payments',
      ),
      SidebarMenuItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Tenants',
        route: 'tenants',
      ),
      SidebarMenuItem(
        icon: Icons.report_problem_outlined,
        activeIcon: Icons.report_problem,
        label: 'Complaints',
        route: 'complaints',
      ),
      SidebarMenuItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        route: 'profile',
      ),
    ];

    final tenantMenuItems = [
      SidebarMenuItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        route: 'dashboard',
      ),
      SidebarMenuItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Properties',
        route: 'properties',
      ),
      SidebarMenuItem(
        icon: Icons.payment_outlined,
        activeIcon: Icons.payment,
        label: 'Payments',
        route: 'payments',
      ),
      SidebarMenuItem(
        icon: Icons.build_outlined,
        activeIcon: Icons.build,
        label: 'Maintenance',
        route: 'maintenance',
      ),
      SidebarMenuItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        route: 'profile',
      ),
    ];

    final menuItems = userType == 'Landlord' ? landlordMenuItems : tenantMenuItems;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile ? const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ) : BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isMobile ? 0.15 : 0.05),
            blurRadius: isMobile ? 15 : 10,
            spreadRadius: isMobile ? 3 : 0,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo section with improved mobile spacing
          // _buildLogoSection(),
          
          // Divider after logo for mobile
          if (isMobile) 
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: 1,
              color: Colors.grey[200],
            ),
          
          SizedBox(height: isMobile ? 12 : 24),
          
          // Menu items with mobile-optimized padding
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 4 : (isMobile ? 20 : 16)
              ),
              children: menuItems.map((item) => _buildMenuItem(item)).toList(),
            ),
          ),
          
          // User section and logout
          // _buildUserSection(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Row(
        mainAxisAlignment: 
            isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 12 : 8),
            ),
            child: Icon(
              Icons.home,
              color: AppTheme.primaryColor,
              size: isCollapsed ? 24 : (isMobile ? 32 : 28),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Text(
              'PayRent',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 22 : 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(SidebarMenuItem item) {
    final isSelected = selectedRoute == item.route;
    
    if (isCollapsed) {
      // Simplified collapsed item to avoid overflow
      return Container(
        margin: EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onRouteSelected(item.route),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryColor.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Expanded item for normal and mobile views
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 6 : 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onRouteSelected(item.route),
          borderRadius: BorderRadius.circular(isMobile ? 14 : 12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 18 : 16,
              vertical: isMobile ? 16 : 14,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.primaryColor.withOpacity(0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(isMobile ? 14 : 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : Colors.grey[600],
                  size: isMobile ? 26 : 24,
                ),
                SizedBox(width: isMobile ? 18 : 16),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 15,
                      fontWeight: isSelected 
                          ? FontWeight.w600 
                          : FontWeight.w500,
                      color: isSelected 
                          ? AppTheme.primaryColor 
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // User info
          if (!isCollapsed) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userType,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Active Account',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Logout button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutDialog(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 12 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: isCollapsed 
                      ? MainAxisAlignment.center 
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.red[600],
                      size: 20,
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      const LogoutDialog(),
      barrierDismissible: true,
    );
  }
}

class SidebarMenuItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  SidebarMenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}