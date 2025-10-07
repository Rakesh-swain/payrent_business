import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/services/tenant_auth_service.dart';
import 'package:payrent_business/widgets/stat_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payrent_business/widgets/common/app_loading_indicator.dart';

class TenantDashboardPage extends StatefulWidget {
  const TenantDashboardPage({super.key});

  @override
  State<TenantDashboardPage> createState() => _TenantDashboardPageState();
}

class _TenantDashboardPageState extends State<TenantDashboardPage> {
  final TenantAuthService _tenantAuthService = TenantAuthService();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  
  // Dashboard data
  bool _isLoading = true;
  String _tenantName = '';
  Map<String, dynamic> _dashboardStats = {
    'totalRentAmount': 0.0,
    'amountPaid': 0.0,
    'amountDue': 0.0,
    'overdueAmount': 0.0,
  };
  List<Map<String, dynamic>> _recentPayments = [];
  List<Map<String, dynamic>> _assignedProperties = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);
      
      // Get tenant info from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final tenantId = prefs.getString('tenantId') ?? '';
      final landlordId = prefs.getString('landlordId') ?? '';
      
      if (tenantId.isEmpty || landlordId.isEmpty) {
        print('Tenant or landlord ID not found');
        setState(() => _isLoading = false);
        return;
      }
      
      // Fetch tenant full data
      final tenantData = await _tenantAuthService.getTenantFullData(landlordId, tenantId);
      if (tenantData != null) {
        setState(() {
          _tenantName = tenantData['name'] ?? 'Tenant';
          _assignedProperties = List<Map<String, dynamic>>.from(
            tenantData['assignedProperties'] ?? []
          );
        });
      }
      
      // Fetch dashboard statistics
      final stats = await _tenantAuthService.getTenantDashboardStats(landlordId, tenantId);
      setState(() {
        _dashboardStats = stats;
      });
      
      // Fetch recent payment history
      final payments = await _tenantAuthService.getTenantPaymentHistory(landlordId, tenantId);
      setState(() {
        _recentPayments = payments.take(5).toList(); // Show only 5 recent payments
      });
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 28),
            onPressed: () {
              // Handle notifications
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wb_sunny_rounded,
                            color: Color(0xFFFCD34D),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Good ${_getGreeting()}, $_tenantName!',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'Here\'s your rent overview',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Stat Cards
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 200),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          StatCard(
                            title: 'Total Rent',
                            value: currencyFormat.format(_dashboardStats['totalRentAmount']),
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          StatCard(
                            title: 'Amount Paid',
                            value: currencyFormat.format(_dashboardStats['amountPaid']),
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF10B981),
                          ),
                          StatCard(
                            title: 'Amount Due',
                            value: currencyFormat.format(_dashboardStats['amountDue']),
                            icon: Icons.pending_outlined,
                            color: const Color(0xFFF59E0B),
                          ),
                          StatCard(
                            title: 'Overdue',
                            value: currencyFormat.format(_dashboardStats['overdueAmount']),
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // My Properties Section
                    if (_assignedProperties.isNotEmpty) ...[
                      FadeInLeft(
                        duration: const Duration(milliseconds: 700),
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          'My Properties',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._assignedProperties.map((property) => FadeInUp(
                        duration: const Duration(milliseconds: 700),
                        delay: Duration(milliseconds: 400 + (_assignedProperties.indexOf(property) * 100)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.home,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      property['propertyName'] ?? property['address'] ?? 'Property',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (property['unitNumber'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Unit ${property['unitNumber']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      '${property['city']}, ${property['state']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Monthly Rent',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormat.format(property['rentAmount'] ?? 0),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                      const SizedBox(height: 32),
                    ],
                    
                    // Recent Payments Section
                    if (_recentPayments.isNotEmpty) ...[
                      FadeInLeft(
                        duration: const Duration(milliseconds: 700),
                        delay: const Duration(milliseconds: 400),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Payments',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to payments page - tab index 2
                                final scaffold = context.findAncestorStateOfType<ScaffoldState>();
                                if (scaffold != null && scaffold.widget.bottomNavigationBar != null) {
                                  // Switch to payments tab
                                }
                              },
                              child: Text(
                                'View All',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._recentPayments.map((payment) {
                        final status = payment['status'] ?? 'pending';
                        final dueDate = payment['dueDate'] != null
                            ? DateFormat('dd MMM yyyy').format(payment['dueDate'].toDate())
                            : 'N/A';
                        
                        return FadeInUp(
                          duration: const Duration(milliseconds: 700),
                          delay: Duration(milliseconds: 500 + (_recentPayments.indexOf(payment) * 100)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getStatusIcon(status),
                                    color: _getStatusColor(status),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Due: $dueDate',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(payment['amount'] ?? 0),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'overdue':
        return const Color(0xFFEF4444);
      default:
        return AppTheme.textSecondary;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.access_time;
      case 'overdue':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }
}