import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/complaints/pdf_viewer_page.dart';
import 'package:payrent_business/screens/landlord/complaints/raise_complaint_page.dart';
import 'package:payrent_business/screens/landlord/complaints/complaint_status_page.dart';

class ComplaintListPage extends StatefulWidget {
  const ComplaintListPage({Key? key}) : super(key: key);

  @override
  State<ComplaintListPage> createState() => _ComplaintListPageState();
}

class _ComplaintListPageState extends State<ComplaintListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _selectedPaymentIds = [];
  bool _selectAll = false;
  bool _showMemoFetched = false;
  Map<String, bool> _memoStatus = {}; // Track which payments have memos

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Raise Complaint',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Fetch Memo Button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _selectedPaymentIds.isNotEmpty ? _fetchMemo : () {},
              icon: Icon(Icons.file_download_outlined, size: 18),
              label: Text('Fetch Memo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(isWeb),
    );
  }

  Widget _buildBody(bool isWeb) {
    return Column(
      children: [
        // Header with Select All
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Checkbox(
                value: _selectAll,
                onChanged: _toggleSelectAll,
                activeColor: AppTheme.primaryColor,
              ),
              Text(
                'Select All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_selectedPaymentIds.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedPaymentIds.length} selected',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Payment List
        Expanded(child: _buildPaymentsList(isWeb)),
      ],
    );
  }

  Widget _buildPaymentsList(bool isWeb) {
    final landlordId = _auth.currentUser?.uid ?? '';
    if (landlordId.isEmpty) return _buildEmptyState('Please login to continue');

    // Query for overdue and failed payments
    final query = _firestore
        .collection('users')
        .doc(landlordId)
        .collection('payments')
        .where('landlord_id', isEqualTo: landlordId)
        .where('status', whereIn: ['pending', 'failed'])
        .orderBy('due_date', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print(snapshot.error);
          return Center(
            child: Text(
              'Error loading payments: ${snapshot.error}',
              style: GoogleFonts.poppins(color: AppTheme.errorColor),
            ),
          );
        }

        final payments = snapshot.data?.docs ?? [];
        if (payments.isEmpty) {
          return _buildEmptyState('No overdue or failed payments found');
        }

        // Filter for overdue and failed payments
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final filteredPayments = payments.where((payment) {
          final data = payment.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          final dueDate = (data['due_date'] as Timestamp?)?.toDate();

          // Include failed payments or overdue payments
          return status == 'failed' ||
              (status == 'pending' &&
                  dueDate != null &&
                  dueDate.isBefore(startOfToday));
        }).toList();

        if (filteredPayments.isEmpty) {
          return _buildEmptyState('No overdue or failed payments found');
        }

        return isWeb
            ? _buildWebGrid(filteredPayments)
            : _buildMobileList(filteredPayments);
      },
    );
  }

  Widget _buildWebGrid(List<QueryDocumentSnapshot> payments) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: payments.map((payment) {
          final data = payment.data() as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildPaymentCard(payment, data, true),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<QueryDocumentSnapshot> payments) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final data = payment.data() as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildPaymentCard(payment, data, false),
        );
      },
    );
  }

  Widget _buildPaymentCard(
    QueryDocumentSnapshot payment,
    Map<String, dynamic> data,
    bool isWeb,
  ) {
    final paymentId = payment.id;
    final amount = (data['amount'] ?? 0.0).toDouble();
    final status = data['status'] ?? '';
    final dueDate = (data['due_date'] as Timestamp?)?.toDate();
    final tenantId = data['tenant_id'] ?? '';
    final propertyId = data['property_id'] ?? '';
    final unitId = data['unit_id'] ?? '';
    final hasMemo =
        (_memoStatus[paymentId] ?? false) || (data.containsKey('memo_file'));
    final isSelected = _selectedPaymentIds.contains(paymentId);

    // Determine display status
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final displayStatus = status == 'failed'
        ? 'failed'
        : (status == 'pending' &&
              dueDate != null &&
              dueDate.isBefore(startOfToday))
        ? 'overdue'
        : status;

    Color statusColor = displayStatus == 'failed' ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => _togglePaymentSelection(paymentId),
                activeColor: AppTheme.primaryColor,
              ),
              Expanded(child: _buildTenantName(tenantId)),
              if (hasMemo)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewerPage(
                          pdfUrl: data['memo_file'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              if (hasMemo)
                ElevatedButton(
                  onPressed: () => _navigateToRaiseComplaint(payment, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'Raise Complaint',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Property and Unit Info
          _buildPropertyUnitInfo(propertyId, unitId),

          const SizedBox(height: 12),

          // Payment Details Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'OMR ${amount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      dueDate != null
                          ? DateFormat('MMM dd, yyyy').format(dueDate)
                          : 'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  displayStatus.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          // Check Complaint Status Button (if complaint exists)
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _checkComplaintStatus(paymentId),
              icon: Icon(Icons.info_outline, size: 16),
              label: Text('Check Complaint Status'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantName(String tenantId) {
    final landlordId = _auth.currentUser?.uid ?? '';
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore
          .collection('users')
          .doc(landlordId)
          .collection('tenants')
          .doc(tenantId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Text('Loading...', style: GoogleFonts.poppins(fontSize: 14));

        final tenantData = snapshot.data?.data() as Map<String, dynamic>?;
        final tenantName =
            '${tenantData?['firstName']} ${tenantData?['lastName']}' ??
            'Unknown Tenant';

        return Text(
          tenantName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        );
      },
    );
  }

  Widget _buildPropertyUnitInfo(String propertyId, String unitId) {
    final landlordId = _auth.currentUser?.uid ?? '';
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore
          .collection('users')
          .doc(landlordId)
          .collection('properties')
          .doc(propertyId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Text('Loading...', style: GoogleFonts.poppins(fontSize: 12));

        final propertyData = snapshot.data?.data() as Map<String, dynamic>?;
        final propertyName = propertyData?['name'] ?? 'Unknown Property';
        final units = propertyData?['units'] as List<dynamic>? ?? [];
        final unit = units.firstWhere(
          (u) => u['unitId'] == unitId,
          orElse: () => {'unitNumber': 'Unknown Unit'},
        );
        final unitName = unit['unitNumber'] ?? 'Unknown Unit';

        return Text(
          '$propertyName - $unitName',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_problem_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        // Add all payment IDs to selection
        _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .collection('payments')
            .where('landlord_id', isEqualTo: _auth.currentUser?.uid ?? '')
            .where('status', whereIn: ['pending', 'failed'])
            .get()
            .then((snapshot) {
              final now = DateTime.now();
              final startOfToday = DateTime(now.year, now.month, now.day);

              final validPayments = snapshot.docs
                  .where((payment) {
                    final data = payment.data();
                    final status = data['status'] ?? '';
                    final dueDate = (data['due_date'] as Timestamp?)?.toDate();

                    return status == 'failed' ||
                        (status == 'pending' &&
                            dueDate != null &&
                            dueDate.isBefore(startOfToday));
                  })
                  .map((payment) => payment.id)
                  .toList();

              setState(() {
                _selectedPaymentIds = validPayments;
                print(_selectedPaymentIds);
              });
            });
      } else {
        _selectedPaymentIds.clear();
      }
    });
  }

  void _togglePaymentSelection(String paymentId) {
    setState(() {
      if (_selectedPaymentIds.contains(paymentId)) {
        _selectedPaymentIds.remove(paymentId);
      } else {
        _selectedPaymentIds.add(paymentId);
      }
      _selectAll = false; // Reset select all when individual selection changes
    });
  }

  Future<void> _fetchMemo() async {
    if (_selectedPaymentIds.isEmpty) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Fetching memos...', style: GoogleFonts.poppins()),
          ],
        ),
      ),
    );

    try {
      // Check for memo files in Firestore for selected payments
      for (String paymentId in _selectedPaymentIds) {
        final memoDoc = await _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .collection('payments')
            .doc(paymentId)
            .get();

        if (memoDoc.exists) {
          final data = memoDoc.data();
          final memoFile = data?['memo_file'];

          // ✅ Check if memo_file field exists and is not empty
          if (memoFile != null && memoFile.toString().isNotEmpty) {
            _memoStatus[paymentId] = true;
          } else {
            _memoStatus[paymentId] = false;
          }
        } else {
          _memoStatus[paymentId] = false;
        }
      }

      Navigator.pop(context); // Close loading dialog

      setState(() {
        _showMemoFetched = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Memo fetch completed.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error fetching memos: ${e.toString()}',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToRaiseComplaint(
    QueryDocumentSnapshot payment,
    Map<String, dynamic> data,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RaiseComplaintPage(paymentId: payment.id, paymentData: data),
      ),
    );
  }

  void _checkComplaintStatus(String paymentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintStatusPage(paymentId: paymentId),
      ),
    );
  }
}
