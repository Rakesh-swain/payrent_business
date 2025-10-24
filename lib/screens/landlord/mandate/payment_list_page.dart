import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/mandate/payment_details_page.dart';

class PaymentListPage extends StatefulWidget {
  final String type; // 'due rent today', 'collection today', 'overdue', total earning this month
  const PaymentListPage({Key? key, required this.type}) : super(key: key);

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _showFilterDropdown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _pageTitle {
  switch (widget.type) {
    case 'collection today':
      return 'Collection Today';
    case 'overdue':
      return 'Overdue Rent';
    case 'total earning this month':
      return 'Earnings This Month';
    case 'due rent tomorrow':
      return 'Due Rent Tomorrow';
    default:
      return 'Due Rent Today';
  }
}

Color get _primaryColor {
  switch (widget.type) {
    case 'collection today':
      return const Color(0xFF4CAF50);
    case 'overdue':
      return const Color(0xFFFF6B6B);
    case 'total earning this month':
      return const Color(0xFF2196F3); // Blue for earnings
    default:
      return const Color(0xFF6C63FF);
  }
}

IconData get _headerIcon {
  switch (widget.type) {
    case 'collection today':
      return Icons.attach_money_rounded;
    case 'overdue':
      return Icons.warning_amber_rounded;
    case 'total earning this month':
      return Icons.pie_chart_rounded;
    default:
      return Icons.calendar_today_outlined;
  }
}


  // Get date range based on filter selection (only used for overdue)
  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'last_week':
        return DateTimeRange(
          start: now.subtract(Duration(days: 7)),
          end: now,
        );
      case 'last_month':
        return DateTimeRange(
          start: now.subtract(Duration(days: 30)),
          end: now,
        );
      case 'last_6_months':
        return DateTimeRange(
          start: DateTime(now.year, now.month - 6, now.day),
          end: now,
        );
      case 'last_1_year':
        return DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return DateTimeRange(start: _customStartDate!, end: _customEndDate!);
        }
        return DateTimeRange(start: now.subtract(Duration(days: 7)), end: now);
      default:
        return DateTimeRange(start: now.subtract(Duration(days: 7)), end: now);
    }
  }

  // Apply payment type specific filters
  Query _applyPaymentTypeFilter(Query query) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = startOfToday.add(Duration(days: 1));
  final startOfTomorrow = endOfToday; // tomorrow starts when today ends
  final endOfTomorrow = startOfTomorrow.add(Duration(days: 1));
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  switch (widget.type) {
    case 'collection today':
      // Payments that are paid today
      return query
          .where('status', isEqualTo: 'paid')
          .where('payment_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('payment_date', isLessThan: Timestamp.fromDate(endOfToday));

    case 'total earning this month':
      // All paid payments this month
      return query
          .where('status', isEqualTo: 'paid')
          .where('payment_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('payment_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));

    case 'due rent today':
      // Payments due today (regardless of status)
      return query
          .where('due_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('due_date', isLessThan: Timestamp.fromDate(endOfToday));

    case 'due rent tomorrow':
      // Payments due tomorrow
      return query
          .where('due_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow))
          .where('due_date', isLessThan: Timestamp.fromDate(endOfTomorrow));

    case 'overdue':
      // Overdue = pending or failed and due date before today
      query = query
          .where('status', whereIn: ['pending', 'failed'])
          .where('due_date', isLessThan: Timestamp.fromDate(startOfToday));

      // Optional date range filter
      if (_selectedFilter != 'all') {
        final dateRange = _getDateRange();
        query = query.where('due_date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start));
      }
      return query;

    default:
      return query;
  }
}


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 800;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _pageTitle,
              style: GoogleFonts.poppins(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            actions: [
              // Filter Dropdown - Only show for overdue
              if (widget.type == 'overdue')
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.filter_list,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    onSelected: (value) async {
                      if (value == 'custom') {
                        final dateRange = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _customStartDate != null && _customEndDate != null
                              ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
                              : null,
                        );
                        if (dateRange != null) {
                          setState(() {
                            _customStartDate = dateRange.start;
                            _customEndDate = dateRange.end;
                            _selectedFilter = 'custom';
                          });
                        }
                      } else {
                        setState(() {
                          _selectedFilter = value;
                        });
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'all',
                        child: Text('All Overdue'),
                      ),
                      const PopupMenuItem(
                        value: 'last_week',
                        child: Text('Last Week'),
                      ),
                      const PopupMenuItem(
                        value: 'last_month',
                        child: Text('Last Month'),
                      ),
                      const PopupMenuItem(
                        value: 'last_6_months',
                        child: Text('Last 6 Months'),
                      ),
                      const PopupMenuItem(
                        value: 'last_1_year',
                        child: Text('Last 1 Year'),
                      ),
                      const PopupMenuItem(
                        value: 'custom',
                        child: Text('Custom Range'),
                      ),
                    ],
                  ),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Tenants'),
                Tab(text: 'Properties'),
              ],
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTenantsView(isWeb),
              _buildPropertiesView(isWeb),
            ],
          ),
        );
      },
    );
  }

  // Build Tenants Tab View
