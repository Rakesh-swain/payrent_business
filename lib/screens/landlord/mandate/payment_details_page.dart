import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payrent_business/config/theme.dart';

class PaymentDetailsPage extends StatefulWidget {
  final String id; // tenant_id or property_id
  final String name; // tenant name or property name
  final String type; // 'tenant' or 'property'
  final String
  paymentType; // 'collection today', 'due rent today', 'overdue', 'total earning this month'
   final String? email; // optional
  final String? phone; // optional

  const PaymentDetailsPage({
    Key? key,
    required this.id,
    required this.name,
    required this.type,
    required this.paymentType,
    this.email,
    this.phone,
  }) : super(key: key);

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  // Apply payment type specific filters
Query _applyPaymentTypeFilter(Query query) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = startOfToday.add(const Duration(days: 1));
  final startOfTomorrow = endOfToday; // tomorrow starts after today ends
  final endOfTomorrow = startOfTomorrow.add(const Duration(days: 1));
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  switch (widget.paymentType) {
    case 'collection today':
      // Payments that are paid today
      return query.where(
        Filter.and(
          Filter('status', isEqualTo: 'paid'),
          Filter('payment_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday)),
          Filter('payment_date', isLessThan: Timestamp.fromDate(endOfToday)),
        ),
      );

    case 'total earning this month':
      // All paid payments this month
      return query.where(
        Filter.and(
          Filter('status', isEqualTo: 'paid'),
          Filter('payment_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth)),
          Filter('payment_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth)),
        ),
      );

    case 'due rent today':
      // Payments due today (regardless of status)
      return query.where(
        Filter.and(
          Filter('due_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday)),
          Filter('due_date', isLessThan: Timestamp.fromDate(endOfToday)),
        ),
      );

    case 'due rent tomorrow':
      // Payments due tomorrow (regardless of status)
      return query.where(
        Filter.and(
          Filter('due_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow)),
          Filter('due_date', isLessThan: Timestamp.fromDate(endOfTomorrow)),
        ),
      );

    case 'overdue':
      // Pending or failed payments due before today
      return query.where(
        Filter.and(
          Filter.or(
            Filter('status', isEqualTo: 'pending'),
            Filter('status', isEqualTo: 'failed'),
          ),
          Filter('due_date', isLessThan: Timestamp.fromDate(startOfToday)),
        ),
      );

    default:
      return query;
  }
}


  String _getPaymentTypeTitle() {
    switch (widget.paymentType) {
      case 'collection today':
        return 'Collection Today';
      case 'due rent today':
        return 'Due Today';
      case 'overdue':
        return 'Overdue Payments';
      case 'total earning this month':
        return 'Earnings This Month';
      case 'due rent tomorrow':
        return 'Due Rent Tomorrow';
      default:
        return '${widget.type.capitalizeFirst} Payments';
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.poppins(
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(width: 10),
                    widget.email != null?Text(
                      '+968 ${widget.phone!}',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                      ),
                    ):Container(),
                    SizedBox(width: 10),
                     widget.phone != null?Text(
                      widget.email!,
                      style: GoogleFonts.poppins(
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                      ),
                    ):Container(),
                  ],
                ),
                Text(
                  _getPaymentTypeTitle(),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          body: _buildPaymentsList(isWeb),
        );
      },
    );
  }

  Widget _buildPaymentsList(bool isWeb) {
    final landlordId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Build query based on type
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(landlordId)
        .collection('payments');

    if (widget.type == 'tenant') {
      query = query.where('tenant_id', isEqualTo: widget.id);
    } else {
      query = query.where('property_id', isEqualTo: widget.id);
    }

    // Apply payment type specific filters
    query = _applyPaymentTypeFilter(query);

    query = query.orderBy('due_date', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // Show loading only on first load
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors
        if (snapshot.hasError) {
          print(snapshot.error);
          return Center(
            child: Text('Error loading payments: ${snapshot.error}'),
          );
        }

        // Handle no data
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyView('No payments found');
        }

        // Build content with data
        final payments = snapshot.data!.docs;
        return _buildPaymentsContent(isWeb, payments);
      },
    );
  }

  /// Helper to build the summary header + list content
  Widget _buildPaymentsContent(
    bool isWeb,
    List<QueryDocumentSnapshot> payments,
  ) {
    // Calculate totals
    double totalAmount = 0;
    int paidCount = 0;
    int pendingCount = 0;
    int overdueCount = 0;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    for (var doc in payments) {
      final payment = doc.data() as Map<String, dynamic>;
      final amount = payment['amount'] ?? 0.0;
      final status = payment['status'] ?? 'pending';
      final dueDate = (payment['due_date'] as Timestamp).toDate();

      totalAmount += amount;

      if (status == 'paid') {
        paidCount++;
      } else if (status == 'pending' || status == "failed") {
        if (dueDate.isBefore(startOfToday)) {
          overdueCount++;
        } else {
          pendingCount++;
        }
      }
    }

    return Column(
      children: [
        // Summary Header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isWeb
              ? _buildWebSummaryHeader(
                  payments.length,
                  totalAmount,
                  paidCount,
                  pendingCount,
                  overdueCount,
                )
              : _buildMobileSummaryHeader(
                  payments.length,
                  totalAmount,
                  paidCount,
                  pendingCount,
                  overdueCount,
                ),
        ),

        // Payments List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index].data() as Map<String, dynamic>;
              return _buildPaymentCard(payment, isWeb);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWebSummaryHeader(
    int total,
    double totalAmount,
    int paid,
    int pending,
    int overdue,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            widget.type == 'tenant' ? Icons.person : Icons.home,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total Payments',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'OMR ${totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              _buildStatusRow(paid, pending, overdue)
            ],
          ),
        ),
      ],
    );
  }
