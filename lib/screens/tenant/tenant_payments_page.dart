import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/services/tenant_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TenantPaymentsPage extends StatefulWidget {
  const TenantPaymentsPage({super.key});

  @override
  State<TenantPaymentsPage> createState() => _TenantPaymentsPageState();
}

class _TenantPaymentsPageState extends State<TenantPaymentsPage> {
  final TenantAuthService _tenantAuthService = TenantAuthService();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  Map<String, List<Map<String, dynamic>>> _paymentsGroupedByProperty = {};
  String _selectedFilter = 'All';
  String? _selectedPropertyId;
  
  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
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
      
      // Fetch payment history
      final payments = await _tenantAuthService.getTenantPaymentHistory(landlordId, tenantId);
      
      setState(() {
        _allPayments = payments;
        _filteredPayments = payments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading payment history: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterPayments(String filter) {
    setState(() {
      _selectedFilter = filter;
      
      if (filter == 'All') {
        _filteredPayments = _allPayments;
      } else {
        _filteredPayments = _allPayments
            .where((payment) => 
                (payment['status'] ?? '').toString().toLowerCase() == filter.toLowerCase())
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Payment History',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              // Download payment statement
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadPaymentHistory,
        child: Column(
          children: [
            // Filter Chips
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFilterChip('All', _allPayments.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Paid', 
                      _allPayments.where((p) => p['status'] == 'paid').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 
                      _allPayments.where((p) => p['status'] == 'pending').length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Overdue', 
                      _allPayments.where((p) => p['status'] == 'overdue').length),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Payment List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPayments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payment_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedFilter == 'All' 
                                    ? 'No payment history'
                                    : 'No $_selectedFilter payments',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = _filteredPayments[index];
                            final status = payment['status'] ?? 'pending';
                            final amount = payment['amount'] ?? 0;
                            final dueDate = payment['dueDate'];
                            final paidDate = payment['paidDate'];
                            final propertyName = payment['propertyName'] ?? 'Property';
                            final month = payment['month'] ?? '';
                            
                            return FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              delay: Duration(milliseconds: index * 50),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      _showPaymentDetails(payment);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Status Icon
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getStatusIcon(status),
                                              color: _getStatusColor(status),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          
                                          // Payment Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  propertyName,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  month.isNotEmpty ? month : 
                                                  (status == 'paid' && paidDate != null
                                                      ? 'Paid on ${_formatDate(paidDate)}'
                                                      : 'Due on ${_formatDate(dueDate)}'),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
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
                                          
                                          // Amount
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                currencyFormat.format(amount),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              if (status == 'pending') ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    'Pay Now',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    
    return GestureDetector(
      onTap: () => _filterPayments(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Property', payment['propertyName'] ?? 'N/A'),
            _buildDetailRow('Month', payment['month'] ?? 'N/A'),
            _buildDetailRow('Amount', currencyFormat.format(payment['amount'] ?? 0)),
            if (payment['paymentFrequency'] != null)
              _buildDetailRow('Frequency', payment['paymentFrequency']),
            if (payment['leaseStartDate'] != null)
              _buildDetailRow('Lease Start', _formatDate(payment['leaseStartDate'])),
            if (payment['leaseEndDate'] != null)
              _buildDetailRow('Lease End', _formatDate(payment['leaseEndDate'])),
            _buildDetailRow('Due Date', _formatDate(payment['dueDate'])),
            if (payment['paidDate'] != null)
              _buildDetailRow('Paid Date', _formatDate(payment['paidDate'])),
            _buildDetailRow('Status', (payment['status'] ?? 'pending').toString().toUpperCase()),
            if (payment['transactionId'] != null)
              _buildDetailRow('Transaction ID', payment['transactionId']),
            const SizedBox(height: 24),
            if (payment['status'] == 'pending')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Handle payment
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Pay Now',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
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
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'overdue':
        return Icons.warning_rounded;
      default:
        return Icons.help_outline;
    }
  }
  
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) return date;
      return DateFormat('dd MMM yyyy').format(date.toDate());
    } catch (e) {
      return 'N/A';
    }
  }
}