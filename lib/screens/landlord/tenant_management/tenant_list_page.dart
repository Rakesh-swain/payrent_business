import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/tenant_controller.dart';
import 'package:payrent_business/controllers/property_controller.dart';
import 'package:payrent_business/screens/landlord/tenant_management/add_tenant_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/edit_tenant_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_detail_page.dart';
import 'package:payrent_business/widgets/common/app_loading_indicator.dart';

class TenantListPage extends StatefulWidget {
  const TenantListPage({super.key});

  @override
  State<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends State<TenantListPage> {
  final TenantController _tenantController = Get.find<TenantController>();
  final PropertyController _propertyController = Get.find<PropertyController>();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, inactive
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _tenantController.fetchTenants(),
        _propertyController.fetchProperties(),
      ]);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _fetchData();
    setState(() => _isRefreshing = false);
  }

  List<DocumentSnapshot> _getFilteredTenants() {
    var tenants = _tenantController.tenants.value.where((tenant) {
      final data = tenant.data() as Map<String, dynamic>;
      final firstName = (data['firstName'] ?? '').toString().toLowerCase();
      final lastName = (data['lastName'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final phone = (data['phone'] ?? '').toString().toLowerCase();
      final fullName = '$firstName $lastName';

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!fullName.contains(query) &&
            !email.contains(query) &&
            !phone.contains(query)) {
          return false;
        }
      }

      // Get tenant properties safely
      // final properties = (data['properties'] as List<dynamic>?) ?? [];

      // Status filter based on properties
      // if (_selectedFilter == 'active') {
      //   return properties.isNotEmpty;
      // } else if (_selectedFilter == 'inactive') {
      //   return properties.isEmpty;
      // }

      return true;
    }).toList();

    // Sort by tenant name
    tenants.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aName = '${aData['firstName'] ?? ''} ${aData['lastName'] ?? ''}'
          .trim();
      final bName = '${bData['firstName'] ?? ''} ${bData['lastName'] ?? ''}'
          .trim();
      return aName.compareTo(bName);
    });

    return tenants;
  }

  String _getPropertyName(String? propertyId) {
    if (propertyId == null || propertyId.isEmpty) return 'No Property';

    try {
      final property = _propertyController.properties.firstWhere(
        (p) => p.id == propertyId,
      );
      final data = property.data() as Map<String, dynamic>;
      return data['name'] ?? 'Unknown Property';
    } catch (e) {
      return 'Unknown Property';
    }
  }

  String _getTenantStatus(Map<String, dynamic> tenantData) {
    final propertyId = tenantData['propertyId'];
    final leaseEndDate = tenantData['leaseEndDate'];

    if (propertyId == null || propertyId.toString().isEmpty) {
      return 'Inactive';
    }

    if (leaseEndDate != null) {
      final endDate = leaseEndDate is Timestamp
          ? leaseEndDate.toDate()
          : DateTime.tryParse(leaseEndDate.toString());

      if (endDate != null && endDate.isBefore(DateTime.now())) {
        return 'Lease Expired';
      }
    }

    return 'Active';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppTheme.successColor;
      case 'Lease Expired':
        return AppTheme.warningColor;
      case 'Inactive':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  void _showTenantOptions(DocumentSnapshot tenant) {
    final data = tenant.data() as Map<String, dynamic>;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '${data['firstName']} ${data['lastName']}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildOptionTile(
                    icon: Icons.visibility_outlined,
                    title: 'View Details',
                    onTap: () {
                      Navigator.pop(context);
                      _viewTenantDetails(tenant);
                    },
                  ),
                  _buildOptionTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Tenant',
                    onTap: () {
                      Navigator.pop(context);
                      _editTenant(tenant);
                    },
                  ),
                  _buildOptionTile(
                    icon: Icons.payment_outlined,
                    title: 'View Payments',
                    onTap: () {
                      Navigator.pop(context);
                      _viewTenantPayments(tenant);
                    },
                  ),
                  if (data['propertyId'] == null ||
                      data['propertyId'].toString().isEmpty)
                    _buildOptionTile(
                      icon: Icons.home_outlined,
                      title: 'Assign Property',
                      onTap: () {
                        Navigator.pop(context);
                        _assignProperty(tenant);
                      },
                    ),
                  _buildOptionTile(
                    icon: Icons.delete_outline,
                    title: 'Delete Tenant',
                    color: AppTheme.errorColor,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteTenant(tenant);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textPrimary),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: color ?? AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _viewTenantDetails(DocumentSnapshot tenant) {
    Get.to(TenantDetailPage(tenantId: tenant.id));
  }

  void _editTenant(DocumentSnapshot tenant) {
    Get.to(EditTenantPage(tenantId: tenant.id));
  }

  void _viewTenantPayments(DocumentSnapshot tenant) {
    // Navigate to tenant payments page
    Get.snackbar('Info', 'Tenant payments page coming soon!');
  }

  void _assignProperty(DocumentSnapshot tenant) {
    // Navigate to property assignment page
    Get.snackbar('Info', 'Property assignment coming soon!');
  }

  void _deleteTenant(DocumentSnapshot tenant) {
    final data = tenant.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Tenant',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ${data['firstName']} ${data['lastName']}? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _tenantController.deleteTenant(tenant.id);
                Get.snackbar('Success', 'Tenant deleted successfully');
                _refreshData();
              } catch (e) {
                Get.snackbar('Error', 'Failed to delete tenant: $e');
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tenants',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.add_outlined),
            onPressed: () {
              Get.to(() => const AddTenantPage())?.then((_) => _refreshData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: Column(
                children: [
                  // Search and Filter Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search Bar
                        TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search tenants...',
                            prefixIcon: const Icon(Icons.search_outlined),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),

                        const SizedBox(height: 16),

                        // Filter Chips
                        Row(
                          children: [
                            _buildFilterChip('All', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Active', 'active'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Inactive', 'inactive'),
                            const Spacer(),
                            Obx(
                              () => Text(
                                '${_getFilteredTenants().length} tenant${_getFilteredTenants().length != 1 ? 's' : ''}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tenant List
                  Expanded(
                    child: Obx(() {
                      final filteredTenants = _getFilteredTenants();

                      if (filteredTenants.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No tenants found'
                                    : 'No tenants yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Try adjusting your search'
                                    : 'Add your first tenant to get started',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Get.to(
                                      () => const AddTenantPage(),
                                    )?.then((_) => _refreshData());
                                  },
                                  icon: const Icon(Icons.add_outlined),
                                  label: Text(
                                    'Add Tenant',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredTenants.length,
                        itemBuilder: (context, index) {
                          final tenant = filteredTenants[index];
                          final data = tenant.data() as Map<String, dynamic>;

                          // Get list of property names
                          final properties =
                              data['properties'] as List<dynamic>? ?? [];
                          print(properties);
                          final propertyNames = properties
                              .map(
                                (prop) =>
                                    (prop
                                        as Map<
                                          String,
                                          dynamic
                                        >)['propertyName'] ??
                                    '',
                              )
                              .where((name) => name.isNotEmpty)
                              .toList();

                          final propertyNamesString = propertyNames.join(
                            ', ',
                          ); // comma-separated list

                          return FadeInUp(
                            duration: Duration(
                              milliseconds: 300 + (index * 100),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showTenantOptions(tenant),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          child: Text(
                                            '${data['firstName']?.toString().substring(0, 1).toUpperCase() ?? ''}${data['lastName']?.toString().substring(0, 1).toUpperCase() ?? ''}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        // Tenant Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Name
                                              Text(
                                                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                                                    .trim(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              // Email
                                              Text(
                                                data['email'] ?? '',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              // Properties list
                                              // if (propertyNames.isNotEmpty)
                                              //   Row(
                                              //     children: [
                                              //       Icon(
                                              //         Icons.home_outlined,
                                              //         size: 16,
                                              //         color: AppTheme
                                              //             .textSecondary,
                                              //       ),
                                              //       const SizedBox(width: 4),
                                              //       Expanded(
                                              //         child: Text(
                                              //           propertyNamesString,
                                              //           style:
                                              //               GoogleFonts.poppins(
                                              //                 fontSize: 12,
                                              //                 color: AppTheme
                                              //                     .textSecondary,
                                              //               ),
                                              //           overflow: TextOverflow
                                              //               .ellipsis,
                                              //         ),
                                              //       ),
                                              //     ],
                                              //   ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        // More Options
                                        Icon(
                                          Icons.more_vert,
                                          color: AppTheme.textSecondary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const AddTenantPage())?.then((_) => _refreshData());
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primaryColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }
}