Widget _buildTenantsView(bool isWeb) {
  final landlordId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Query query = FirebaseFirestore.instance
      .collection('users')
      .doc(landlordId)
      .collection('payments');

  query = _applyPaymentTypeFilter(query);

  return StreamBuilder<QuerySnapshot>(
    stream: query.snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        print(snapshot.error);
        return Center(child: Text('Error loading payments: ${snapshot.error}'));
      }

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      // Group payments by tenant
      Map<String, List<Map<String, dynamic>>> tenantPayments = {};
      Map<String, double> tenantTotals = {};

      for (var doc in snapshot.data!.docs) {
        final payment = doc.data() as Map<String, dynamic>;
        final tenantId = payment['tenant_id'] ?? '';
        if (tenantId.isNotEmpty) {
          tenantPayments.putIfAbsent(tenantId, () => []);
          tenantPayments[tenantId]!.add(payment);
          tenantTotals[tenantId] = (tenantTotals[tenantId] ?? 0) + (payment['amount'] ?? 0);
        }
      }

      if (tenantPayments.isEmpty) {
        return _buildEmptyView('No tenant payments found');
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tenantPayments.keys.length,
        itemBuilder: (context, index) {
          final tenantId = tenantPayments.keys.elementAt(index);
          final payments = tenantPayments[tenantId]!;
          final totalAmount = tenantTotals[tenantId]!;

          // Take the first payment to get property/unit info
          final firstPayment = payments.first;
          final propertyId = firstPayment['property_id'];
          final unitId = firstPayment['unit_id'];

          // 🏠 Fetch property + unit names asynchronously
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(landlordId)
                .collection('properties')
                .doc(propertyId)
                .get(),
            builder: (context, propertySnapshot) {
              if (propertySnapshot.connectionState == ConnectionState.waiting) {
                return  Container();
              }

              if (!propertySnapshot.hasData || !propertySnapshot.data!.exists) {
                return _buildTenantCard(
                  tenantId,
                  payments,
                  totalAmount,
                  isWeb,
                  'Unknown Property',
                   'Unknown Unit',
                );
              }

              final propertyData = propertySnapshot.data!.data() as Map<String, dynamic>;
              print(propertyData);
              final propertyName = propertyData['property_name'] ?? 'Unknown Property';
              final units = propertyData['units'] as List<dynamic>? ?? [];

              // 🔍 Find unit name by matching unit_id
              String unitName = 'Unknown Unit';
              for (var unit in units) {
                if (unit is Map<String, dynamic> && unit['unit_id'] == unitId) {
                  unitName = unit['unit_name'] ?? 'Unknown Unit';
                  break;
                }
              }

              return _buildTenantCard(
                tenantId,
                payments,
                totalAmount,
                isWeb,
                propertyName,
                unitName,
              );
            },
          );
        },
      );
    },
  );
}


  // Build Properties Tab View
  Widget _buildPropertiesView(bool isWeb) {
    final landlordId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    // Build query based on payment type
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(landlordId)
        .collection('payments');

    // Apply filters based on payment type
    query = _applyPaymentTypeFilter(query);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
         if (snapshot.hasError) {
        print(snapshot.error);
        return Center(
          child: Text('Error loading payments: ${snapshot.error}'),
        );
      }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Group payments by property
        Map<String, List<Map<String, dynamic>>> propertyPayments = {};
        Map<String, double> propertyTotals = {};
        
        for (var doc in snapshot.data!.docs) {
          final payment = doc.data() as Map<String, dynamic>;
          final propertyId = payment['property_id'] ?? '';
          if (propertyId.isNotEmpty) {
            propertyPayments.putIfAbsent(propertyId, () => []);
            propertyPayments[propertyId]!.add(payment);
            propertyTotals[propertyId] = (propertyTotals[propertyId] ?? 0) + (payment['amount'] ?? 0);
          }
        }

        if (propertyPayments.isEmpty) {
          return _buildEmptyView('No property payments found');
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: propertyPayments.keys.length,
          itemBuilder: (context, index) {
            final propertyId = propertyPayments.keys.elementAt(index);
            final payments = propertyPayments[propertyId]!;
            final totalAmount = propertyTotals[propertyId]!;

            return _buildPropertyCard(propertyId, payments, totalAmount, isWeb);
          },
        );
      },
    );
  }



  Widget _buildTenantCard(String tenantId, List<Map<String, dynamic>> payments, double totalAmount, bool isWeb,String proppertyName,String unitName) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
          .collection('tenants')
          .doc(tenantId)
          .snapshots(),
      builder: (context, tenantSnapshot) {
        String tenantName = 'Unknown Tenant';
        String phone = '';
        String email = '';
        if (tenantSnapshot.hasData && tenantSnapshot.data!.exists) {
          final tenantData = tenantSnapshot.data!.data() as Map<String, dynamic>;
          final firstName = tenantData['firstName'] ?? '';
          final lastName = tenantData['lastName'] ?? '';
           phone = tenantData['phone'] ?? '';
           email = tenantData['email'] ?? '';
          tenantName = '$firstName $lastName'.trim();
          if (tenantName.isEmpty) tenantName = 'Unknown Tenant';
        }

        return _buildExpandableCard(
          title: tenantName,
          subtitle: '${payments.length} payment${payments.length > 1 ? 's' : ''}',
          totalAmount: totalAmount,
          isWeb: isWeb,
          email: email,
          phone: phone,
          propertyName: proppertyName,
          unitName: unitName,
          onExpand: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentDetailsPage(
                id: tenantId,
                name: tenantName,
                type: 'tenant',
                paymentType: widget.type,
                email: email,
                phone: phone,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyCard(String propertyId, List<Map<String, dynamic>> payments, double totalAmount, bool isWeb) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
          .collection('properties')
          .doc(propertyId)
          .snapshots(),
      builder: (context, propertySnapshot) {
        String propertyName = 'Unknown Property';
        if (propertySnapshot.hasData && propertySnapshot.data!.exists) {
          final propertyData = propertySnapshot.data!.data() as Map<String, dynamic>;
          propertyName = propertyData['name'] ?? 'Unknown Property';
        }

        return _buildExpandableCard(
          title: propertyName,
          subtitle: '${payments.length} payment${payments.length > 1 ? 's' : ''}',
          totalAmount: totalAmount,
          isWeb: isWeb,
          email: '',
          phone: '',
          propertyName: '',
          unitName: '',
          onExpand: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentDetailsPage(
                id: propertyId,
                name: propertyName,
                type: 'property',paymentType: widget.type,
              ),
            ),
          ),
        );
      },
    );
  }

