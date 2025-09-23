import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/tenant_controller.dart';
import 'package:payrent_business/screens/landlord/tenant_management/add_tenant_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_detail_page.dart';

class TenantListPage extends StatefulWidget {
  const TenantListPage({super.key});

  @override
  State<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends State<TenantListPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'active', 'archived'];
  
  // Use TenantController instead of static data
  final TenantController _tenantController = Get.find<TenantController>();
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Refresh tenant data when page loads
    _tenantController.fetchTenants();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Tenants',
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) => _buildFilterChip(filter)).toList(),
              ),
            ),
          ),
          
          // Tenants Count
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Showing ${_tenantController.filteredTenants.length} Tenants',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          )),
          
          const SizedBox(height: 8),
          
          // Tenant List with loading state
          Expanded(
            child: Obx(() {
              if (_tenantController.isLoading.value) {
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
                        onPressed: () => _tenantController.fetchTenants(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (_tenantController.filteredTenants.isEmpty) {
                return _buildEmptyState();
              } else {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tenantController.filteredTenants.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final tenant = _tenantController.filteredTenants[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      child: _buildTenantCard(tenant),
                    );
                  },
                );
              }
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTenantPage()),
          ).then((_) {
            // Refresh the list when returning from add tenant page
            _tenantController.fetchTenants();
          });
        },
        backgroundColor: AppTheme.primaryColor,
        label: Row(
          children: [
            const Icon(Icons.person_add_outlined, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Add Tenant',
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
    
    String displayText = filter;
    if (filter == 'active') {
      displayText = 'Active';
    } else if (filter == 'archived') {
      displayText = 'Archived';
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        
        if (filter == 'All') {
          _tenantController.filteredTenants.value = _tenantController.tenants;
        } else {
          _tenantController.filterTenants(_selectedFilter);
        }
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
                  )
                ]
              : null,
        ),
        child: Text(
          displayText,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
  
  Widget _buildTenantCard(DocumentSnapshot tenant) {
    final data = tenant.data() as Map<String, dynamic>;
    
    // Extract values with null safety
    final String id = tenant.id;
    final String firstName = data['firstName'] ?? '';
    final String lastName = data['lastName'] ?? '';
    final String fullName = '$firstName $lastName';
    final String email = data['email'] ?? '';
    final String phone = data['phone'] ?? '';
    final String propertyName = data['propertyName'] ?? '';
    final String propertyId = data['propertyId'] ?? '';
    final String unitNumber = data['unitNumber'] ?? '';
    final double rentAmount = (data['rentAmount'] is int) 
        ? (data['rentAmount'] as int).toDouble() 
        : (data['rentAmount'] ?? 0.0);
    final String status = data['status'] ?? 'active';
    final bool isArchived = data['isArchived'] ?? false;
    
    // Get dates with fallbacks for missing data
    DateTime? leaseStartDate;
    DateTime? leaseEndDate;
    
    try {
      if (data['leaseStartDate'] != null) {
        leaseStartDate = (data['leaseStartDate'] as Timestamp).toDate();
      }
      
      if (data['leaseEndDate'] != null) {
        leaseEndDate = (data['leaseEndDate'] as Timestamp).toDate();
      }
    } catch (e) {
      print('Error parsing tenant dates: $e');
    }
    
    // Determine status color based on payment status
    Color statusColor = AppTheme.textLight;
    String displayStatus = status;
    
    switch (status) {
      case 'active':
        statusColor = AppTheme.successColor;
        displayStatus = 'Active';
        break;
      case 'archived':
        statusColor = AppTheme.textLight;
        displayStatus = 'Archived';
        break;
      default:
        statusColor = AppTheme.textLight;
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TenantDetailPage(tenantId: id),
          ),
        ).then((_) {
          // Refresh the list when returning from detail page
          _tenantController.fetchTenants();
        });
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Tenant Image (using placeholder if no image)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: const AssetImage('assets/profile.png'),
                    backgroundColor: Colors.grey.shade200,
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.home_outlined,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                propertyName.isEmpty 
                                    ? 'No property assigned' 
                                    : '$propertyName${unitNumber.isNotEmpty ? " - $unitNumber" : ""}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            displayStatus,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    label: 'Rent',
                    value: '\$${rentAmount.toStringAsFixed(0)}/mo',
                    icon: Icons.attach_money_outlined,
                  ),
                  _buildInfoItem(
                    label: 'Lease Start',
                    value: leaseStartDate != null 
                        ? DateFormat('dd MMM').format(leaseStartDate) 
                        : 'Not set',
                    icon: Icons.calendar_today_outlined,
                  ),
                  _buildInfoItem(
                    label: 'Lease End',
                    value: leaseEndDate != null 
                        ? DateFormat('dd MMM').format(leaseEndDate) 
                        : 'Not set',
                    icon: Icons.event_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textLight),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
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
                'Filter Tenants',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('All Tenants'),
                leading: Radio(
                  value: 'All',
                  groupValue: _selectedFilter,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    _tenantController.filteredTenants.value = _tenantController.tenants;
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Active Tenants'),
                leading: Radio(
                  value: 'active',
                  groupValue: _selectedFilter,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    _tenantController.filterTenants('active');
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Archived Tenants'),
                leading: Radio(
                  value: 'archived',
                  groupValue: _selectedFilter,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    _tenantController.filterTenants('archived');
                    Navigator.pop(context);
                  },
                ),
              ),
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
          'Search Tenants',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter tenant name, email, or property',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            // _tenantController.searchTenants(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _tenantController.fetchTenants();
              Navigator.pop(context);
            },
            child: const Text('CLEAR'),
          ),
          ElevatedButton(
            onPressed: () {
              // _tenantController.searchTenants(_searchController.text);
              Navigator.pop(context);
            },
            child: const Text('SEARCH'),
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
          Icon(
            Icons.people_outline_rounded,
            size: 80,
            color: AppTheme.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tenants found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Add your first tenant to get started'
                : 'No tenants match the current filter',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTenantPage()),
              ).then((_) {
                // Refresh the list when returning from add tenant page
                _tenantController.fetchTenants();
              });
            },
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Add Tenant'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}