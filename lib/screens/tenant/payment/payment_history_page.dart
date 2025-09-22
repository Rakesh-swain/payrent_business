import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/payments/payment_detail_page.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'This Year', 'Last Year'];
  
  // Sample payment history data
  final List<Map<String, dynamic>> _payments = [
    {
      'id': '1',
      'title': 'Monthly Rent',
      'amount': 2200,
      'date': '2023-08-15',
      'dueDate': '2023-08-15',
      'status': 'Paid',
      'method': 'Credit Card',
      'transactionId': 'TXN123456789',
      'receiptUrl': 'https://example.com/receipt/123',
      'property': 'Modern Apartment in Downtown',
      'landlord': 'Sarah Thompson',
    },
    {
      'id': '2',
      'title': 'Monthly Rent',
      'amount': 2200,
      'date': '2023-07-14',
      'dueDate': '2023-07-15',
      'status': 'Paid',
      'method': 'Bank Transfer',
      'transactionId': 'TXN123456788',
      'receiptUrl': 'https://example.com/receipt/122',
      'property': 'Modern Apartment in Downtown',
      'landlord': 'Sarah Thompson',
    },
    {
      'id': '3',
      'title': 'Monthly Rent',
      'amount': 2200,
      'date': '2023-06-15',
      'dueDate': '2023-06-15',
      'status': 'Paid',
      'method': 'UPI',
      'transactionId': 'TXN123456787',
      'receiptUrl': 'https://example.com/receipt/121',
      'property': 'Modern Apartment in Downtown',
      'landlord': 'Sarah Thompson',
    },
    {
      'id': '4',
      'title': 'Monthly Rent',
      'amount': 2200,
      'date': '2023-05-15',
      'dueDate': '2023-05-15',
      'status': 'Paid',
      'method': 'Credit Card',
      'transactionId': 'TXN123456786',
      'receiptUrl': 'https://example.com/receipt/120',
      'property': 'Modern Apartment in Downtown',
      'landlord': 'Sarah Thompson',
    },
    {
      'id': '5',
      'title': 'Monthly Rent',
      'amount': 2200,
      'date': '2023-04-14',
      'dueDate': '2023-04-15',
      'status': 'Paid',
      'method': 'Bank Transfer',
      'transactionId': 'TXN123456785',
      'receiptUrl': 'https://example.com/receipt/119',
      'property': 'Modern Apartment in Downtown',
      'landlord': 'Sarah Thompson',
    },
    {
      'id': '6',
      'title': 'Monthly Rent',
      'amount': 2200,
      'date': null,
      'dueDate': '2023-09-15',
      'status': 'Upcoming',
      'method': null,
      'transactionId': null,
      'receiptUrl': null,
      'property': 'Modern Apartment in Downtown',
      'landlord': 'Sarah Thompson',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  List<Map<String, dynamic>> _getFilteredPayments(String status) {
    // Filter by status first
    List<Map<String, dynamic>> statusFiltered;
    if (status == 'All') {
      statusFiltered = _payments;
    } else if (status == 'Paid') {
      statusFiltered = _payments.where((payment) => payment['status'] == 'Paid').toList();
    } else if (status == 'Upcoming') {
      statusFiltered = _payments.where((payment) => payment['status'] == 'Upcoming').toList();
    } else {
      statusFiltered = _payments;
    }
    
    // Then filter by date
    return _filterByDate(statusFiltered);
  }
  
  List<Map<String, dynamic>> _filterByDate(List<Map<String, dynamic>> payments) {
    final now = DateTime.now();
    final currentYear = DateTime(now.year);
    final lastYear = DateTime(now.year - 1);
    
    if (_selectedFilter == 'This Year') {
      return payments.where((payment) {
        if (payment['date'] == null) return true; // Include upcoming payments
        final date = DateTime.parse(payment['date']);
        return date.year == currentYear.year;
      }).toList();
    } else if (_selectedFilter == 'Last Year') {
      return payments.where((payment) {
        if (payment['date'] == null) return false; // Exclude upcoming payments
        final date = DateTime.parse(payment['date']);
        return date.year == lastYear.year;
      }).toList();
    } else {
      return payments;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculate total paid amount
    final paidPayments = _payments.where((payment) => payment['status'] == 'Paid').toList();
    final totalPaid = paidPayments.fold<double>(
      0, (sum, payment) => sum + (payment['amount'] as num),
    );
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Payment History'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Paid'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7869E6), Color(0xFF4F287D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${paidPayments.length} Payments',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${NumberFormat('#,##0.00').format(totalPaid)}',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View your payment receipts and upcoming payments',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Filter Chips
          SingleChildScrollView( physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filters.map((filter) => _buildFilterChip(filter)).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Payment Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Payments
                _buildPaymentList(_getFilteredPayments('All')),
                
                // Paid Payments
                _buildPaymentList(_getFilteredPayments('Paid')),
                
                // Upcoming Payments
                _buildPaymentList(_getFilteredPayments('Upcoming')),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          filter,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPaymentList(List<Map<String, dynamic>> payments) {
    if (payments.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return FadeInUp(
          duration: Duration(milliseconds: 300 + (index * 100)),
          child: _buildPaymentCard(payment),
        );
      },
    );
  }
  
  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    Color statusColor;
    IconData statusIcon;
    
    switch (payment['status']) {
      case 'Paid':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'Upcoming':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.access_time;
        break;
      case 'Overdue':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        statusColor = AppTheme.textLight;
        statusIcon = Icons.help_outline;
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentDetailPage(paymentId: payment['id']),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          payment['status'] == 'Paid'
                              ? 'Paid on ${_formatDate(payment['date'])}'
                              : 'Due on ${_formatDate(payment['dueDate'])}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          payment['status'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              const Divider(height: 1),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      Text(
                        '\$${NumberFormat('#,##0.00').format(payment['amount'])}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (payment['status'] == 'Paid') ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Payment Method',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        Text(
                          payment['method'] ?? 'N/A',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    OutlinedButton(
                      onPressed: () {
                        // Navigate to make payment page
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      child: const Text('Pay Now'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM, yyyy').format(date);
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppTheme.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No payments found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no payments in this category',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}