Widget _buildExpandableCard({
  required String title,
  required String subtitle,
  required String phone,
  required String email,
  required String propertyName,
  required String unitName,
  required double totalAmount,
  required bool isWeb,
  required VoidCallback onExpand,
}) {


  return InkWell(
    onTap: onExpand,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
    
            // 📄 Info section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
    
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
    
                  const SizedBox(height: 6),
    
                  // 📞 Phone (only if not empty)
                  if (phone.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '+968 $phone',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
    
                  // 📧 Email (only if not empty)
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
    
                  // // 🏠 Property (only if not empty)
                  // if (propertyName.isNotEmpty || unitName.isNotEmpty) ...[
                  //   const SizedBox(height: 8),
                  //   Row(
                  //     children: [
                  //       Icon(Icons.home_work_outlined, size: 16, color: Colors.grey[600]),
                  //       const SizedBox(width: 6),
                  //       Expanded(
                  //         child: Text(
                  //           '${propertyName.isNotEmpty ? propertyName : ''}'
                  //           '${propertyName.isNotEmpty && unitName.isNotEmpty ? ' • ' : ''}'
                  //           '${unitName.isNotEmpty ? unitName : ''}',
                  //           style: GoogleFonts.poppins(
                  //             fontSize: 13,
                  //             color: Colors.grey[700],
                  //             fontWeight: FontWeight.w500,
                  //           ),
                  //           overflow: TextOverflow.ellipsis,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ],
                ],
              ),
            ),
    
            // 💰 Amount + arrow
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'OMR ${totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Text(
                //   'Total',
                //   style: GoogleFonts.poppins(
                //     color: Colors.grey[500],
                //     fontSize: 12,
                //   ),
                // ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: onExpand,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}




  void _showPaymentDetails(BuildContext context, List<Map<String, dynamic>> payments, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '$title - Payment Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${payments.length} payment${payments.length > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  final date = (payment['due_date'] as Timestamp).toDate();
                  final amount = payment['amount'] ?? 0.0;
                  final status = payment['status'] ?? 'pending';

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: status == 'paid' ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            status == 'paid' ? Icons.check : Icons.schedule,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy').format(date),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: status == 'paid' ? Colors.green : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'OMR ${amount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
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

  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, double totalAmount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_headerIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Payment${count > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.type == 'due rent today'
                      ? 'Due today'
                      : widget.type == 'collection today'
                          ? 'Collected today'
                          : 'Overdue payments',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total', style: TextStyle(color: Colors.white)),
              Text(
                'OMR ${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_headerIcon, color: _primaryColor.withOpacity(0.3), size: 80),
          const SizedBox(height: 12),
          Text(
            widget.type == 'due rent today'
                ? 'No rent due today'
                : widget.type == 'collection today'
                    ? 'No collections made today'
                    : 'No overdue rent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _primaryColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String landlordId;
  final Map<String, dynamic> payment;
  final Color primaryColor;
  final String type;

  const _PaymentCard({
    required this.landlordId,
    required this.payment,
    required this.primaryColor,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final date = (payment['due_date'] as Timestamp).toDate();
    final amount = payment['amount'] ?? 0.0;
    final status = (payment['status'] ?? 'pending').toString().toUpperCase();
    final propertyId = payment['property_id'];
    final unitId = payment['unit_id'];
    final tenantId = payment['tenant_id'];
    final mmsId = payment['mmsId'] ?? '';
    final refId = payment['ref_number'] ?? '';
    final paymentRefId = payment['payment_ref_number'] ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(landlordId)
          .collection('properties')
          .doc(propertyId)
          .snapshots(),
      builder: (context, propertySnapshot) {
        String propertyName = 'Property';
        String unitName = 'Unit';

        if (propertySnapshot.hasData && propertySnapshot.data!.exists) {
          final propertyData =
              propertySnapshot.data!.data() as Map<String, dynamic>;
          propertyName = propertyData['name'] ?? 'Property';

          if (propertyData['units'] is List) {
            for (final unit in propertyData['units']) {
              if (unit['unitId'] == unitId) {
                unitName = unit['unitNumber'] ?? 'Unit';
                break;
              }
            }
          }
        }

        final daysOverdue = type == 'overdue'
            ? DateTime.now().difference(date).inDays
            : 0;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(landlordId)
              .collection('tenants')
              .doc(tenantId)
              .snapshots(),
          builder: (context, tenantSnapshot) {
            String tenantName = '';
            if (tenantSnapshot.hasData && tenantSnapshot.data!.exists) {
              final tenantData =
                  tenantSnapshot.data!.data() as Map<String, dynamic>;
              final firstName = tenantData['firstName'] ?? '';
              final lastName = tenantData['lastName'] ?? '';
              tenantName = (firstName + ' ' + lastName).trim().isEmpty
                  ? 'Tenant'
                  : '$firstName $lastName';
            }

            // Determine status color
            Color statusColor;
            switch (status.toLowerCase()) {
              case 'paid':
                statusColor = Colors.green;
                break;
              case 'pending':
                statusColor = Colors.orange;
                break;
              case 'overdue':
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.grey;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () {},
                leading: _buildDateBadge(date),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tenant Name
                    Text(
                      tenantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Property + Unit
                    Text(
                      '$propertyName | Unit: $unitName',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Payment Ref ID
                    if (paymentRefId.isNotEmpty)
                      Text(
                        'Payment Ref No.: $paymentRefId',
                        style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    if (daysOverdue > 0)
                      Text(
                        'Overdue by $daysOverdue days',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'OMR ${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status, // Paid / Pending / Overdue
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateBadge(DateTime date) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('dd').format(date),
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            DateFormat('MMM').format(date),
            style: TextStyle(
              color: primaryColor.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
