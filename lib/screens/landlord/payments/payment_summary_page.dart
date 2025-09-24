import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/payment_controller.dart';
import 'package:payrent_business/controllers/property_controller.dart';
import 'package:payrent_business/controllers/tenant_controller.dart';
import 'package:payrent_business/screens/landlord/payments/payment_detail_page.dart';
import 'package:payrent_business/screens/landlord/property_management/property_detail_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_detail_page.dart';

class PaymentSummaryPage extends StatefulWidget {
  const PaymentSummaryPage({super.key});

  @override
  State<PaymentSummaryPage> createState() => _PaymentSummaryPageState();
}

class _PaymentSummaryPageState extends State<PaymentSummaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'This Month', 'Last Month', 'Overdue'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Use controllers instead of static data
  final PropertyController _propertyController = Get.find<PropertyController>();
  final PaymentController _paymentController = Get.find<PaymentController>();
  final TenantController _tenantController = Get.find<TenantController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch data when page loads
    _loadData();
  }

  Future<void> _loadData() async {
    await _propertyController.fetchProperties();
    await _tenantController.fetchTenants();
    await _paymentController.fetchPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filter properties based on search query
  List<DocumentSnapshot> _getFilteredProperties() {
    List<DocumentSnapshot> filteredProperties = _propertyController.properties;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredProperties = filteredProperties.where((property) {
        final data = property.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final address = (data['address'] ?? '').toString().toLowerCase();
        final searchLower = _searchQuery.toLowerCase();
        
        return name.contains(searchLower) || address.contains(searchLower);
      }).toList();
    }
    
    return filteredProperties;
  }

  // Filter tenants based on search query and filter selection
  List<DocumentSnapshot> _getFilteredTenants() {
    List<DocumentSnapshot> filteredTenants = _tenantController.tenants;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTenants = filteredTenants.where((tenant) {
        final data = tenant.data() as Map<String, dynamic>;
        
        final firstName = (data['firstName'] ?? '').toString().toLowerCase();
        final lastName = (data['lastName'] ?? '').toString().toLowerCase();
        final fullName = '$firstName $lastName'.toLowerCase();
        final propertyName = (data['propertyName'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final searchLower = _searchQuery.toLowerCase();
        
        return fullName.contains(searchLower) || 
               propertyName.contains(searchLower) || 
               email.contains(searchLower);
      }).toList();
    }
    
    // Apply time-based filter
    if (_selectedFilter == 'Overdue') {
      // Get payments that are overdue
      final overduePayments = _paymentController.payments.where((payment) {
        final data = payment.data() as Map<String, dynamic>;
        final bool isLate = data['isLate'] ?? false;
        final String status = data['status'] ?? '';
        
        return isLate && status == 'pending';
      }).toList();
      
      // Get tenant IDs with overdue payments
      final overdueTenantIds = overduePayments.map((payment) {
        final data = payment.data() as Map<String, dynamic>;
        return data['tenantId'] ?? '';
      }).toSet();
      
      // Filter tenants to only those with overdue payments
      filteredTenants = filteredTenants.where((tenant) {
        return overdueTenantIds.contains(tenant.id);
      }).toList();
    } else if (_selectedFilter == 'This Month') {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      
      // Get payments due this month
      final thisMonthPayments = _paymentController.payments.where((payment) {
        final data = payment.data() as Map<String, dynamic>;
        if (data['dueDate'] == null) return false;
        
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final dueMonth = DateTime(dueDate.year, dueDate.month);
        return dueMonth.isAtSameMomentAs(currentMonth);
      }).toList();
      
      // Get tenant IDs with payments due this month
      final thisMonthTenantIds = thisMonthPayments.map((payment) {
        final data = payment.data() as Map<String, dynamic>;
        return data['tenantId'] ?? '';
      }).toSet();
      
      // Filter tenants to only those with payments due this month
      filteredTenants = filteredTenants.where((tenant) {
        return thisMonthTenantIds.contains(tenant.id);
      }).toList();
    } else if (_selectedFilter == 'Last Month') {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1);
      
      // Get payments due last month
      final lastMonthPayments = _paymentController.payments.where((payment) {
        final data = payment.data() as Map<String, dynamic>;
        if (data['dueDate'] == null) return false;
        
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final dueMonth = DateTime(dueDate.year, dueDate.month);
        return dueMonth.isAtSameMomentAs(lastMonth);
      }).toList();
      
      // Get tenant IDs with payments due last month
      final lastMonthTenantIds = lastMonthPayments.map((payment) {
        final data = payment.data() as Map<String, dynamic>;
        return data['tenantId'] ?? '';
      }).toSet();
      
      // Filter tenants to only those with payments due last month
      filteredTenants = filteredTenants.where((tenant) {
        return lastMonthTenantIds.contains(tenant.id);
      }).toList();
    }
    
    return filteredTenants;
  }

  // Get payments for a specific property
  List<DocumentSnapshot> _getPaymentsForProperty(String propertyId) {
    return _paymentController.payments.where((payment) {
      final data = payment.data() as Map<String, dynamic>;
      return data['propertyId'] == propertyId;
    }).toList();
  }
  
  // Get tenants for a specific property
  List<DocumentSnapshot> _getTenantsForProperty(String propertyId) {
    return _tenantController.tenants.where((tenant) {
      final data = tenant.data() as Map<String, dynamic>;
      return data['propertyId'] == propertyId;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Payment Summary',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
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
            Tab(text: 'Properties'),
            Tab(text: 'Tenants'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Properties Tab
                _buildPropertiesTab(),
                
                // Tenants Tab
                _buildTenantsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesTab() {
    return Obx(() {
      if (_propertyController.isLoading.value || _paymentController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      } else if (_propertyController.errorMessage.isNotEmpty) {
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
                'Error loading properties',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _propertyController.errorMessage.value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      } else {
        final properties = _getFilteredProperties();
        if (properties.isEmpty) {
          return _buildEmptyState('No properties found', 'Try adjusting your search or filters');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: properties.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final property = properties[index];
            return FadeInUp(
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: _buildPropertyCard(property),
            );
          },
        );
      }
    });
  }

  Widget _buildTenantsTab() {
    return Obx(() {
      if (_tenantController.isLoading.value || _paymentController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      } else if (_tenantController.errorMessage.isNotEmpty) {
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
                'Error loading tenants',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tenantController.errorMessage.value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      } else {
        final tenants = _getFilteredTenants();
        if (tenants.isEmpty) {
          return _buildEmptyState('No tenants found', 'Try adjusting your search or filters');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tenants.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final tenant = tenants[index];
            return FadeInUp(
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: _buildTenantCard(tenant),
            );
          },
        );
      }
    });
  }

  Widget _buildPropertyCard(DocumentSnapshot property) {
    final data = property.data() as Map<String, dynamic>;
    
    // Extract basic property info
    final String id = property.id;
    final String name = data['name'] ?? 'Unnamed Property';
    final String address = data['address'] ?? '';
    final String city = data['city'] ?? '';
    final String state = data['state'] ?? '';
    final String zipCode = data['zipCode'] ?? '';
    final String fullAddress = [address, city, state, zipCode].where((s) => s.isNotEmpty).join(', ');
    final String image = 'assets/home.png'; // Use placeholder image
    
    // Get payments associated with this property
    final propertyPayments = _getPaymentsForProperty(id);
    
    // Calculate payment statistics
    double totalRent = 0;
    double collectedRent = 0;
    double pendingRent = 0;
    double overdueRent = 0;
    
    for (final payment in propertyPayments) {
      final paymentData = payment.data() as Map<String, dynamic>;
      final double amount = (paymentData['amount'] is int) 
          ? (paymentData['amount'] as int).toDouble() 
          : (paymentData['amount'] ?? 0.0);
      final String status = paymentData['status'] ?? '';
      final bool isLate = paymentData['isLate'] ?? false;
      
      totalRent += amount;
      
      if (status == 'paid') {
        collectedRent += amount;
      } else if (status == 'pending') {
        if (isLate) {
          overdueRent += amount;
        } else {
          pendingRent += amount;
        }
      }
    }
    
    // Calculate collection rate
    final collectionRate = totalRent > 0 
        ? (collectedRent / totalRent * 100).toInt()
        : 0;
    
    // Get occupancy information
    final propertyTenants = _getTenantsForProperty(id);
    final int totalUnits = data['units'] ?? 1;
    final int occupiedUnits = propertyTenants.length;
    
    return GestureDetector(
      onTap: () {
        _showPropertyPaymentDetails(property);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Property Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Property Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fullAddress,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Payment Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPropertyStatItem(
                    label: 'Total Rent',
                    value: '\$${NumberFormat('#,##0').format(totalRent)}',
                    color: AppTheme.textPrimary,
                  ),
                  _buildPropertyStatItem(
                    label: 'Collected',
                    value: '\$${NumberFormat('#,##0').format(collectedRent)}',
                    color: AppTheme.successColor,
                  ),
                  _buildPropertyStatItem(
                    label: 'Pending',
                    value: '\$${NumberFormat('#,##0').format(pendingRent)}',
                    color: AppTheme.warningColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Collection Rate Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Collection Rate',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '$collectionRate%',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: collectionRate >= 80
                              ? AppTheme.successColor
                              : collectionRate >= 50
                                  ? AppTheme.warningColor
                                  : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.shade200,
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          flex: collectionRate,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: collectionRate >= 80
                                    ? [
                                        const Color(0xFF43A047),
                                        const Color(0xFF388E3C),
                                      ]
                                    : collectionRate >= 50
                                        ? [
                                            const Color(0xFFFFA726),
                                            const Color(0xFFFB8C00),
                                          ]
                                        : [
                                            const Color(0xFFEF5350),
                                            const Color(0xFFE53935),
                                          ],
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 100 - collectionRate,
                          child: const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // View Details Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    _showPropertyPaymentDetails(property);
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(
                    'View Details',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCard(DocumentSnapshot tenant) {
    final data = tenant.data() as Map<String, dynamic>;
    
    // Extract tenant information
    final String id = tenant.id;
    final String firstName = data['firstName'] ?? '';
    final String lastName = data['lastName'] ?? '';
    final String fullName = '$firstName $lastName';
    final String propertyName = data['propertyName'] ?? 'No Property Assigned';
    final String unitNumber = data['unitNumber'] ?? '';
    final double rentAmount = (data['rentAmount'] is int) 
        ? (data['rentAmount'] as int).toDouble() 
        : (data['rentAmount'] ?? 0.0);
    
    // Get tenant's most recent payment status
    String paymentStatus = 'Unknown';
    DateTime? dueDate;
    DateTime? paymentDate;
    
    // Find the most recent payment for this tenant
    final tenantPayments = _paymentController.payments.where((payment) {
      final paymentData = payment.data() as Map<String, dynamic>;
      return paymentData['tenantId'] == id;
    }).toList();
    
    if (tenantPayments.isNotEmpty) {
      // Sort payments by due date (most recent first)
      tenantPayments.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        
        final aDate = aData['dueDate'] != null 
            ? (aData['dueDate'] as Timestamp).toDate() 
            : DateTime(1900);
        final bDate = bData['dueDate'] != null 
            ? (bData['dueDate'] as Timestamp).toDate() 
            : DateTime(1900);
        
        return bDate.compareTo(aDate); // Reverse sort
      });
      
      // Get status from most recent payment
      final recentPayment = tenantPayments.first;
      final recentPaymentData = recentPayment.data() as Map<String, dynamic>;
      
      final String status = recentPaymentData['status'] ?? '';
      final bool isLate = recentPaymentData['isLate'] ?? false;
      
      if (status == 'paid') {
        paymentStatus = 'Paid';
      } else if (status == 'pending' && isLate) {
        paymentStatus = 'Overdue';
      } else if (status == 'pending') {
        paymentStatus = 'Due';
      }
      
      // Get dates
      if (recentPaymentData['dueDate'] != null) {
        dueDate = (recentPaymentData['dueDate'] as Timestamp).toDate();
      }
      
      if (recentPaymentData['paymentDate'] != null) {
        paymentDate = (recentPaymentData['paymentDate'] as Timestamp).toDate();
      }
    }
    
    Color statusColor;
    IconData statusIcon;

    switch (paymentStatus) {
      case 'Paid':
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
            builder: (context) => TenantDetailPage(tenantId: id),
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
                    backgroundImage: const AssetImage('assets/profile.png'),
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 12),
                  // Tenant Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unitNumber.isEmpty ? propertyName : '$propertyName - $unitNumber',
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
                          paymentStatus,
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
                        'Rent Amount',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${NumberFormat('#,##0').format(rentAmount)}',
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
                          color: paymentStatus == 'Overdue'
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
                        paymentStatus == 'Paid'
                            ? 'Payment Date'
                            : 'Status',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        paymentStatus == 'Paid' && paymentDate != null
                            ? DateFormat('dd MMM, yyyy').format(paymentDate)
                            : paymentStatus,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (paymentStatus != 'Paid')
                    OutlinedButton.icon(
                      onPressed: () {
                        // Send payment reminder
                        _showSnackBar('Payment reminder sent to $fullName');
                      },
                      icon: const Icon(Icons.notifications_active_outlined, size: 18),
                      label: const Text('Send Reminder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warningColor,
                        side: BorderSide(color: AppTheme.warningColor),
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      // Find most recent payment to show
                      final payments = _paymentController.payments.where((payment) {
                        final paymentData = payment.data() as Map<String, dynamic>;
                        return paymentData['tenantId'] == id;
                      }).toList();
                      
                      if (payments.isNotEmpty) {
                        // Sort by due date (most recent first)
                        payments.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          
                          final aDate = aData['dueDate'] != null 
                              ? (aData['dueDate'] as Timestamp).toDate() 
                              : DateTime(1900);
                          final bDate = bData['dueDate'] != null 
                              ? (bData['dueDate'] as Timestamp).toDate() 
                              : DateTime(1900);
                          
                          return bDate.compareTo(aDate);
                        });
                        
                        // Navigate to most recent payment
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentDetailPage(paymentId: payments.first.id),
                          ),
                        );
                      } else {
                        _showSnackBar('No payments found for this tenant');
                      }
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View Payment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
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

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 80,
            color: AppTheme.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  void _showPropertyPaymentDetails(DocumentSnapshot property) {
    final data = property.data() as Map<String, dynamic>;
    final id = property.id;
    final name = data['name'] ?? 'Unnamed Property';
    final address = data['address'] ?? '';
    final city = data['city'] ?? '';
    final state = data['state'] ?? '';
    final zipCode = data['zipCode'] ?? '';
    final fullAddress = [address, city, state, zipCode].where((s) => s.isNotEmpty).join(', ');
    
    // Get tenants for this property
    final tenants = _getTenantsForProperty(id);
    
    // Get property payment summary
    final propertySummary = _paymentController.getPaymentSummaryByProperty(id);
    final totalDue = propertySummary['totalDue'] ?? 0.0;
    final totalPaid = propertySummary['totalPaid'] ?? 0.0;
    final totalPending = propertySummary['totalPending'] ?? 0.0;
    final totalLate = propertySummary['totalLate'] ?? 0.0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Property Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.home_outlined),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailsPage(propertyId: id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    fullAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Payment Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildPropertyPaymentStatCard(
                          title: 'Total Rent',
                          value: '\$${NumberFormat('#,##0').format(totalDue)}',
                          icon: Icons.attach_money,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPropertyPaymentStatCard(
                          title: 'Collected',
                          value: '\$${NumberFormat('#,##0').format(totalPaid)}',
                          icon: Icons.check_circle_outline,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPropertyPaymentStatCard(
                          title: 'Pending',
                          value: '\$${NumberFormat('#,##0').format(totalPending)}',
                          icon: Icons.access_time,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPropertyPaymentStatCard(
                          title: 'Overdue',
                          value: '\$${NumberFormat('#,##0').format(totalLate)}',
                          icon: Icons.warning_amber_rounded,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tenants List
                  Text(
                    'Tenants',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: tenants.isEmpty
                        ? Center(
                            child: Text(
                              'No tenants found for this property',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: tenants.length,
                            itemBuilder: (context, index) {
                              final tenant = tenants[index];
                              return _buildTenantPaymentListItem(tenant);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPropertyPaymentStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantPaymentListItem(DocumentSnapshot tenant) {
    final data = tenant.data() as Map<String, dynamic>;
    final id = tenant.id;
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final fullName = '$firstName $lastName';
    final unitNumber = data['unitNumber'] ?? '';
    final double rentAmount = (data['rentAmount'] is int) 
        ? (data['rentAmount'] as int).toDouble() 
        : (data['rentAmount'] ?? 0.0);
    
    // Get tenant's most recent payment status
    String paymentStatus = 'Unknown';
    
    // Find the most recent payment for this tenant
    final tenantPayments = _paymentController.payments.where((payment) {
      final paymentData = payment.data() as Map<String, dynamic>;
      return paymentData['tenantId'] == id;
    }).toList();
    
    if (tenantPayments.isNotEmpty) {
      // Sort payments by due date (most recent first)
      tenantPayments.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        
        final aDate = aData['dueDate'] != null 
            ? (aData['dueDate'] as Timestamp).toDate() 
            : DateTime(1900);
        final bDate = bData['dueDate'] != null 
            ? (bData['dueDate'] as Timestamp).toDate() 
            : DateTime(1900);
        
        return bDate.compareTo(aDate); // Reverse sort
      });
      
      // Get status from most recent payment
      final recentPayment = tenantPayments.first;
      final recentPaymentData = recentPayment.data() as Map<String, dynamic>;
      
      final String status = recentPaymentData['status'] ?? '';
      final bool isLate = recentPaymentData['isLate'] ?? false;
      
      if (status == 'paid') {
        paymentStatus = 'Paid';
      } else if (status == 'pending' && isLate) {
        paymentStatus = 'Overdue';
      } else if (status == 'pending') {
        paymentStatus = 'Due';
      }
    }
    
    Color statusColor;
    IconData statusIcon;

    switch (paymentStatus) {
      case 'Paid':
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TenantDetailPage(tenantId: id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: const AssetImage('assets/profile.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      unitNumber.isEmpty ? 'No unit assigned' : unitNumber,
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
                    '\$${NumberFormat('#,##0').format(rentAmount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          paymentStatus,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}