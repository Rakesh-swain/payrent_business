// lib/screens/landlord/property_management/property_details_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/property_model.dart';
import 'package:payrent_business/models/tenant_model.dart';
import 'package:payrent_business/models/mandate_model.dart';
import 'package:payrent_business/models/account_information_model.dart';
import 'package:payrent_business/screens/landlord/mandate/create_mandate_page.dart';
import 'package:payrent_business/screens/landlord/mandate/new_create_mandate_page.dart';
import 'package:payrent_business/screens/landlord/property_management/edit_property_page.dart';
import 'package:payrent_business/screens/landlord/property_management/unit_action_bottom_sheet.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_detail_page.dart';

class PropertyDetailsPage extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsPage({Key? key, required this.propertyId})
    : super(key: key);

  @override
  _PropertyDetailsPageState createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  PropertyModel? _property;
  List<DocumentSnapshot> _propertyDocuments = [];
  List<DocumentSnapshot>  _tenants = [];
  List<DocumentSnapshot> _mandates = [];
  AccountInformation? _landlordAccountInfo;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  String _paymentFrequency = 'Monthly';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPropertyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPropertyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch property data
      final propertyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .get();

      if (!propertyDoc.exists) {
        throw Exception('Property not found');
      }

      // Convert to property model
      final property = PropertyModel.fromFirestore(propertyDoc);

      // Extract payment frequency from document data
      final propertyData = propertyDoc.data() as Map<String, dynamic>?;
      final paymentFreq = propertyData?['paymentFrequency'] as String?;

      // Fetch property documents
      final documentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .collection('documents')
          .orderBy('uploadDate', descending: true)
          .get();

      // Fetch tenants for this property
      final tenantsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tenants');

      final tenantDocs = await tenantsRef.get();

      final matchedTenants = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      await Future.wait(
        tenantDocs.docs.map((tenantDoc) async {
          final tenantPropsSnapshot = await tenantsRef
              .doc(tenantDoc.id)
              .collection('properties')
              .where('propertyId', isEqualTo: widget.propertyId)
              .get();

          if (tenantPropsSnapshot.docs.isNotEmpty) {
            matchedTenants.add(tenantDoc);
          }
        }),
      );
      final tenantSnapshot = matchedTenants; 
      // Fetch mandates for this property
      final mandateSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mandates')
          .where('propertyId', isEqualTo: widget.propertyId)
          .get();

      // Fetch landlord account information
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
        _property = property;
        _propertyDocuments = documentsSnapshot.docs;
        _tenants = tenantSnapshot;
        _mandates = mandateSnapshot.docs;
        _landlordAccountInfo = landlordAccountInfo;
        _paymentFrequency = paymentFreq ?? 'Monthly';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadDocument() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      // Create storage reference
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('properties')
          .child(widget.propertyId)
          .child('documents')
          .child(
            DateTime.now().millisecondsSinceEpoch.toString() + '_' + fileName,
          );

      // Upload file with progress tracking
      final uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      // Wait for upload to complete
      await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Save document metadata to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .collection('documents')
          .add({
            'name': fileName,
            'url': downloadUrl,
            'uploadDate': FieldValue.serverTimestamp(),
            'type': path.extension(fileName),
            'size': await file.length(),
          });

      // Refresh documents list
      final documentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .collection('documents')
          .orderBy('uploadDate', descending: true)
          .get();

      setState(() {
        _propertyDocuments = documentsSnapshot.docs;
        _isUploading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Document uploaded successfully')));
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading document: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
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
            _errorMessage ?? 'Something went wrong',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchPropertyData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_property == null) return SizedBox.shrink();

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 200.0,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 15),
              title: Text(
                _property!.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 25,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromARGB(255, 11, 12, 61),
                          Color(0xFFA78BFA),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.home_rounded,
                      size: 64,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Edit Property',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPropertyPage(
                        propertyId: widget.propertyId,
                        property: _property!,
                      ),
                    ),
                  ).then((updated) {
                    if (updated == true) {
                      _fetchPropertyData();
                    }
                  });
                },
              ),
            ],
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(),
                tabs: const [
                  Tab(text: 'Property Info'),
                  Tab(text: 'Tenants'),
                  Tab(text: 'Maintenance'),
                ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPropertyInfoTab(),
          _buildTenantsTab(),
          _buildMaintenanceTab(),
        ],
      ),
    );
  }

  Widget _buildPropertyInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Property Details Card
        FadeInUp(
          duration: Duration(milliseconds: 300),
          child: _buildInfoCard(
            title: 'Property Details',
            icon: Icons.home_outlined,
            content: Column(
              children: [
                _buildInfoRow('Property Type', _property?.type ?? 'No data'),
                _buildInfoRow(
                  'Units',
                  _property?.isMultiUnit == true
                      ? 'Multi-Unit (${_property?.units.length ?? 0} units)'
                      : 'Single Unit',
                ),
                _buildInfoRow(
                  'Description',
                  _property?.description ?? 'No description',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Address Card
        FadeInUp(
          duration: Duration(milliseconds: 400),
          child: _buildInfoCard(
            title: 'Address',
            icon: Icons.location_on_outlined,
            content: Column(
              children: [
                _buildInfoRow('Street', _property?.address ?? 'No data'),
                _buildInfoRow('City', _property?.city ?? 'No data'),
                _buildInfoRow('State', _property?.state ?? 'No data'),
                _buildInfoRow('Zip Code', _property?.zipCode ?? 'No data'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Financial Details Card
        FadeInUp(
          duration: Duration(milliseconds: 500),
          child: _buildInfoCard(
            title: 'Financial Summary',
            icon: Icons.attach_money,
            content: Column(
              children: [
                // _buildInfoRow('Payment Frequency', _getPaymentFrequency()),
                _buildInfoRow(
                  'Total Rent Amount',
                  'OMR${_calculateTotalRent().toStringAsFixed(0)}',
                ),
                // _buildInfoRow(
                //   'Average Unit Rent',
                //   'OMR${_calculateAverageRent().toStringAsFixed(0)}',
                // ),
                _buildInfoRow(
                  'Occupancy Rate',
                  '${_calculateOccupancyRate().toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Documents Section
        FadeInUp(
          duration: Duration(milliseconds: 600),
          child: _buildDocumentsSection(),
        ),
      ],
    );
  }

  Widget _buildTenantsTab() {
    final propertyUnits = _property?.units ?? [];
    final hasUnits = propertyUnits.isNotEmpty;

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Occupancy summary card
        FadeInUp(
          duration: Duration(milliseconds: 300),
          child: _buildInfoCard(
            title: 'Occupancy Summary',
            icon: Icons.people_outline,
            content: Column(
              children: [
                _buildInfoRow('Total Units', '${propertyUnits.length}'),
                _buildInfoRow(
                  'Occupied Units',
                  '${propertyUnits.where((unit) => unit.tenantId != null).length}',
                ),
                _buildInfoRow(
                  'Vacant Units',
                  '${propertyUnits.where((unit) => unit.tenantId == null).length}',
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24),

        // Title
        Text(
          'Units & Tenants',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),

        SizedBox(height: 16),

        hasUnits
            ? ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: propertyUnits.length,
                itemBuilder: (context, index) {
                  final unit = propertyUnits[index];
                  final tenantDoc = unit.tenantId != null
                      ? _tenants.where((t) => t.id == unit.tenantId).firstOrNull
                      : null;
                  return _buildUnitTenantCard(
                    unit,
                    tenantDoc,
                    tenantDoc?.id,
                  );
                },
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No units available',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add units to this property to assign tenants',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildUnitTenantCard(
    PropertyUnitModel unit,
    DocumentSnapshot? tenantDoc,
    String? tenantId,
  ) {
    final hasTenant = tenantDoc != null;
    Map<String, dynamic>? tenantData;

    if (hasTenant) {
      tenantData = tenantDoc!.data() as Map<String, dynamic>;
    }

    return FadeInUp(
      duration: Duration(milliseconds: 300),
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unit header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFF0EEFE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE0D6FD), width: 1),
                    ),
                    child: Text(
                      'Unit ${unit.unitNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C3AED), // Deep purple
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasTenant
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasTenant
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      hasTenant ? 'Occupied' : 'Vacant',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasTenant ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Unit details
              Row(
                children: [
                  _buildUnitDetailItem('Type', unit.unitType),
                  _buildUnitDetailItem(
                    'Size',
                    '${unit.bedrooms} bed, ${unit.bathrooms} bath',
                  ),
                  _buildUnitDetailItem(
                    'Rent Amount',
                  'OMR${unit.rent}/mo',
                    isHighlighted: true,
                  ),
                ],
              ),

              // Divider if tenant exists
              if (hasTenant) Divider(height: 32),

              // Tenant section if exists
              if (hasTenant) ...[
                Text(
                  'Current Tenant',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      child: Text(
                        '${tenantData?['firstName']?[0] ?? ''}${tenantData?['lastName']?[0] ?? ''}'
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tenantData?['firstName'] ?? 'Unknown'} ${tenantData?['lastName'] ?? ''}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          if (tenantData?['phone'] != null)
                            Text(
                              tenantData!['phone'],
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Get.to(TenantDetailPage(tenantId: tenantId!));
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text('Details'),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
                _buildMandateButton(unit, tenantDoc),
                SizedBox(height: 12),
                _buildLeaseInfo(tenantData),
              ] else ...[
                SizedBox(height: 16),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAssignTenantBottomSheet(unit),
                    icon: Icon(Icons.person_add_outlined),
                    label: Text('Assign Tenant'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitDetailItem(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isHighlighted ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaseInfo(Map<String, dynamic>? tenantData) {
    if (tenantData == null) return SizedBox.shrink();

    final leaseStartTimestamp = tenantData['leaseStartDate'] as Timestamp?;
    final leaseEndTimestamp = tenantData['leaseEndDate'] as Timestamp?;

    final leaseStart = leaseStartTimestamp?.toDate();
    final leaseEnd = leaseEndTimestamp?.toDate();

    final dateFormat = DateFormat('MMM d, yyyy');
    final startDateStr = leaseStart != null
        ? dateFormat.format(leaseStart)
        : 'Not set';
    final endDateStr = leaseEnd != null
        ? dateFormat.format(leaseEnd)
        : 'Not set';

    // Calculate days remaining in lease
    String daysRemaining = 'N/A';
    if (leaseEnd != null) {
      final today = DateTime.now();
      final difference = leaseEnd.difference(today).inDays;

      if (difference < 0) {
        daysRemaining = 'Expired';
      } else {
        daysRemaining = '$difference days';
      }
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lease Information',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      startDateStr,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Date',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(endDateStr, style: GoogleFonts.poppins(fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      daysRemaining,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: daysRemaining == 'Expired'
                            ? Colors.red
                            : daysRemaining != 'N/A' &&
                                  int.tryParse(daysRemaining.split(' ')[0]) !=
                                      null &&
                                  int.parse(daysRemaining.split(' ')[0]) < 30
                            ? Colors.orange
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Coming Soon',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Maintenance tracking and service request features will be available in a future update.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  child: Icon(
                    Icons.description_outlined,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Documents',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                if (!_isUploading)
                  TextButton.icon(
                    icon: Icon(Icons.upload_file, size: 16),
                    label: Text('Upload'),
                    onPressed: _uploadDocument,
                  ),
              ],
            ),
            if (_isUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_propertyDocuments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No documents yet',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload property documents like leases, receipts, and contracts',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _propertyDocuments.length,
                itemBuilder: (context, index) {
                  final document =
                      _propertyDocuments[index].data() as Map<String, dynamic>;
                  return _buildDocumentItem(
                    document,
                    _propertyDocuments[index].id,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> document, String documentId) {
    final fileName = document['name'] ?? 'Unnamed document';
    final fileType = document['type'] ?? '.pdf';
    final uploadDate = document['uploadDate'] as Timestamp?;
    final fileUrl = document['url'] as String?;
    final fileSize = document['size'] as int?;

    IconData fileIcon;
    Color fileColor;

    // Determine file icon and color based on extension
    if (fileType.contains('pdf')) {
      fileIcon = Icons.picture_as_pdf;
      fileColor = Colors.red;
    } else if (fileType.contains('doc')) {
      fileIcon = Icons.article_outlined;
      fileColor = Colors.blue;
    } else if (fileType.contains('jpg') ||
        fileType.contains('jpeg') ||
        fileType.contains('png')) {
      fileIcon = Icons.image;
      fileColor = Colors.green;
    } else {
      fileIcon = Icons.insert_drive_file;
      fileColor = Colors.amber;
    }

    // Format date
    String dateStr = 'Unknown date';
    if (uploadDate != null) {
      final date = uploadDate.toDate();
      dateStr = DateFormat('MMM d, yyyy').format(date);
    }

    // Format file size
    String sizeStr = 'Unknown size';
    if (fileSize != null) {
      if (fileSize < 1024) {
        sizeStr = '$fileSize B';
      } else if (fileSize < 1024 * 1024) {
        sizeStr = '${(fileSize / 1024).toStringAsFixed(1)} KB';
      } else {
        sizeStr = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Open document
          if (fileUrl != null) {
            // Launch URL
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fileColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(fileIcon, color: fileColor, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$dateStr • $sizeStr',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onPressed: () {
                  _showDocumentOptions(documentId, document);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentOptions(String documentId, Map<String, dynamic> document) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.visibility_outlined, color: Colors.blue),
              title: Text('View Document'),
              onTap: () {
                Navigator.pop(context);
                // Launch URL
              },
            ),
            ListTile(
              leading: Icon(Icons.download_outlined, color: Colors.green),
              title: Text('Download'),
              onTap: () {
                Navigator.pop(context);
                // Download logic
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteDocument(documentId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDocument(String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete this document? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final userId = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('properties')
                    .doc(widget.propertyId)
                    .collection('documents')
                    .doc(documentId)
                    .delete();

                // Refresh documents list
                _fetchPropertyData();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Document deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting document: $e')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  double _calculateTotalRent() {
    double total = 0;
    for (var unit in _property?.units ?? []) {
      total += unit.rent;
    }
    return total;
  }

  double _calculateAverageRent() {
    final units = _property?.units ?? [];
    if (units.isEmpty) return 0;
    return _calculateTotalRent() / units.length;
  }

  double _calculateOccupancyRate() {
    final units = _property?.units ?? [];
    if (units.isEmpty) return 0;

    final occupiedUnits = units.where((unit) => unit.tenantId != null).length;
    return (occupiedUnits / units.length) * 100;
  }

  String _getPaymentFrequency() {
    return _paymentFrequency;
  }

  Widget _buildMandateButton(
    PropertyUnitModel unit,
    DocumentSnapshot tenantDoc,
  ) {
    final tenantData = tenantDoc.data() as Map<String, dynamic>;
    final tenantId = tenantDoc.id;

    // Check if mandate exists for this unit and tenant
    final mandateExists = _mandates.any((mandate) {
      final mandateData = mandate.data() as Map<String, dynamic>;
      return mandateData['tenantId'] == tenantId &&
          mandateData['unitId'] == unit.unitId && (mandateData['status'].toString().toLowerCase() == 'pending' || mandateData['status'].toString().toLowerCase() == 'success');
    });
    final mandateExist = _mandates.any((mandate) {
      final mandateData = mandate.data() as Map<String, dynamic>;
      return mandateData['tenantId'] == tenantId &&
          mandateData['unitId'] == unit.unitId && mandateData['status'] == 'accepted';
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
      return  Container(
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
                                );
    }
    else if(mandateExists){
        return  Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
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
                    propertyId: widget.propertyId,
                  ),
                ),
              ).then((result) {
                // Refresh data when returning from mandate creation
                if (result == true) {
                  _fetchPropertyData();
                }
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

  // void _showCreateMandateDialog(
  //   PropertyUnitModel unit,
  //   DocumentSnapshot tenantDoc,
  // ) {
  //   final tenantData = tenantDoc.data() as Map<String, dynamic>;

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(
  //         'Create Mandate',
  //         style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
  //       ),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'This will create a payment mandate between:',
  //               style: GoogleFonts.poppins(fontSize: 14),
  //             ),
  //             const SizedBox(height: 16),

  //             // Landlord Account Info
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.blue.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(color: Colors.blue.withOpacity(0.3)),
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     'Landlord Account (Receiver)',
  //                     style: GoogleFonts.poppins(
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.blue,
  //                       fontSize: 12,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Text('Name: ${_landlordAccountInfo!.accountHolderName}'),
  //                   Text('Account: ${_landlordAccountInfo!.accountNumber}'),
  //                   Text('Bank: ${_landlordAccountInfo!.bankBic}'),
  //                   Text('Branch: ${_landlordAccountInfo!.branchCode}'),
  //                 ],
  //               ),
  //             ),

  //             const SizedBox(height: 12),

  //             // Tenant Account Info
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.green.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(color: Colors.green.withOpacity(0.3)),
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     'Tenant Account (Payer)',
  //                     style: GoogleFonts.poppins(
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.green,
  //                       fontSize: 12,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Text('Name: ${tenantData['db_account_holder_name']}'),
  //                   Text('Account: ${tenantData['db_account_number']}'),
  //                   Text('Bank: ${tenantData['db_bank_bic']}'),
  //                   Text('Branch: ${tenantData['db_branch_code']}'),
  //                 ],
  //               ),
  //             ),

  //             const SizedBox(height: 16),

  //             // Payment Details
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.orange.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(color: Colors.orange.withOpacity(0.3)),
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     'Payment Details',
  //                     style: GoogleFonts.poppins(
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.orange,
  //                       fontSize: 12,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Text('Amount: OMR${unit.rent}'),
  //                   Text(
  //                     'Frequency: ${tenantData['paymentFrequency'] ?? 'Monthly'}',
  //                   ),
  //                   Text('Unit: ${unit.unitNumber}'),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             Navigator.pop(context);
  //             await _createMandate(unit, tenantDoc);
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppTheme.primaryColor,
  //             foregroundColor: Colors.white,
  //           ),
  //           child: Text('Create Mandate'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Future<void> _createMandate(
  //   PropertyUnitModel unit,
  //   DocumentSnapshot tenantDoc,
  // ) async {
  //   try {
  //     final userId = FirebaseAuth.instance.currentUser?.uid;
  //     if (userId == null) throw Exception('User not logged in');

  //     final tenantData = tenantDoc.data() as Map<String, dynamic>;

  //     final mandate = MandateModel(
  //       landlordId: userId,
  //       tenantId: tenantDoc.id,
  //       propertyId: widget.propertyId,
  //       unitId: unit.unitId,
  //       landlordAccountHolderName: _landlordAccountInfo!.accountHolderName,
  //       landlordAccountNumber: _landlordAccountInfo!.accountNumber,
  //       landlordIdType: _landlordAccountInfo!.idType.value,
  //       landlordIdNumber: _landlordAccountInfo!.idNumber,
  //       landlordBankBic: _landlordAccountInfo!.bankBic,
  //       landlordBranchCode: _landlordAccountInfo!.branchCode,
  //       tenantAccountHolderName: tenantData['db_account_holder_name'],
  //       tenantAccountNumber: tenantData['db_account_number'],
  //       tenantIdType: tenantData['db_id_type'],
  //       tenantIdNumber: tenantData['db_id_number'],
  //       tenantBankBic: tenantData['db_bank_bic'],
  //       tenantBranchCode: tenantData['db_branch_code'],
  //       rentAmount: unit.rent,
  //       paymentFrequency: tenantData['paymentFrequency'] ?? 'monthly',
  //       startDate: DateTime.now(),
  //       createdAt: DateTime.now(),
  //       updatedAt: DateTime.now(),
  //     );

  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(userId)
  //         .collection('mandates')
  //         .add(mandate.toFirestore());

  //     // Refresh data to show updated mandate status
  //     await _fetchPropertyData();

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Mandate created successfully'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error creating mandate: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  Future<void> _fetchProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching properties: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showAssignTenantBottomSheet(PropertyUnitModel unit) {
    // Will be implemented with tenant selection functionality
    // Showing a placeholder for now
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return UnitActionBottomSheet(
          propertyId: widget.propertyId,
          unit: unit,
          onComplete: () {
            _fetchProperties();
            Get.back();
            Get.back();
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Color(0xFFF8F9FB), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
