import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentListPage extends StatelessWidget {
  final String type; // 'due rent today', 'collection today', 'overdue', total earning this month
  const PaymentListPage({Key? key, required this.type}) : super(key: key);

  String get _pageTitle {
  switch (type) {
    case 'collection today':
      return 'Collection Today';
    case 'overdue':
      return 'Overdue Rent';
    case 'total earning this month':
      return 'Earnings This Month';
    default:
      return 'Due Rent Today';
  }
}

Color get _primaryColor {
  switch (type) {
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
  switch (type) {
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


  @override
  Widget build(BuildContext context) {
    final landlordId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

final startOfMonth = DateTime(now.year, now.month, 1);
final startOfNextMonth =
    DateTime(now.year, now.month + 1, 1); // automatically handles December
    // 🔹 Define Firestore Query based on type
    Query<Map<String, dynamic>> baseQuery =
    FirebaseFirestore.instance.collection('users').doc(landlordId).collection('payments');

if (type == 'due rent today') {
  baseQuery = baseQuery
      .where('due_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('due_date', isLessThan: Timestamp.fromDate(endOfDay));
} else if (type == 'collection today') {
  baseQuery = baseQuery
      .where('due_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('due_date', isLessThan: Timestamp.fromDate(endOfDay))
      .where('status', isEqualTo: 'paid');
} else if (type == 'overdue') {
  baseQuery = baseQuery
      .where('due_date', isLessThan: Timestamp.fromDate(startOfDay))
      .where('status', isEqualTo: 'pending');
} else if (type == 'total earning this month') {
  baseQuery = baseQuery
      .where('due_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .where('due_date', isLessThan: Timestamp.fromDate(startOfNextMonth))
      .where('status', isEqualTo: 'paid');
}


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
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: baseQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            );
          }

          final payments = snapshot.data!.docs;
          if (payments.isEmpty) return _buildEmptyState();

          double totalAmount = payments.fold(
            0.0,
            (sum, doc) => sum + (doc.data()['amount'] ?? 0),
          );

          return Column(
            children: [
              _buildHeader(payments.length, totalAmount),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final payment = payments[index].data();
                    return _PaymentCard(
                      landlordId: landlordId,
                      payment: payment,
                      primaryColor: _primaryColor,
                      type: type,
                    );
                  },
                ),
              ),
            ],
          );
        },
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
                  type == 'due rent today'
                      ? 'Due today'
                      : type == 'collection today'
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
                'ر.ع ${totalAmount.toStringAsFixed(2)}',
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
            type == 'due rent today'
                ? 'No rent due today'
                : type == 'collection today'
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
