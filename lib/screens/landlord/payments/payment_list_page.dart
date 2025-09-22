import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/payments/payment_detail_page.dart';

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'This Month', 'Last Month'];

  // Sample payment data
  final List<Map<String, dynamic>> _payments = [
    {
      'id': '1',
      'tenantName': 'John Doe',
      'tenantId': '1',
      'propertyName': 'Modern Apartment in Downtown',
      'propertyId': '1',
      'amount': 2200,
      'status': 'Completed',
      'dueDate': '2023-08-15',
      'paymentDate': '2023-08-14',
      'method': 'Credit Card',
      'tenantImage': 'assets/profile.png',
    },
    {
      'id': '2',
      'tenantName': 'Jane Smith',
      'tenantId': '2',
      'propertyName': 'Luxury Condo with View',
      'propertyId': '3',
      'amount': 3500,
      'status': 'Due',
      'dueDate': '2023-09-01',
      'paymentDate': null,
      'method': null,
      'tenantImage': 'assets/profile.png',
    },
    {
      'id': '3',
      'tenantName': 'Robert Johnson',
      'tenantId': '3',
      'propertyName': '2-Bedroom Townhouse',
      'propertyId': '4',
      'amount': 2800,
      'status': 'Overdue',
      'dueDate': '2023-08-15',
      'paymentDate': null,
      'method': null,
      'tenantImage': 'assets/profile.png',
    },
    {
      'id': '4',
      'tenantName': 'Michael Brown',
      'tenantId': '4',
      'propertyName': 'Penthouse Apartment',
      'propertyId': '5',
      'amount': 4200,
      'status': 'Completed',
      'dueDate': '2023-08-10',
      'paymentDate': '2023-08-09',
      'method': 'Bank Transfer',
      'tenantImage': 'assets/profile.png',
    },
    {
      'id': '5',
      'tenantName': 'Sarah Wilson',
      'tenantId': '5',
      'propertyName': 'Studio Apartment',
      'propertyId': '6',
      'amount': 1800,
      'status': 'Completed',
      'dueDate': '2023-08-05',
      'paymentDate': '2023-08-03',
      'method': 'UPI',
      'tenantImage': 'assets/profile.png',
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
    if (status == 'All') {
      return _filterByDate(_payments);
    } else {
      return _filterByDate(
        _payments.where((payment) => payment['status'] == status).toList(),
      );
    }
  }

  List<Map<String, dynamic>> _filterByDate(
    List<Map<String, dynamic>> payments,
  ) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    if (_selectedFilter == 'This Month') {
      return payments.where((payment) {
        final dueDate = DateTime.parse(payment['dueDate']);
        final dueMonth = DateTime(dueDate.year, dueDate.month);
        return dueMonth.isAtSameMomentAs(currentMonth);
      }).toList();
    } else if (_selectedFilter == 'Last Month') {
      return payments.where((payment) {
        final dueDate = DateTime.parse(payment['dueDate']);
        final dueMonth = DateTime(dueDate.year, dueDate.month);
        return dueMonth.isAtSameMomentAs(lastMonth);
      }).toList();
    } else {
      return payments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:  Text('Payments',style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              )),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search action
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
                fontSize: 15  ,
                fontWeight: FontWeight.w500,
              ),
          tabs: const [
            Tab(text: 'All',),
            Tab(text: 'Completed'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters
                    .map((filter) => _buildFilterChip(filter))
                    .toList(),
              ),
            ),
          ),

          // Payment Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Payments
                _buildPaymentList(_getFilteredPayments('All')),

                // Completed Payments
                _buildPaymentList(_getFilteredPayments('Completed')),

                // Pending Payments (Due + Overdue)
                _buildPaymentList([
                  ..._getFilteredPayments('Due'),
                  ..._getFilteredPayments('Overdue'),
                ]),
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
                  ),
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
      physics: BouncingScrollPhysics(),
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
      case 'Completed':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'Due':
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Tenant Image
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage(payment['tenantImage']),
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 12),
                  // Payment Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment['tenantName'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payment['propertyName'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Payment Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
                        Icon(statusIcon, size: 14, color: statusColor),
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
                      const SizedBox(height: 4),
                      Text(
                        '\$${payment['amount']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Due Date',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(payment['dueDate']),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: payment['status'] == 'Overdue'
                              ? AppTheme.errorColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        payment['status'] == 'Completed'
                            ? 'Payment Date'
                            : 'Method',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment['status'] == 'Completed'
                            ? _formatDate(payment['paymentDate'])
                            : payment['method'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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

  void _showFilterBottomSheet() {
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
                'Filter Payments',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...['All', 'This Month', 'Last Month'].map((filter) {
                return RadioListTile<String>(
                  title: Text(filter),
                  value: filter,
                  groupValue: _selectedFilter,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payments_outlined,
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
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}
