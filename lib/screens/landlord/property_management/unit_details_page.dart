// lib/screens/landlord/property_management/unit_details_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/property_model.dart';
import 'package:payrent_business/screens/landlord/property_management/property_list_page.dart';
import 'package:payrent_business/screens/landlord/property_management/unit_action_bottom_sheet.dart';

class UnitDetailsPage extends StatefulWidget {
  final String propertyId;
  final PropertyUnitModel unit;
  
  const UnitDetailsPage({
    Key? key,
    required this.propertyId,
    required this.unit,
  }) : super(key: key);

  @override
  _UnitDetailsPageState createState() => _UnitDetailsPageState();
}

class _UnitDetailsPageState extends State<UnitDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  DocumentSnapshot? _tenant;
  PropertyModel? _property;
  Map<String, dynamic>? _leaseInfo;
  String? _errorMessage;
  List<DocumentSnapshot> _allProperties = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUnitData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUnitData() async {
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

      // Fetch tenant if assigned
      DocumentSnapshot? tenant;
            print(widget.unit.tenantId);

      if (widget.unit.tenantId != null) {
        tenant = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('tenants')
            .doc(widget.unit.tenantId)
            .get();
        // Fetch lease information
        final leaseSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('properties')
            .doc(widget.propertyId)
            .collection('units')
            .doc(widget.unit.unitId)
            .collection('tenants')
            .doc(widget.unit.tenantId)
            .get();
            
        if (leaseSnapshot.exists) {
          _leaseInfo = leaseSnapshot.data();
        }
      }

      setState(() {
        _property = property;
        _tenant = tenant;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
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
        _allProperties = querySnapshot.docs;
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
            Get.back();
            Get.back();
            Get.back();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('Unit Details', style: GoogleFonts.poppins()),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
          // Show edit bottom sheet - handled by parent
        },
        backgroundColor: AppTheme.primaryColor,
        label: Text('Manage Unit', style: GoogleFonts.poppins(color: Colors.white,fontSize: 16)),
        icon: Icon(Icons.edit,color: Colors.white,size: 20,),
      ),
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
            onPressed: _fetchUnitData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Header
        FadeInDown(
          duration: Duration(milliseconds: 300),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFA78BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit Number & Status
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Unit ${widget.unit.unitNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _tenant != null
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _tenant != null
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _tenant != null ? 'Occupied' : 'Vacant',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Property Name
                Text(
                  _property?.name ?? 'Unknown Property',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                // Address
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white.withOpacity(0.8), size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _property?.address ?? 'No address',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Tab Bar
        FadeInUp(
          duration: Duration(milliseconds: 300),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Tenant'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Overview Tab
              _buildOverviewTab(),
              // Tenant Tab
              _buildTenantTab(),
              // Documents Tab
              _buildDocumentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit Details Card
          FadeInUp(
            duration: Duration(milliseconds: 400),
            child: _buildCard(
              title: 'Unit Details',
              icon: Icons.apartment_outlined,
              content: Column(
                children: [
                  _buildInfoRow('Unit Type', widget.unit.unitType),
                  _buildInfoRow('Bedrooms', widget.unit.bedrooms.toString()),
                  _buildInfoRow('Bathrooms', widget.unit.bathrooms.toString()),
                  _buildInfoRow('Monthly Rent', '\$${widget.unit.rent.toStringAsFixed(2)}'),
                  if (widget.unit.securityDeposit != null)
                    _buildInfoRow('Security Deposit', '\$${widget.unit.securityDeposit!.toStringAsFixed(2)}'),
                  if (widget.unit.squareFeet != null)
                    _buildInfoRow('Square Feet', '${widget.unit.squareFeet} sq ft'),
                  if (widget.unit.notes != null && widget.unit.notes!.isNotEmpty)
                    _buildInfoRow('Notes', widget.unit.notes!),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Financial Summary
          FadeInUp(
            duration: Duration(milliseconds: 500),
            child: _buildCard(
              title: 'Financial Summary',
              icon: Icons.attach_money,
              content: Column(
                children: [
                  _buildInfoRow('Rent Amount', '\$${widget.unit.rent.toStringAsFixed(2)}'),
                  _buildInfoRow('Annual Income', '\$${(widget.unit.rent * 12).toStringAsFixed(2)}'),
                  if (_tenant != null) ...[
                    _buildInfoRow(
                      'Occupancy Status',
                      'Occupied',
                      valueColor: Colors.green,
                    ),
                    if (_leaseInfo != null) ...[
                      _buildInfoRow(
                        'Security Deposit',
                        '\$${(_leaseInfo?['securityDeposit'] ?? 0).toStringAsFixed(2)}',
                      ),
                      _buildInfoRow(
                        'Lease Start',
                        _formatTimestamp(_leaseInfo?['startDate']),
                      ),
                      _buildInfoRow(
                        'Lease End',
                        _formatTimestamp(_leaseInfo?['endDate']),
                      ),
                    ],
                  ] else
                    _buildInfoRow(
                      'Occupancy Status',
                      'Vacant - No Income',
                      valueColor: Colors.orange,
                    ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Actions
          FadeInUp(
            duration: Duration(milliseconds: 600),
            child: _buildCard(
              title: 'Quick Actions',
              icon: Icons.flash_on,
              content: Column(
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit Unit Details',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 8),
                  _buildActionButton(
                    icon: _tenant != null ? Icons.person_off : Icons.person_add,
                    label: _tenant != null ? 'Change Tenant' : 'Assign Tenant',
                    color: _tenant != null ? Colors.orange : Colors.green,
                    onTap: () {
                      _showAssignTenantBottomSheet(widget.unit);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantTab() {
    if (_tenant == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No Tenant Assigned',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This unit is currently vacant',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _showAssignTenantBottomSheet(widget.unit);
              },
              icon: Icon(Icons.person_add),
              label: Text('Assign Tenant'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    final tenantData = _tenant!.data() as Map<String, dynamic>;
    final firstName = tenantData['firstName'] ?? '';
    final lastName = tenantData['lastName'] ?? '';
    final email = tenantData['email'] ?? 'No email provided';
    final phone = tenantData['phone'] ?? 'No phone provided';
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant Profile Card
          FadeInUp(
            duration: Duration(milliseconds: 400),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 1,
              shadowColor: Colors.black.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Avatar and Basic Info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                          radius: 30,
                          child: Text(
                            '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$firstName $lastName',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tenant since ${_formatTimestamp(tenantData['leaseStartDate'])}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    // Contact Details
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 18, color: AppTheme.primaryColor),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  email,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 18, color: AppTheme.primaryColor),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  phone,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Lease Details
          FadeInUp(
            duration: Duration(milliseconds: 500),
            child: _buildCard(
              title: 'Lease Information',
              icon: Icons.description_outlined,
              content: Column(
                children: [
                  _buildInfoRow(
                    'Lease Start',
                    _formatTimestamp(tenantData['leaseStartDate']),
                  ),
                  _buildInfoRow(
                    'Lease End',
                    _formatTimestamp(tenantData['leaseEndDate']),
                  ),
                  _buildInfoRow(
                    'Monthly Rent',
                    '\$${(tenantData['rentAmount'] ?? 0).toStringAsFixed(2)}',
                  ),
                  if (tenantData['securityDeposit'] != null)
                    _buildInfoRow(
                      'Security Deposit',
                      '\$${tenantData['securityDeposit'].toStringAsFixed(2)}',
                    ),
                  _buildInfoRow(
                    'Rent Due Day',
                    '${tenantData['rentDueDay'] ?? 1}${_getDaySuffix(tenantData['rentDueDay'] ?? 1)} of each month',
                  ),
                  _buildInfoRow(
                    'Days Remaining',
                    _calculateDaysRemaining(tenantData['leaseEndDate']),
                    valueColor: _calculateRemainingColor(tenantData['leaseEndDate']),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Actions
          FadeInUp(
            duration: Duration(milliseconds: 600),
            child: _buildCard(
              title: 'Tenant Actions',
              icon: Icons.settings_outlined,
              content: Column(
                children: [
                  _buildActionButton(
                    icon: Icons.receipt_long_outlined,
                    label: 'View Lease Documents',
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Coming soon: Lease documents viewer')),
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  _buildActionButton(
                    icon: Icons.message_outlined,
                    label: 'Message Tenant',
                    color: Colors.green,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Coming soon: Tenant messaging')),
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  _buildActionButton(
                    icon: Icons.person_remove_outlined,
                    label: 'Remove Tenant',
                    color: Colors.red,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('To remove tenant, return to property details')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Coming Soon',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Unit-specific document management will be available in a future update',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    icon,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
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
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Not specified';
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('MMM d, yyyy').format(date);
    }
    
    return 'Invalid date';
  }
  
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
  
  String _calculateDaysRemaining(Timestamp? endTimestamp) {
    if (endTimestamp == null) return 'No end date';
    
    final endDate = endTimestamp.toDate();
    final now = DateTime.now();
    
    if (endDate.isBefore(now)) {
      return 'Expired';
    }
    
    final daysRemaining = endDate.difference(now).inDays;
    return '$daysRemaining days';
  }
  
  Color? _calculateRemainingColor(Timestamp? endTimestamp) {
    if (endTimestamp == null) return null;
    
    final endDate = endTimestamp.toDate();
    final now = DateTime.now();
    
    if (endDate.isBefore(now)) {
      return Colors.red;
    }
    
    final daysRemaining = endDate.difference(now).inDays;
    
    if (daysRemaining <= 30) {
      return Colors.orange;
    } else if (daysRemaining <= 60) {
      return Colors.amber;
    }
    
    return Colors.green;
  }
}