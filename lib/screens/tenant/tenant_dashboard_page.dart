import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/tenant_data_controller.dart';
import 'package:payrent_business/screens/tenant/payment/make_payment_page.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class TenantDashboardPage extends StatefulWidget {
  const TenantDashboardPage({super.key});

  @override
  State<TenantDashboardPage> createState() => _TenantDashboardPageState();
}

class _TenantDashboardPageState extends State<TenantDashboardPage> {
  late TenantDataController _tenantController;

  @override
  void initState() {
    super.initState();
    _tenantController = Get.find<TenantDataController>();
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
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => _tenantController.refreshTenantData(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: AppTheme.textPrimary,
                    ),
                    const SizedBox(width: 12),
                    Text('Settings', style: GoogleFonts.poppins(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      size: 18,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (_tenantController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_tenantController.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading data',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _tenantController.errorMessage.value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _tenantController.refreshTenantData(),
                  child: Text('Retry', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _tenantController.refreshTenantData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                FadeInDown(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    'Hello, ${_tenantController.tenantFullName.split(' ').first}!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Property Info
                FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: _buildPropertyInfo(),
                ),

                const SizedBox(height: 24),

                // Next Payment Card
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: _buildNextPaymentCard(),
                ),

                const SizedBox(height: 24),

                // Statistics Row
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: _buildStatisticsRow(),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                FadeInDown(
                  duration: const Duration(milliseconds: 700),
                  child: _buildQuickActions(),
                ),

                const SizedBox(height: 24),

                // Recent Payments
                _buildSectionHeader('Recent Payments', onViewAll: () {
                  // Navigate to payment history
                }),

                const SizedBox(height: 12),

                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: _buildRecentPayments(),
                ),

                const SizedBox(height: 24),

                // Maintenance Requests
                _buildSectionHeader('Maintenance Requests', onViewAll: () {
                  // Navigate to maintenance requests
                }),

                const SizedBox(height: 12),

                FadeInUp(
                  duration: const Duration(milliseconds: 900),
                  child: _buildMaintenanceRequests(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPropertyInfo() {
    final primaryProperty = _tenantController.primaryProperty;
    if (primaryProperty == null) return const SizedBox.shrink();

    final propertyData = primaryProperty['propertyData'] as Map<String, dynamic>;
    final unitDetails = primaryProperty['unitDetails'] as Map<String, dynamic>?;

    return Row(
      children: [
        const Icon(
          Icons.home_outlined,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            unitDetails != null
                ? '${propertyData['name']} - Unit ${unitDetails['unitNumber']}'
                : propertyData['name'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        if (_tenantController.hasMultipleProperties)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${_tenantController.totalProperties.value - 1} more',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNextPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Payment',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        '\$${NumberFormat('#,##0.00').format(_tenantController.nextPaymentAmount.value)}',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Obx(() => Text(
                      _tenantController.nextPaymentDate.value.isNotEmpty
                          ? _tenantController.nextPaymentDate.value
                          : 'No pending payments',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_tenantController.nextPaymentAmount.value > 0) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MakePaymentPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Make Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'All payments up to date',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.home_outlined,
            label: 'Properties',
            value: _tenantController.totalProperties.value.toString(),
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => _buildStatCard(
                icon: Icons.payment_outlined,
                label: 'Pending Payments',
                value: _tenantController.pendingPaymentsCount.value.toString(),
                color: _tenantController.pendingPaymentsCount.value > 0
                    ? AppTheme.errorColor
                    : AppTheme.successColor,
              )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => _buildStatCard(
                icon: Icons.attach_money,
                label: 'Total Rent',
                value: '\$${NumberFormat('#,##0').format(_tenantController.totalRentAmount.value)}',
                color: AppTheme.infoColor,
              )),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickAction(
              icon: Icons.home_repair_service_outlined,
              label: 'Request\\nMaintenance',
              onTap: () {
                // Navigate to maintenance request page
              },
            ),
            _buildQuickAction(
              icon: Icons.receipt_long_outlined,
              label: 'View\\nDocuments',
              onTap: () {
                // Navigate to documents page
              },
            ),
            _buildQuickAction(
              icon: Icons.history_outlined,
              label: 'Payment\\nHistory',
              onTap: () {
                // Navigate to payment history page
              },
            ),
            _buildQuickAction(
              icon: Icons.message_outlined,
              label: 'Message\\nLandlord',
              onTap: () {
                // Navigate to messaging page
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'View All',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentPayments() {
    return Obx(() {
      if (_tenantController.paymentHistory.isEmpty) {
        return _buildEmptyState(
          icon: Icons.payment_outlined,
          title: 'No payments yet',
          subtitle: 'Your payment history will appear here',
        );
      }

      final recentPayments = _tenantController.paymentHistory.take(3).toList();

      return Column(
        children: recentPayments.map((payment) {
          final paymentData = payment['paymentData'] as Map<String, dynamic>;
          return _buildPaymentItem(paymentData);
        }).toList(),
      );
    });
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final status = payment['status']?.toString() ?? 'unknown';
    final dueDate = payment['dueDate'] as Timestamp?;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'paid':
        statusColor = AppTheme.successColor;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'overdue':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.payment_outlined,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['description'] ?? 'Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (dueDate != null)
                  Text(
                    DateFormat('MMM dd, yyyy').format(dueDate.toDate()),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
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
                '\$${NumberFormat('#,##0.00').format(amount)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceRequests() {
    return Obx(() {
      if (_tenantController.maintenanceRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.home_repair_service_outlined,
          title: 'No maintenance requests',
          subtitle: 'Your maintenance requests will appear here',
        );
      }

      final recentRequests = _tenantController.maintenanceRequests.take(3).toList();

      return Column(
        children: recentRequests.map((request) {
          final requestData = request['maintenanceData'] as Map<String, dynamic>;
          return _buildMaintenanceItem(requestData);
        }).toList(),
      );
    });
  }

  Widget _buildMaintenanceItem(Map<String, dynamic> request) {
    final status = request['status']?.toString() ?? 'pending';
    final createdAt = request['createdAt'] as Timestamp?;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'resolved':
        statusColor = AppTheme.successColor;
        break;
      case 'in_progress':
      case 'in progress':
        statusColor = AppTheme.infoColor;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = AppTheme.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.home_repair_service_outlined,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['title'] ?? 'Maintenance Request',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (createdAt != null)
                  Text(
                    DateFormat('MMM dd, yyyy').format(createdAt.toDate()),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                // Clear tenant data
                _tenantController.clearData();
                
                // Navigate to login page
                Get.offAllNamed('/login');
                
                Get.snackbar(
                  'Logged Out',
                  'You have been logged out successfully',
                  backgroundColor: AppTheme.successColor,
                  colorText: Colors.white,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}