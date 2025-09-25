import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/property_management/property_detail_page.dart';
import 'package:payrent_business/controllers/tenant_controller.dart';
import 'package:payrent_business/controllers/property_controller.dart';
import 'package:payrent_business/controllers/auth_controller.dart';
import 'package:payrent_business/models/tenant_model.dart';
import 'package:payrent_business/screens/landlord/tenant_management/edit_tenant_page.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class TenantDetailPage extends StatefulWidget {
  final String tenantId;
  
  const TenantDetailPage({super.key, required this.tenantId});

  @override
  State<TenantDetailPage> createState() => _TenantDetailPageState();
}

class _TenantDetailPageState extends State<TenantDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final TenantController _tenantController = Get.find<TenantController>();
  final PropertyController _propertyController = Get.find<PropertyController>();
  final AuthController _authController = Get.find<AuthController>();
  
  DocumentSnapshot? _tenantDoc;
  DocumentSnapshot? _propertyDoc;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _generatedPayments = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTenantData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchTenantData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Fetch tenant data from Firebase
      _tenantDoc = await _tenantController.getTenantById(widget.tenantId);
      
      if (_tenantDoc == null || !_tenantDoc!.exists) {
        throw Exception('Tenant not found');
      }
      
      final tenantData = _tenantDoc!.data() as Map<String, dynamic>;
      
      // Fetch property data if property ID exists
      if (tenantData['propertyId'] != null && tenantData['propertyId'].isNotEmpty) {
        _propertyDoc = await _propertyController.getPropertyById(tenantData['propertyId']);
      }
      
      // Generate payment list based on lease dates and frequency
      _generatePaymentList();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _generatePaymentList() {
    if (_tenantDoc == null) return;
    
    final tenantData = _tenantDoc!.data() as Map<String, dynamic>;
    
    // Get lease details
    final leaseStartDate = tenantData['leaseStartDate'] != null 
        ? (tenantData['leaseStartDate'] as Timestamp).toDate()
        : null;
    final leaseEndDate = tenantData['leaseEndDate'] != null 
        ? (tenantData['leaseEndDate'] as Timestamp).toDate()
        : null;
    final rentAmount = (tenantData['rentAmount'] is int) 
        ? (tenantData['rentAmount'] as int).toDouble() 
        : (tenantData['rentAmount'] ?? 0.0);
    final paymentFrequency = tenantData['paymentFrequency'] ?? 'monthly';
    final rentDueDay = tenantData['rentDueDay'] ?? 1;
    
    if (leaseStartDate == null || leaseEndDate == null) return;
    
    _generatedPayments.clear();
    
    // Calculate payment dates based on frequency
    DateTime currentPaymentDate = DateTime(leaseStartDate.year, leaseStartDate.month, rentDueDay);
    final today = DateTime.now();
    int paymentNumber = 1;
    
    while (currentPaymentDate.isBefore(leaseEndDate) || currentPaymentDate.isAtSameMomentAs(leaseEndDate)) {
      // Don't generate payments for future dates beyond 3 months
      if (currentPaymentDate.isAfter(today.add(const Duration(days: 90)))) {
        break;
      }
      
      String status;
      if (currentPaymentDate.isBefore(today)) {
        // Past due dates - assume paid for demo (you can check actual payment records)
        status = 'paid';
      } else if (currentPaymentDate.year == today.year && 
                 currentPaymentDate.month == today.month) {
        status = 'due';
      } else {
        status = 'upcoming';
      }
      
      _generatedPayments.add({
        'id': 'payment_${paymentNumber}',
        'title': _getPaymentTitle(paymentFrequency),
        'amount': rentAmount,
        'dueDate': currentPaymentDate,
        'status': status,
        'frequency': paymentFrequency,
        'paymentNumber': paymentNumber,
        'formattedDueDate': DateFormat('MMM dd, yyyy').format(currentPaymentDate),
        'isOverdue': currentPaymentDate.isBefore(today) && status != 'paid',
      });
      
      // Calculate next payment date based on frequency
      switch (paymentFrequency.toLowerCase()) {
        case 'weekly':
          currentPaymentDate = currentPaymentDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          currentPaymentDate = DateTime(
            currentPaymentDate.month == 12 ? currentPaymentDate.year + 1 : currentPaymentDate.year,
            currentPaymentDate.month == 12 ? 1 : currentPaymentDate.month + 1,
            rentDueDay,
          );
          break;
        case 'quarterly':
          currentPaymentDate = DateTime(
            currentPaymentDate.month + 3 > 12 ? currentPaymentDate.year + 1 : currentPaymentDate.year,
            (currentPaymentDate.month + 3) > 12 ? (currentPaymentDate.month + 3) - 12 : currentPaymentDate.month + 3,
            rentDueDay,
          );
          break;
        case 'yearly':
          currentPaymentDate = DateTime(
            currentPaymentDate.year + 1,
            currentPaymentDate.month,
            rentDueDay,
          );
          break;
        default:
          currentPaymentDate = DateTime(
            currentPaymentDate.month == 12 ? currentPaymentDate.year + 1 : currentPaymentDate.year,
            currentPaymentDate.month == 12 ? 1 : currentPaymentDate.month + 1,
            rentDueDay,
          );
      }
      
      paymentNumber++;
      _generatedPayments = _generatedPayments.reversed.toList();
    }
  }
  
  String _getPaymentTitle(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'weekly':
        return 'Weekly Rent';
      case 'monthly':
        return 'Monthly Rent';
      case 'quarterly':
        return 'Quarterly Rent';
      case 'yearly':
        return 'Yearly Rent';
      default:
        return 'Rent Payment';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Tenant Details', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Tenant Details', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Error', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_errorMessage!, style: GoogleFonts.poppins(color: AppTheme.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchTenantData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final tenantData = _tenantDoc!.data() as Map<String, dynamic>;
    final propertyData = _propertyDoc?.data() as Map<String, dynamic>?;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Tenant Details', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditTenant(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsBottomSheet(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tenant Profile Header
          _buildTenantHeader(tenantData, propertyData),
          
          // Tab Bar
          _buildTabBar(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(tenantData, propertyData),
                _buildPaymentsTab(tenantData),
                _buildDocumentsTab(tenantData),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTenantHeader(Map<String, dynamic> tenantData, Map<String, dynamic>? propertyData) {
    final firstName = tenantData['firstName'] ?? '';
    final lastName = tenantData['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFA78BFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Tenant Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : 'Unknown Tenant',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (tenantData['email'] != null)
                        Text(
                          tenantData['email'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (tenantData['phone'] != null)
                        Text(
                          tenantData['phone'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            
            // Property and Rent Info
            Row(
              children: [
                Expanded(
                  child: _buildHeaderStat(
                    'Property',
                    propertyData?['name'] ?? 'Not Assigned',
                    Icons.home_outlined,
                  ),
                ),
                Expanded(
                  child: _buildHeaderStat(
                    'Rent Amount',
                    '\$${(tenantData['rentAmount'] ?? 0).toStringAsFixed(0)}',
                    Icons.attach_money_outlined,
                  ),
                ),
                Expanded(
                  child: _buildHeaderStat(
                    'Frequency',
                    _capitalizeFirst(tenantData['paymentFrequency'] ?? 'monthly'),
                    Icons.schedule_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildTabBar() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Payments'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailsTab(Map<String, dynamic> tenantData, Map<String, dynamic>? propertyData) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information
            _buildInfoCard(
              'Personal Information',
              Icons.person_outline,
              [
                _buildDetailRow('First Name', tenantData['firstName'] ?? 'Not provided'),
                _buildDetailRow('Last Name', tenantData['lastName'] ?? 'Not provided'),
                _buildDetailRow('Email', tenantData['email'] ?? 'Not provided'),
                _buildDetailRow('Phone', tenantData['phone'] ?? 'Not provided'),
                if (tenantData['status'] != null)
                  _buildDetailRow('Status', tenantData['status']),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Property Information
            if (propertyData != null)
              _buildInfoCard(
                'Property Information',
                Icons.home_outlined,
                [
                  _buildDetailRow('Property Name', propertyData['name'] ?? 'Unknown'),
                  _buildDetailRow('Unit Number', tenantData['unitNumber'] ?? 'Not specified'),
                  if (propertyData['address'] != null)
                    _buildDetailRow('Address', propertyData['address']),
                  if (propertyData['city'] != null)
                    _buildDetailRow('City', propertyData['city']),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // Lease Information
            _buildInfoCard(
              'Lease Information',
              Icons.description_outlined,
              [
                if (tenantData['leaseStartDate'] != null)
                  _buildDetailRow('Lease Start', _formatTimestamp(tenantData['leaseStartDate'])),
                if (tenantData['leaseEndDate'] != null)
                  _buildDetailRow('Lease End', _formatTimestamp(tenantData['leaseEndDate'])),
                _buildDetailRow('Rent Amount', '\$${(tenantData['rentAmount'] ?? 0).toStringAsFixed(2)}'),
                _buildDetailRow('Payment Frequency', _capitalizeFirst(tenantData['paymentFrequency'] ?? 'monthly')),
                _buildDetailRow('Rent Due Day', '${tenantData['rentDueDay'] ?? 1}${_getDaySuffix(tenantData['rentDueDay'] ?? 1)} of each ${tenantData['paymentFrequency'] ?? 'month'}'),
                if (tenantData['securityDeposit'] != null)
                  _buildDetailRow('Security Deposit', '\$${tenantData['securityDeposit'].toStringAsFixed(2)}'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Additional Information
            if (tenantData['notes'] != null && tenantData['notes'].toString().isNotEmpty)
              _buildInfoCard(
                'Additional Notes',
                Icons.note_outlined,
                [
                  _buildDetailRow('Notes', tenantData['notes']),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentsTab(Map<String, dynamic> tenantData) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Summary
            _buildPaymentSummaryCard(tenantData),
            
            const SizedBox(height: 20),
            
            // Payment List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_generatedPayments.length} payments',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Payment List
            if (_generatedPayments.isEmpty)
              _buildEmptyPaymentsState()
            else
              ..._generatedPayments.map((payment) => _buildPaymentItem(payment)).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentSummaryCard(Map<String, dynamic> tenantData) {
    final paidPayments = _generatedPayments.where((p) => p['status'] == 'paid').length;
    final duePayments = _generatedPayments.where((p) => p['status'] == 'due').length;
    final overduePayments = _generatedPayments.where((p) => p['isOverdue'] == true).length;
    final totalAmount = _generatedPayments.fold<double>(0.0, (sum, p) => sum + (p['amount'] as double));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Payments',
                  _generatedPayments.length.toString(),
                  Colors.blue,
                  Icons.receipt_long_outlined,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Paid',
                  paidPayments.toString(),
                  Colors.green,
                  Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Due',
                  duePayments.toString(),
                  Colors.orange,
                  Icons.schedule_outlined,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Overdue',
                  overduePayments.toString(),
                  Colors.red,
                  Icons.warning_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\$${NumberFormat('#,##0.00').format(totalAmount)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
    );
  }
  
  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    Color statusColor;
    IconData statusIcon;
    
    switch (payment['status']) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'due':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'upcoming':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }
    
    if (payment['isOverdue'] == true) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: ${payment['formattedDueDate']}',
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
                '\$${NumberFormat('#,##0.00').format(payment['amount'])}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
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
                  payment['isOverdue'] == true ? 'Overdue' : _capitalizeFirst(payment['status']),
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
  
  Widget _buildEmptyPaymentsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Payment Schedule',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please ensure lease dates and payment frequency are set',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDocumentsTab(Map<String, dynamic> tenantData) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Documents',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement document upload
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Document upload coming soon')),
                    );
                  },
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Placeholder for documents
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No Documents Yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload lease agreements, ID proofs, and other documents',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToEditTenant() {
    if (_tenantDoc != null) {
      Get.to(() => EditTenantPage(tenantId: widget.tenantId))?.then((_) {
        // Refresh data when returning from edit
        _fetchTenantData();
      });
    }
  }
  
  void _showOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tenant Options',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionItem(
                icon: Icons.edit_outlined,
                label: 'Edit Tenant Details',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditTenant();
                },
              ),
              if (_tenantDoc != null && _propertyDoc != null)
                _buildOptionItem(
                  icon: Icons.home_outlined,
                  label: 'View Property',
                  onTap: () {
                    Navigator.pop(context);
                    final tenantData = _tenantDoc!.data() as Map<String, dynamic>;
                    if (tenantData['propertyId'] != null) {
                      Get.to(() => PropertyDetailsPage(propertyId: tenantData['propertyId']));
                    }
                  },
                ),
              _buildOptionItem(
                icon: Icons.delete_outline,
                label: 'Delete Tenant',
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
                isDestructive: true,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.errorColor.withOpacity(0.1)
              : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
        ),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.errorColor : null,
        ),
      ),
      onTap: onTap,
    );
  }
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Tenant'),
          content: const Text('Are you sure you want to delete this tenant? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _tenantController.deleteTenant(widget.tenantId);
                if (success) {
                  Get.back(); // Return to previous screen
                  Get.snackbar('Success', 'Tenant deleted successfully');
                } else {
                  Get.snackbar('Error', 'Failed to delete tenant');
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Not specified';
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('MMM dd, yyyy').format(date);
    }
    
    return 'Invalid date';
  }
  
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}