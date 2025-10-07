import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/payment_controller.dart';
import 'package:payrent_business/screens/landlord/payments/payment_detail_page.dart';
import 'package:payrent_business/widgets/common/app_loading_indicator.dart';

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
  
  // Use PaymentController instead of static data
  final PaymentController _paymentController = Get.find<PaymentController>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch payments when page loads
    _paymentController.fetchPayments();
    
    // Listen for tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _filterPaymentsByTab();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Filter payments based on tab selection
  void _filterPaymentsByTab() {
    final int tabIndex = _tabController.index;
    
    switch (tabIndex) {
      case 0: // All
        _paymentController.filteredPayments.value = _paymentController.payments;
        break;
      case 1: // Completed
        _paymentController.filterPaymentsByStatus('paid');
        break;
      case 2: // Pending
        _paymentController.filterPaymentsByStatus('pending');
        break;
    }
    
    // Apply date filter if selected
    _applyDateFilter();
  }
  
  // Apply date filter after status filter
  void _applyDateFilter() {
    if (_selectedFilter == 'All') {
      return;
    }
    
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    
    List<DocumentSnapshot> filtered = [];
    
    if (_selectedFilter == 'This Month') {
      filtered = _paymentController.filteredPayments.where((payment) {
        final data = payment.data() as Map<String, dynamic>;
        if (data['dueDate'] == null) return false;
        
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final dueMonth = DateTime(dueDate.year, dueDate.month);
        return dueMonth.isAtSameMomentAs(currentMonth);
      }).toList();
      
      _paymentController.filteredPayments.value = filtered;
    } else if (_selectedFilter == 'Last Month') {
      filtered = _paymentController.filteredPayments.where((payment) {
        final data = payment.data() as Map<String, dynamic>;
        if (data['dueDate'] == null) return false;
        
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final dueMonth = DateTime(dueDate.year, dueDate.month);
        return dueMonth.isAtSameMomentAs(lastMonth);
      }).toList();
      
      _paymentController.filteredPayments.value = filtered;
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
          'Payments',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          )
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
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
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'All'),
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

          // Payment Lists with Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Payments
                _buildPaymentListView(),

                // Completed Payments
                _buildPaymentListView(),

                // Pending Payments
                _buildPaymentListView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show dialog to create a new payment
          _showCreatePaymentDialog();
        },
        backgroundColor: AppTheme.primaryColor,
        label: Row(
          children: [
            const Icon(Icons.add, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Create Payment',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white
              ),
            ),
          ],
        ),
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
        
        // Apply combined filters
        _filterPaymentsByTab();
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

  Widget _buildPaymentListView() {
    return Obx(() {
      if (_paymentController.isLoading.value) {
        return const Center(
          child: AppLoadingIndicator(),
        );
      } else if (_paymentController.errorMessage.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading payments',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _paymentController.errorMessage.value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _paymentController.fetchPayments();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      } else if (_paymentController.filteredPayments.isEmpty) {
        return _buildEmptyState();
      } else {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _paymentController.filteredPayments.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final payment = _paymentController.filteredPayments[index];
            return FadeInUp(
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: _buildPaymentCard(payment),
            );
          },
        );
      }
    });
  }

  Widget _buildPaymentCard(DocumentSnapshot payment) {
    final data = payment.data() as Map<String, dynamic>;
    
    // Extract values with null safety
    final String id = payment.id;
    final String tenantName = data['tenantName'] ?? 'Unknown Tenant';
    final String propertyName = data['propertyName'] ?? 'Unknown Property';
    final String unitNumber = data['unitNumber'] ?? '';
    final double amount = (data['amount'] is int) 
        ? (data['amount'] as int).toDouble() 
        : (data['amount'] ?? 0.0);
    final String status = data['status'] ?? 'pending';
    final bool isLate = data['isLate'] ?? false;
    
    // Dates
    DateTime? dueDate;
    DateTime? paymentDate;
    
    try {
      if (data['dueDate'] != null) {
        dueDate = (data['dueDate'] as Timestamp).toDate();
      }
      
      if (data['paymentDate'] != null) {
        paymentDate = (data['paymentDate'] as Timestamp).toDate();
      }
    } catch (e) {
      print('Error parsing payment dates: $e');
    }
    
    final String paymentMethod = data['paymentMethod'] ?? 'N/A';
    
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;

    if (status == 'paid') {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle;
    } else if (isLate) {
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.access_time;
    }
    
    // Display status label
    String statusLabel = status;
    if (status == 'pending' && isLate) {
      statusLabel = 'Overdue';
    } else if (status == 'paid') {
      statusLabel = 'Completed';
    } else if (status == 'pending') {
      statusLabel = 'Due';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentDetailPage(paymentId: id),
          ),
        ).then((_) {
          // Refresh payments when returning from detail page
          _paymentController.fetchPayments();
        });
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
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/profile.png'),
                    onBackgroundImageError: null,
                  ),
                  const SizedBox(width: 12),
                  // Payment Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenantName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          propertyName + (unitNumber.isNotEmpty ? ' - $unitNumber' : ''),
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
                          statusLabel,
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
                        '\$${amount.toStringAsFixed(0)}',
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
                        dueDate != null 
                            ? DateFormat('dd MMM, yyyy').format(dueDate)
                            : 'Not set',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: statusLabel == 'Overdue'
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
                        status == 'paid'
                            ? 'Payment Date'
                            : 'Method',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status == 'paid'
                            ? paymentDate != null 
                                ? DateFormat('dd MMM, yyyy').format(paymentDate)
                                : 'N/A'
                            : paymentMethod,
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showCreatePaymentDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Payment'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
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
              ..._filters.map((filter) {
                return RadioListTile<String>(
                  title: Text(filter),
                  value: filter,
                  groupValue: _selectedFilter,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    
                    // Apply filters
                    _filterPaymentsByTab();
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
  
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Payments',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter tenant name or property',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            _paymentController.searchPayments(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _filterPaymentsByTab(); // Reset to current tab filter
              Navigator.pop(context);
            },
            child: const Text('CLEAR'),
          ),
          ElevatedButton(
            onPressed: () {
              _paymentController.searchPayments(_searchController.text);
              Navigator.pop(context);
            },
            child: const Text('SEARCH'),
          ),
        ],
      ),
    );
  }
  
  void _showCreatePaymentDialog() {
    // Placeholder for payment creation dialog
    // In a real implementation, this would show a form to create a new payment
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create Payment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'To create payments, please use the tenant detail page or generate monthly payments for all tenants.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you would navigate to a full payment creation form
              Navigator.pop(context);
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
}