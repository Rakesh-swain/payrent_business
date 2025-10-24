import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/routes/app_routes.dart';
import 'package:universal_html/html.dart' as html;

// Import all page widgets
import 'package:payrent_business/screens/landlord/landlord_dashboard_page.dart';
import 'package:payrent_business/screens/landlord/property_management/manage_properties_page.dart';
import 'package:payrent_business/screens/landlord/payments/payment_summary_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_list_page.dart';
import 'package:payrent_business/screens/profile/user_profile_page.dart';

import 'package:payrent_business/screens/tenant/tenant_dashboard_page.dart';
import 'package:payrent_business/screens/tenant/tenant_properties_page.dart';
import 'package:payrent_business/screens/tenant/tenant_payments_page.dart';
import 'package:payrent_business/screens/tenant/tenant_maintenance_page.dart';
import 'package:payrent_business/screens/tenant/tenant_profile_page.dart';

import 'package:payrent_business/screens/web/widgets/web_sidebar.dart';
import 'package:payrent_business/screens/web/widgets/web_topbar.dart';
import 'package:payrent_business/screens/landlord/complaints/complaint_list_page.dart';

class WebMainPage extends StatefulWidget {
  final String userType;
  final String? initialRoute;

  const WebMainPage({
    super.key,
    required this.userType,
    this.initialRoute,
  });

  @override
  State<WebMainPage> createState() => _WebMainPageState();
}

class _WebMainPageState extends State<WebMainPage> {
  late String _selectedRoute;
  bool _sidebarCollapsed = true; // Start with sidebar collapsed on mobile

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.initialRoute ?? 'dashboard';
    _updatePageTitle();
  }

  void _updatePageTitle() {
    if (kIsWeb) {
      final title = _getPageTitle(_selectedRoute);
      html.document.title = 'PayRent - $title';
    }
  }

  String _getPageTitle(String route) {
    final routeTitles = {
      'dashboard': 'Dashboard',
      'properties': 'Properties',
      'payments': 'Payments',
      'tenants': 'Tenants',
      'complaints': 'Complaints',
      'maintenance': 'Maintenance',
      'profile': 'Profile',
    };
    return routeTitles[route] ?? 'Dashboard';
  }

  void _onRouteSelected(String route) {
    setState(() {
      _selectedRoute = route;
    });
    _updatePageTitle();
    
    // Update browser URL
    final fullRoute = widget.userType == 'Landlord' 
        ? '/landlord/$route' 
        : '/tenant/$route';
    
    if (kIsWeb) {
      html.window.history.pushState({}, '', fullRoute);
    }
  }

  Widget _getCurrentPage() {
    if (widget.userType == 'Landlord') {
      switch (_selectedRoute) {
        case 'dashboard':
          return const LandlordDashboardPage();
        case 'properties':
          return const ManagePropertiesPage();
        case 'payments':
          return const PaymentSummaryPage();
        case 'tenants':
          return const TenantListPage();
        case 'complaints':
          return const ComplaintListPage();
        case 'profile':
          return const UserProfilePage(isLandlord: true);
        default:
          return const LandlordDashboardPage();
      }
    } else {
      switch (_selectedRoute) {
        case 'dashboard':
          return const TenantDashboardPage();
        case 'properties':
          return const TenantPropertiesPage();
        case 'payments':
          return const TenantPaymentsPage();
        case 'maintenance':
          return const TenantMaintenancePage();
        case 'profile':
          return const TenantProfilePage();
        default:
          return const TenantDashboardPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use sidebar for desktop/tablet, bottom navigation for mobile
        if (constraints.maxWidth >= 1400) {
          return _buildWideDesktopLayout();
        } else if (constraints.maxWidth >= 1024) {
          return _buildStandardDesktopLayout();
        } else if (constraints.maxWidth >= 700) {
          return _buildTabletSidebarLayout();
        } else {
          return _buildMobileBottomNavLayout(); // Back to bottom navigation for mobile
        }
      },
    );
  }

  Widget _buildWideDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Fixed sidebar
          WebSidebar(
            userType: widget.userType,
            selectedRoute: _selectedRoute,
            onRouteSelected: _onRouteSelected,
            isCollapsed: false,
            width: 280,
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                WebTopbar(
                  title: _getPageTitle(_selectedRoute),
                  userType: widget.userType,
                  showMenuButton: false,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: _getCurrentPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardDesktopLayout() {
    final sidebarWidth = _sidebarCollapsed ? 80.0 : 240.0;
    
    return Scaffold(
      body: Row(
        children: [
          // Collapsible sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: sidebarWidth,
            child: WebSidebar(
              userType: widget.userType,
              selectedRoute: _selectedRoute,
              onRouteSelected: _onRouteSelected,
              isCollapsed: _sidebarCollapsed,
              width: sidebarWidth,
            ),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                WebTopbar(
                  title: _getPageTitle(_selectedRoute),
                  userType: widget.userType,
                  showMenuButton: true,
                  onMenuPressed: () {
                    setState(() {
                      _sidebarCollapsed = !_sidebarCollapsed;
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: _getCurrentPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New tablet layout with permanent sidebar (no drawer)
  Widget _buildTabletSidebarLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Fixed sidebar for tablet
          WebSidebar(
            userType: widget.userType,
            selectedRoute: _selectedRoute,
            onRouteSelected: _onRouteSelected,
            isCollapsed: false,
            width: 200,
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                WebTopbar(
                  title: _getPageTitle(_selectedRoute),
                  userType: widget.userType,
                  showMenuButton: false, // No menu button needed
                  isMobile: true,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: _getCurrentPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile layout with traditional bottom navigation
  Widget _buildMobileBottomNavLayout() {
    final landlordBottomNavItems = [
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
    ];

    final tenantBottomNavItems = [
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
    ];

    final routes = widget.userType == 'Landlord' 
        ? ['dashboard', 'properties', 'payments', 'tenants', 'profile']
        : ['dashboard', 'properties', 'payments', 'maintenance', 'profile'];
    
    final currentIndex = routes.indexOf(_selectedRoute).clamp(0, routes.length - 1);

    return Scaffold(
      body: Column(
        children: [
          // Simple mobile top bar
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.home,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      _getPageTitle(_selectedRoute),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Notifications
                  IconButton(
                    onPressed: () {},
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined, size: 24),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _getCurrentPage(),
            ),
          ),
        ],
      ),
      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        items: widget.userType == 'Landlord' ? landlordBottomNavItems : tenantBottomNavItems,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        elevation: 10,
        onTap: (index) {
          _onRouteSelected(routes[index]);
        },
      ),
    );
  }
}