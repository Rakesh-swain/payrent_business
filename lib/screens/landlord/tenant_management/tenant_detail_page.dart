import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/account_information_model.dart';
import 'package:payrent_business/models/property_model.dart';
import 'package:payrent_business/screens/landlord/mandate/installment_dialog.dart';
import 'package:payrent_business/screens/landlord/mandate/mandate_status_page.dart';
import 'package:payrent_business/screens/landlord/mandate/new_create_mandate_page.dart';
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

class _TenantDetailPageState extends State<TenantDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TenantController _tenantController = Get.find<TenantController>();
  final PropertyController _propertyController = Get.find<PropertyController>();
  final AuthController _authController = Get.find<AuthController>();
  AccountInformation? _landlordAccountInfo;
  DocumentSnapshot? _tenantDoc;
  List<Map<String, dynamic>> _tenantProperties = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, List<Map<String, dynamic>>> _propertyPayments = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to show the correct tab in IndexedStack
      }
    });

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
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Fetch tenant basic data
      final tenantRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tenants')
          .doc(widget.tenantId);

      _tenantDoc = await tenantRef.get();

      if (!_tenantDoc!.exists) {
        throw Exception('Tenant not found');
      }

      // Fetch all properties associated with this tenant from subcollection
      final propertiesSnapshot = await tenantRef.collection('properties').get();

      _tenantProperties.clear();
      _propertyPayments.clear();

      for (var propDoc in propertiesSnapshot.docs) {
        final propData = propDoc.data();
        propData['docId'] = propDoc.id; // Store document ID for reference

        // Fetch actual property details if propertyId exists
        if (propData['propertyId'] != null) {
          try {
            final propertyDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('properties')
                .doc(propData['propertyId'])
                .get();

            if (propertyDoc.exists) {
              final propertyData = propertyDoc.data() as Map<String, dynamic>;
              // Merge property data with lease data
              propData['propertyDetails'] = propertyData;
            }
          } catch (e) {
            print('Error fetching property details: $e');
          }
        }

        _tenantProperties.add(propData);

        // Generate payments for this property
        _generatePaymentsForProperty(propData);
      }
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      AccountInformation? landlordAccountInfo;
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['cr_account_holder_name'] != null) {
          landlordAccountInfo = AccountInformation.fromMap(userData);
        }
      }
      setState(() {
        _landlordAccountInfo = landlordAccountInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showInstallmentsDialog(
    int numberOfInstallments,
    int paymentAmount,
    String selectedFrequency,
    DateTime startDate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InstallmentsDialog(
          installments: numberOfInstallments,
          amount: paymentAmount,
          frequency: selectedFrequency,
          startDate: startDate,
        ),
      ),
    );
  }

  Future<PropertyUnitModel?> _fetchUnit(
    String propertyId,
    String unitId,
  ) async {
    final propertyDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('properties')
        .doc(propertyId)
        .get();

    if (!propertyDoc.exists) return null;

    final data = propertyDoc.data() as Map<String, dynamic>?;
    if (data == null || data['units'] == null) return null;

    final units = (data['units'] as List<dynamic>);
    final unitData = units.firstWhere(
      (u) => u['unitId'] == unitId,
      orElse: () => null,
    );

    if (unitData == null) return null;

    return PropertyUnitModel.fromMap(unitData as Map<String, dynamic>);
  }

  Widget _buildMandateButton(
    PropertyUnitModel unit,
    DocumentSnapshot tenantDoc,
    List<DocumentSnapshot> _mandates,
    String propertyId,
  ) {
    final tenantData = tenantDoc.data() as Map<String, dynamic>;
    final tenantId = tenantDoc.id;

    // Check if mandate exists for this unit and tenant
    final mandateExists = _mandates.any((mandate) {
      final mandateData = mandate.data() as Map<String, dynamic>;
      return mandateData['tenantId'] == tenantId &&
          mandateData['unitId'] == unit.unitId &&
          (mandateData['status'].toString().toLowerCase() == 'pending' ||
              mandateData['status'].toString().toLowerCase() == 'success');
    });
    final mandateExist = _mandates.any((mandate) {
      final mandateData = mandate.data() as Map<String, dynamic>;
      return mandateData['tenantId'] == tenantId &&
          mandateData['unitId'] == unit.unitId &&
          mandateData['status'] == 'accepted';
    });

    // Check if both landlord and tenant have account information
    final landlordHasAccountInfo = _landlordAccountInfo != null;
    final tenantHasAccountInfo =
        tenantData['db_account_holder_name'] != null &&
        tenantData['db_account_number'] != null &&
        tenantData['db_bank_bic'] != null &&
        tenantData['db_branch_code'] != null;

    final canCreateMandate = landlordHasAccountInfo && tenantHasAccountInfo;

    if (mandateExists) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Text(
          'This mandate request is pending.\nAwaiting confirmation of mandate request.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.orange[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (mandateExists) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Text(
          'This mandate request has been accepted.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.green[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: canCreateMandate
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewCreateMandatePage(
                    unit: unit,
                    tenantDoc: tenantDoc,
                    landlordAccountInfo: _landlordAccountInfo!,
                    propertyId: propertyId,
                  ),
                ),
              ).then((result) {
                // Refresh data when returning from mandate creation
                if (result == true) {}
              });
            }
          : () {
              String missingInfo = '';
              if (!landlordHasAccountInfo) {
                missingInfo =
                    'Please complete your account information in settings.';
              } else if (!tenantHasAccountInfo) {
                missingInfo = 'Tenant account information is incomplete.';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(missingInfo),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            },
      icon: Icon(Icons.account_balance, size: 16),
      label: Text('Create Mandate'),
      style: ElevatedButton.styleFrom(
        backgroundColor: canCreateMandate ? AppTheme.primaryColor : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _generatePaymentsForProperty(Map<String, dynamic> propertyData) {
    final propertyId = propertyData['propertyId'] ?? propertyData['docId'];
    final leaseStartDate = propertyData['leaseStartDate'] != null
        ? (propertyData['leaseStartDate'] as Timestamp).toDate()
        : null;
    final leaseEndDate = propertyData['leaseEndDate'] != null
        ? (propertyData['leaseEndDate'] as Timestamp).toDate()
        : null;
    final rentAmount = (propertyData['rentAmount'] is int)
        ? (propertyData['rentAmount'] as int).toDouble()
        : (propertyData['rentAmount'] ?? 0.0);
    final paymentFrequency = propertyData['paymentFrequency'] ?? 'Monthly';
    final rentDueDay = propertyData['rentDueDay'] ?? 1;
    final propertyName = propertyData['propertyName'] ?? 'Unknown Property';
    final unitNumber = propertyData['unitNumber'] ?? '';

    if (leaseStartDate == null || leaseEndDate == null) return;

    List<Map<String, dynamic>> payments = [];

    DateTime currentPaymentDate = DateTime(
      leaseStartDate.year,
      leaseStartDate.month,
      rentDueDay,
    );
    final today = DateTime.now();
    int paymentNumber = 1;

    while (currentPaymentDate.isBefore(leaseEndDate) ||
        currentPaymentDate.isAtSameMomentAs(leaseEndDate)) {
      if (currentPaymentDate.isAfter(today.add(const Duration(days: 90)))) {
        break;
      }

      String status;
      if (currentPaymentDate.isBefore(today)) {
        status = 'paid';
      } else if (currentPaymentDate.year == today.year &&
          currentPaymentDate.month == today.month) {
        status = 'due';
      } else {
        status = 'upcoming';
      }

      payments.add({
        'id': 'payment_${propertyId}_${paymentNumber}',
        'title':
            '${_getPaymentTitle(paymentFrequency)} - $propertyName${unitNumber.isNotEmpty ? " ($unitNumber)" : ""}',
        'amount': rentAmount,
        'dueDate': currentPaymentDate,
        'status': status,
        'frequency': paymentFrequency,
        'paymentNumber': paymentNumber,
        'formattedDueDate': DateFormat(
          'MMM dd, yyyy',
        ).format(currentPaymentDate),
        'isOverdue': currentPaymentDate.isBefore(today) && status != 'paid',
        'propertyName': propertyName,
        'unitNumber': unitNumber,
        'propertyId': propertyId,
      });

      // Calculate next payment date
      switch (paymentFrequency.toLowerCase()) {
        case 'weekly':
          currentPaymentDate = currentPaymentDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          currentPaymentDate = DateTime(
            currentPaymentDate.month == 12
                ? currentPaymentDate.year + 1
                : currentPaymentDate.year,
            currentPaymentDate.month == 12 ? 1 : currentPaymentDate.month + 1,
            rentDueDay,
          );
          break;
        case 'quarterly':
          currentPaymentDate = DateTime(
            currentPaymentDate.month + 3 > 12
                ? currentPaymentDate.year + 1
                : currentPaymentDate.year,
            (currentPaymentDate.month + 3) > 12
                ? (currentPaymentDate.month + 3) - 12
                : currentPaymentDate.month + 3,
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
            currentPaymentDate.month == 12
                ? currentPaymentDate.year + 1
                : currentPaymentDate.year,
            currentPaymentDate.month == 12 ? 1 : currentPaymentDate.month + 1,
            rentDueDay,
          );
      }

      paymentNumber++;
    }

    _propertyPayments[propertyId] = payments.reversed.toList();
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
          title: Text(
            'Tenant Details',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
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
          title: Text(
            'Tenant Details',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchTenantData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final tenantData = _tenantDoc!.data() as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tenant Details',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500),
        ),
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
      body: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tenant Header
              _buildTenantHeader(tenantData),
              const SizedBox(height: 16),

              // Tab Bar
              _buildTabBar(),
              const SizedBox(height: 16),

              // Tab Content as Column
              IndexedStack(
                index: _tabController.index,
                children: [
                  _buildDetailsTab(tenantData),
                  _buildPaymentsTab(),
                  _buildDocumentsTab(tenantData),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTenantHeader(Map<String, dynamic> tenantData) {
    final firstName = tenantData['firstName'] ?? '';
    final lastName = tenantData['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    // Calculate total rent from all properties
    double totalRent = 0;
    for (var prop in _tenantProperties) {
      totalRent += (prop['rentAmount'] ?? 0).toDouble();
    }

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
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                        .toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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

            // Summary Info
            Row(
              children: [
                Expanded(
                  child: _buildHeaderStat(
                    'Properties',
                    _tenantProperties.length.toString(),
                    Icons.home_outlined,
                  ),
                ),
                Expanded(
                  child: _buildHeaderStat(
                    'Total Rent',
                    'OMR ${totalRent.toStringAsFixed(0)}',
                    Icons.attach_money_outlined,
                  ),
                ),
                Expanded(
                  child: _buildHeaderStat(
                    'Status',
                    _capitalizeFirst(tenantData['status'] ?? 'active'),
                    Icons.check_circle_outline,
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

  Widget _buildDetailsTab(Map<String, dynamic> tenantData) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Information
            _buildInfoCard('Personal Information', Icons.person_outline, [
              _buildDetailRow(
                'First Name',
                tenantData['firstName'] ?? 'Not provided',
              ),
              _buildDetailRow(
                'Last Name',
                tenantData['lastName'] ?? 'Not provided',
              ),
              _buildDetailRow('Email', tenantData['email'] ?? 'Not provided'),
              _buildDetailRow('Phone', tenantData['phone'] ?? 'Not provided'),
              if (tenantData['status'] != null)
                _buildDetailRow('Status', tenantData['status']),
            ]),

            const SizedBox(height: 16),

            // Properties & Leases
            if (_tenantProperties.isNotEmpty) ...[
              Text(
                'Properties & Lease Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._tenantProperties.map((prop) => _buildPropertyLeaseCard(prop)),
            ],

            const SizedBox(height: 16),

            // Account Information
            _buildInfoCard(
              'Account Information',
              Icons.account_balance_outlined,
              [
                _buildDetailRow(
                  'Account Holder',
                  tenantData['db_account_holder_name'] ?? 'Not provided',
                ),
                _buildDetailRow(
                  'Account Number',
                  tenantData['db_account_number'] ?? 'Not provided',
                ),
                if (tenantData['db_id_type'] != null)
                  _buildDetailRow('ID Type', tenantData['db_id_type']),
                _buildDetailRow(
                  'ID Number',
                  tenantData['db_id_number'] ?? 'Not provided',
                ),
                _buildDetailRow(
                  'Bank',
                  tenantData['db_bank_bic'] ?? 'Not provided',
                ),
                _buildDetailRow(
                  'Branch Code',
                  tenantData['db_branch_code'] ?? 'Not provided',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyLeaseCard(Map<String, dynamic> propertyData) {
    final propertyDetails =
        propertyData['propertyDetails'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                child: const Icon(
                  Icons.home_work_outlined,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyData['propertyName'] ?? 'Unknown Property',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (propertyData['unitNumber'] != null &&
                        propertyData['unitNumber'].toString().isNotEmpty)
                      Text(
                        'Unit: ${propertyData['unitNumber']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (propertyData['propertyId'] != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    Get.to(
                      () => PropertyDetailsPage(
                        propertyId: propertyData['propertyId'],
                      ),
                    );
                  },
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Property Details
          if (propertyData['propertyAddress'] != null)
            _buildDetailRow('Address', propertyData['propertyAddress']),

          // Lease Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lease Start',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(propertyData['leaseStartDate']),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lease End',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(propertyData['leaseEndDate']),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rent Amount',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'OMR ${(propertyData['rentAmount'] ?? 0).toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequency',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _capitalizeFirst(
                        propertyData['paymentFrequency'] ?? 'Monthly',
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (propertyData['securityDeposit'] != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Deposit Amount',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'OMR ${propertyData['securityDeposit'].toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('mandates')
                .where('propertyId', isEqualTo: propertyData['propertyId'])
                .where('unitId', isEqualTo: propertyData['unitId'])
                .snapshots(),
            builder: (context, mandateSnapshot) {
              if (mandateSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(strokeWidth: 2);
              }

              final mandates = mandateSnapshot.data?.docs ?? [];
              // No mandate → show Create Mandate button
              if (mandates.isEmpty) {
                final tenantId = widget.tenantId;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('tenants')
                      .doc(tenantId)
                      .get(),
                  builder: (context, tenantSnapshot) {
                    if (tenantSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox();
                    }
                    if (!tenantSnapshot.hasData ||
                        !tenantSnapshot.data!.exists) {
                      return const Text(
                        'Tenant information not found. Please assign tenant to create mandate.',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      );
                    }
                    AccountInformation? landlordAccountInfo;
                    if (tenantSnapshot.hasData && tenantSnapshot.data!.exists) {
                      final userData =
                          tenantSnapshot.data!.data() as Map<String, dynamic>;
                      if (userData['cr_account_holder_name'] != null) {
                        landlordAccountInfo = AccountInformation.fromMap(
                          userData,
                        );
                      }
                    }
                    // ✅ Pass landlordAccountInfo, mandates, and propertyId
                    final tenantId = widget.tenantId;
                    return FutureBuilder<PropertyUnitModel?>(
                      future: _fetchUnit(
                        propertyData['propertyId'],
                        propertyData['unitId'],
                      ),
                      builder: (context, unitSnapshot) {
                        if (unitSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(
                            strokeWidth: 2,
                          );
                        }
                        final propertyUnit = unitSnapshot.data;
                        if (propertyUnit == null) {
                          return const Text(
                            'Unit details not found.',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        return _buildMandateButton(
                          propertyUnit, // ✅ Pass the PropertyUnitModel here
                          tenantSnapshot.data!, // tenant DocumentSnapshot
                          mandates, // mandates list
                          propertyData['propertyId'], // propertyId
                        );
                      },
                    );
                  },
                );
              }

              // Mandate exists → show based on status
              final mandateData = mandates.first.data() as Map<String, dynamic>;
              final status = mandateData['mmsStatus'].toString().toLowerCase();
              final noOfPayments = mandateData['noOfInstallments'];
              final frequency = mandateData['paymentFrequency'];
              final rent = mandateData['rentAmount'];
              final startDate = (mandateData['startDate'] as Timestamp)
                  .toDate();

              if (status == 'success' || status == 'pending') {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'This mandate request is pending.\nAwaiting confirmation of mandate request.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => Get.to(
                        () => MandateStatusPage(mandateId: mandates.first.id),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text(
                        'Check Mandate Status',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        _showInstallmentsDialog(
                          noOfPayments,
                          rent,
                          frequency,
                          startDate,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text(
                        'Check Payment Schedule',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              } else if (status == 'accepted') {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Mandate creation successful',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return _buildEmptyPaymentsState();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payments')
          .where('tenant_id', isEqualTo: widget.tenantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading payments: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyPaymentsState();
        }

        // Group payments by property_id
        Map<String, List<Map<String, dynamic>>> propertyPayments = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final propertyId = data['property_id'] ?? 'unknown';
          propertyPayments.putIfAbsent(propertyId, () => []);
          propertyPayments[propertyId]!.add({
            ...data,
            'docId': doc.id, // store payment document id
          });
        }

        // Sort payments inside each property by schedule number
        propertyPayments.forEach((propertyId, payments) {
          payments.sort(
            (a, b) => (a['schedule_number'] ?? 0).compareTo(
              b['schedule_number'] ?? 0,
            ),
          );
        });

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: propertyPayments.entries.map((entry) {
              final propertyId = entry.key;
              final payments = entry.value;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('properties')
                    .doc(propertyId)
                    .get(),
                builder: (context, propSnapshot) {
                  String propertyName = 'Unknown Property';
                  String unitNumber = '';

                  if (propSnapshot.hasData && propSnapshot.data!.exists) {
                    final propertyData =
                        propSnapshot.data!.data() as Map<String, dynamic>;
                    propertyName = propertyData['name'] ?? 'Unknown Property';

                    // Find the unit name from units array by unit_id
                    final unitId = payments.first['unit_id'];
                    if (propertyData['units'] != null) {
                      final unitData = (propertyData['units'] as List)
                          .firstWhere(
                            (u) => u['unitId'] == unitId,
                            orElse: () => null,
                          );
                      if (unitData != null)
                        unitNumber = unitData['unitNumber'] ?? '';
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPropertyPaymentSection({
                        'propertyId': propertyId,
                        'propertyName': propertyName,
                        'unitNumber': unitNumber,
                      }, payments),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPropertyPaymentSection(
    Map<String, dynamic> property,
    List<Map<String, dynamic>> payments,
  ) {
    // payments.sort(
    //   (a, b) => (a['due_date'] as DateTime).compareTo(b['due_date'] as DateTime),
    // );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.home_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${property['propertyName']}${property['unitNumber'] != null && property['unitNumber'].toString().isNotEmpty ? " (${property['unitNumber']})" : ""}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              Text(
                '${payments.length} payments',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...payments.map((payment) => _buildPaymentItem(payment)).toList(),
      ],
    );
  }

  Widget _buildPaymentSummaryCard(List<Map<String, dynamic>> allPayments) {
    final paidPayments = allPayments.where((p) => p['status'] == 'paid').length;
    final duePayments = allPayments.where((p) => p['status'] == 'due').length;
    final overduePayments = allPayments
        .where((p) => p['isOverdue'] == true)
        .length;
    final totalAmount = allPayments.fold<double>(
      0.0,
      (sum, p) => sum + (p['amount'] as double),
    );

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
            'Payment Summary (All Properties)',
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
                  'Total',
                  allPayments.length.toString(),
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
                'OMR ${NumberFormat('#,##0.00').format(totalAmount)}',
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

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
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
    final now = DateTime.now();
    Color statusColor;
    IconData statusIcon;
    String statusText;

   final dueDate = (payment['due_date'] as Timestamp?)?.toDate() ?? now;
    final scheduleNumber = payment['schedule_number'] ?? 0;

    // Determine status
    switch (payment['status']) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Paid';
        break;

      case 'pending':
        if (dueDate.isBefore(now)) {
          statusColor = Colors.red;
          statusIcon = Icons.warning;
          statusText = 'Overdue';
        } else {
          statusColor = Colors.blue;
          statusIcon = Icons.schedule_outlined;
          statusText = 'Upcoming';
        }
        break;

      case 'due':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Due';
        break;

      case 'upcoming':
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.schedule_outlined;
        statusText = 'Upcoming';
    }

    final propertyName = payment['propertyName'] ?? 'Unknown Property';
    final unitNumber = payment['unitNumber'] ?? '';
    final frequency = payment['frequency'] ?? '';

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
                // Schedule number on top
                Text(
                  'Schedule No. $scheduleNumber',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                // Payment title: frequency + property + unit
                Text(
                  '$frequency Rent',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Due date
                Text(
                  'Due: ${DateFormat('dd MMM yyyy').format(payment['due_date'].toDate())}',
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
                '\OMR${NumberFormat('#,##0.00').format(payment['amount'])}',
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
                  statusText,
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
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
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
                      const SnackBar(
                        content: Text('Document upload coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    Icon(
                      Icons.folder_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
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
              if (_tenantDoc != null)
                _buildOptionItem(
                  icon: Icons.home_outlined,
                  label: 'View Property',
                  onTap: () {
                    Navigator.pop(context);
                    final tenantData =
                        _tenantDoc!.data() as Map<String, dynamic>;
                    if (tenantData['propertyId'] != null) {
                      Get.to(
                        () => PropertyDetailsPage(
                          propertyId: tenantData['propertyId'],
                        ),
                      );
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
          content: const Text(
            'Are you sure you want to delete this tenant? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _tenantController.deleteTenant(
                  widget.tenantId,
                );
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
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