Widget _buildStatusRow(int paid, int pending, int overdue) {
  List<Widget> chips = [];

  if (widget.paymentType == "total earning this month" ||
      widget.paymentType == "collection today") {
    chips = [
      _buildStatusChip('Paid', paid, Colors.green),
    ];
  } else if (widget.paymentType == "due rent today") {
    chips = [
      _buildStatusChip('Paid', paid, Colors.green),
      const SizedBox(width: 12),
      _buildStatusChip('Pending', pending, Colors.orange),
    ];
  } else if (widget.paymentType == "overdue") {
    chips = [
      _buildStatusChip('Overdue', overdue, Colors.red),
    ];
  }

  return Row(
    children: chips,
  );
}

  Widget _buildMobileSummaryHeader(
    int total,
    double totalAmount,
    int paid,
    int pending,
    int overdue,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.type == 'tenant' ? Icons.person : Icons.home,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total Payments',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Total Amount',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'OMR ${totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildStatusRow(paid, pending, overdue)
      ],
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6),
          Text(
            '$label ($count)',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, bool isWeb) {
    final date = (payment['due_date'] as Timestamp).toDate();
    final amount = payment['amount'] ?? 0.0;
    final status = payment['status'] ?? 'pending';
    final tenantId = payment['tenant_id'] ?? '';
    final propertyId = payment['property_id'] ?? '';
    final unitId = payment['unit_id'] ?? '';
    final deferredDate =
        payment['deferred_date']; // Get deferred date if exists

    // Determine if overdue
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final isOverdue = (status == 'pending' || status == 'failed') && date.isBefore(startOfToday);
    final displayStatus =status == "failed"?'failed': isOverdue ? 'overdue':status;
    final reason = payment['reason'];
    final scheduleNo = payment['schedule_number'];

print(status);
    // Status color
    Color statusColor;
    switch (displayStatus.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'overdue':
        statusColor = Colors.red;
        break;
      case 'failed':
        statusColor = Colors.red;
        break;  
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue
            ? Border.all(color: Colors.red.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: isOverdue
                ? Colors.red.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Date Badge
            Container(
              width: 50,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(date),
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: GoogleFonts.poppins(
                      color: statusColor.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy').format(date),
                    style: GoogleFonts.poppins(
                      color: statusColor.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            // Payment Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show appropriate details based on type
                  if (widget.type == 'tenant') ...[
                    _buildPropertyUnitInfo(propertyId, unitId),
                  ] else ...[
                    _buildTenantInfo(tenantId),
                  ],
                  SizedBox(height: 4),
                  Text(
                    'Schedule No. ${scheduleNo}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (isOverdue) ...[
                    SizedBox(height: 2),
                    Text(
                      'Overdue by ${now.difference(date).inDays} days',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  // Show deferred date if exists
                  if (deferredDate != null) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Deferred to: ${DateFormat('MMM dd, yyyy').format((deferredDate as Timestamp).toDate())}',
                        style: GoogleFonts.poppins(
                          color: Colors.orange[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Amount and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'OMR ${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: (){
                         if (displayStatus.toLowerCase() == 'failed' || displayStatus.toLowerCase() == 'overdue' ){
                            showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Failed Reason',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                reason ?? 'Insufficient Funds — The tenant’s account didn’t have enough balance to complete the payment.',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Close',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                         }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          displayStatus.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (displayStatus.toLowerCase() == 'failed' || displayStatus.toLowerCase() == 'overdue' ) ...[
                      SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Failed Reason',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                reason ?? 'Insufficient Funds — The tenant’s account didn’t have enough balance to complete the payment.',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Close',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                      ),
                    ],
                  ],
                ),

                // Show Defer button only for overdue payments in overdue payment type and if not already deferred
                if (((widget.paymentType == 'overdue') &&
                    isOverdue &&
                    deferredDate == null)|| (widget.paymentType == "due rent tomorrow")) ...[
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showDeferPaymentDialog(payment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(60, 30),
                    ),
                    child: Text(
                      'Defer',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantInfo(String tenantId) {
    final landlordId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(landlordId)
          .collection('tenants')
          .doc(tenantId)
          .snapshots(),
      builder: (context, snapshot) {
        String tenantName = 'Unknown Tenant';
          String phone = '';
        String email = '';
        if (snapshot.hasData && snapshot.data!.exists) {
          final tenantData = snapshot.data!.data() as Map<String, dynamic>;
          final firstName = tenantData['firstName'] ?? '';
          final lastName = tenantData['lastName'] ?? '';
          tenantName = '$firstName $lastName'.trim();
           phone = tenantData['phone'] ?? '';
           email = tenantData['email'] ?? '';
          if (tenantName.isEmpty) tenantName = 'Unknown Tenant';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tenantName,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
            ),
              Text(
            '+968 ${phone}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 12),
            ),
              Text(
              email,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPropertyUnitInfo(String propertyId, String unitId) {
    final landlordId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(landlordId)
          .collection('properties')
          .doc(propertyId)
          .snapshots(),
      builder: (context, snapshot) {
        String propertyName = 'Unknown Property';
        String unitName = 'Unit';

        if (snapshot.hasData && snapshot.data!.exists) {
          final propertyData = snapshot.data!.data() as Map<String, dynamic>;
          propertyName = propertyData['name'] ?? 'Unknown Property';

          if (propertyData['units'] is List) {
            for (final unit in propertyData['units']) {
              if (unit['unitId'] == unitId) {
                unitName = unit['unitNumber'] ?? 'Unit';
                break;
              }
            }
          }
        }

        return Text(
          '$propertyName - $unitName',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        );
      },
    );
  }

  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
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

  // Show defer payment dialog
  void _showDeferPaymentDialog(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Defer Payment',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a new due date for this payment:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Current due date: ${DateFormat('MMM dd, yyyy').format((payment['due_date'] as Timestamp).toDate())}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(
                    Duration(days: 1),
                  ), // Start from tomorrow
                  firstDate: DateTime.now().add(
                    Duration(days: 1),
                  ), // Can't select today or past dates
                  lastDate: DateTime.now().add(
                    Duration(days: 365),
                  ), // Up to 1 year from now
                  helpText: 'Select defer date',
                  cancelText: 'Cancel',
                  confirmText: 'Defer',
                );

                if (selectedDate != null) {
                  await _deferPayment(payment, selectedDate);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Select Date',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Update Firebase with deferred date
  Future<void> _deferPayment(
    Map<String, dynamic> payment,
    DateTime newDate,
  ) async {
    try {
      final landlordId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final paymentId = payment['payment_id'] ?? payment['id'] ?? '';

      // If paymentId is not directly available, we need to find the document
      if (paymentId.isEmpty) {
        // Query to find the payment document by matching payment details
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(landlordId)
            .collection('payments')
            .where('tenant_id', isEqualTo: payment['tenant_id'])
            .where('property_id', isEqualTo: payment['property_id'])
            .where('due_date', isEqualTo: payment['due_date'])
            .where('amount', isEqualTo: payment['amount'])
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final docId = querySnapshot.docs.first.id;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(landlordId)
              .collection('payments')
              .doc(docId)
              .update({
                'deferred_date': Timestamp.fromDate(newDate),
                'updated_at': Timestamp.now(),
              });
        }
      } else {
        // Direct update using paymentId
        await FirebaseFirestore.instance
            .collection('users')
            .doc(landlordId)
            .collection('payments')
            .doc(paymentId)
            .update({
              'deferred_date': Timestamp.fromDate(newDate),
              'updated_at': Timestamp.now(),
            });
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment deferred to ${DateFormat('MMM dd, yyyy').format(newDate)}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      print('Error deferring payment: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to defer payment. Please try again.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }
}

extension StringCapitalize on String {
  String get capitalizeFirst =>
      this.isNotEmpty ? this[0].toUpperCase() + this.substring(1) : this;
}
