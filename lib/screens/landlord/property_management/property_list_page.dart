// lib/screens/landlord/property_management/property_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/account_information_model.dart';
import 'package:payrent_business/models/property_model.dart';
import 'package:payrent_business/screens/landlord/mandate/mandate_status_page.dart';
import 'package:payrent_business/screens/landlord/mandate/new_create_mandate_page.dart';
import 'package:payrent_business/screens/landlord/property_management/add_property_page.dart';
import 'package:payrent_business/screens/landlord/property_management/edit_property_page.dart';
import 'package:payrent_business/screens/landlord/property_management/property_detail_page.dart';
import 'package:payrent_business/screens/landlord/property_management/unit_action_bottom_sheet.dart';
import 'package:payrent_business/screens/landlord/property_management/unit_details_page.dart';

class PropertyListPage extends StatefulWidget {
  const PropertyListPage({Key? key}) : super(key: key);

  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<DocumentSnapshot> _allProperties = [];
  List<DocumentSnapshot> _filteredProperties = [];
  String? _errorMessage;
  String _searchQuery = '';

  // Animation controller for filter panel
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  // Sort & Filter Options
  String _sortOption = 'Newest';
  String _filterOption = 'All';
  bool _showFilterPanel = false;

  // Track expanded property cards
  Set<String> _expandedProperties = {};

  final TextEditingController _searchController = TextEditingController();
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  @override
  void initState() {
    super.initState();
    _fetchProperties();

    // Initialize animation controller
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
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
        _applyFiltersAndSort(); // Apply initial filters and sort
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching properties: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> deleteProperty({required String propertyId}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(propertyId)
          .delete();

      print('Property $propertyId deleted successfully.');
    } catch (e) {
      print('Error deleting property: $e');
      rethrow;
    }
  }

  void _applyFiltersAndSort() {
    // Start with all properties
    List<DocumentSnapshot> result = List.from(_allProperties);

    // Apply search filter if search query exists
    if (_searchQuery.isNotEmpty) {
      result = result.where((property) {
        final data = property.data() as Map<String, dynamic>;
        final name = data['name']?.toString().toLowerCase() ?? '';
        final city = data['city']?.toString().toLowerCase() ?? '';
        final address = data['address']?.toString().toLowerCase() ?? '';
        final zipCode = data['zipCode']?.toString().toLowerCase() ?? '';

        // Also search within units for unit numbers
        bool unitMatch = false;
        final units = data['units'] as List<dynamic>?;
        if (units != null) {
          unitMatch = units.any((unit) {
            final unitNumber =
                unit['unitNumber']?.toString().toLowerCase() ?? '';
            final unitType = unit['unitType']?.toString().toLowerCase() ?? '';
            return unitNumber.contains(_searchQuery.toLowerCase()) ||
                unitType.contains(_searchQuery.toLowerCase());
          });
        }

        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            city.contains(query) ||
            address.contains(query) ||
            zipCode.contains(query) ||
            unitMatch;
      }).toList();
    }

    // Apply type filter
    if (_filterOption != 'All') {
      result = result.where((property) {
        final data = property.data() as Map<String, dynamic>;
        final isMultiUnit = data['isMultiUnit'] ?? false;

        if (_filterOption == 'Single Unit') {
          return !isMultiUnit;
        } else if (_filterOption == 'Multi Unit') {
          return isMultiUnit;
        } else if (_filterOption == 'Fully Occupied' ||
            _filterOption == 'Has Vacancy') {
          final units = data['units'] as List<dynamic>?;
          if (units == null || units.isEmpty) return false;

          final hasVacancy = units.any((unit) => unit['tenantId'] == null);
          return _filterOption == 'Has Vacancy' ? hasVacancy : !hasVacancy;
        }
        return true;
      }).toList();
    }

    // Apply sorting
    result.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      switch (_sortOption) {
        case 'A–Z':
          return (dataA['name'] ?? '').toString().compareTo(
            (dataB['name'] ?? '').toString(),
          );
        case 'Z–A':
          return (dataB['name'] ?? '').toString().compareTo(
            (dataA['name'] ?? '').toString(),
          );
        case 'Oldest':
          final timestampA = dataA['createdAt'] as Timestamp?;
          final timestampB = dataB['createdAt'] as Timestamp?;
          return (timestampA?.toDate() ?? DateTime.now()).compareTo(
            timestampB?.toDate() ?? DateTime.now(),
          );
        case 'Newest':
        default:
          final timestampA = dataA['createdAt'] as Timestamp?;
          final timestampB = dataB['createdAt'] as Timestamp?;
          return (timestampB?.toDate() ?? DateTime.now()).compareTo(
            timestampA?.toDate() ?? DateTime.now(),
          );
      }
    });

    setState(() {
      _filteredProperties = result;
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
    });

    if (_showFilterPanel) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _togglePropertyExpansion(String propertyId) {
    setState(() {
      if (_expandedProperties.contains(propertyId)) {
        _expandedProperties.remove(propertyId);
      } else {
        _expandedProperties.add(propertyId);
      }
    });
  }

  void _navigateToPropertyDetails(String propertyId, PropertyModel property) {
    // For now, just show a snackbar since PropertyDetailPage is not implemented yet
    Get.to(PropertyDetailsPage(propertyId: propertyId));
  }

  void _navigateToUnitDetails(
    String propertyId,
    String unitId,
    PropertyUnitModel unit,
  ) {
    Get.to(UnitDetailsPage(propertyId: propertyId, unit: unit));
  }

  void _showPropertyOptions(BuildContext context, DocumentSnapshot property) {
    final propertyModel = PropertyModel.fromFirestore(property);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Manage Property',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                propertyModel.name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit Property',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  Get.to(
                    EditPropertyPage(
                      property: propertyModel,
                      propertyId: propertyModel.id!,
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.home_work_outlined,
                label: 'View Units',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _togglePropertyExpansion(property.id);
                },
              ),
              _buildActionButton(
                icon: Icons.delete_outline,
                label: 'Delete Property',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, property);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // In PropertyListPage - Update this method
  void _showUnitOptions(
    BuildContext context,
    String propertyId,
    PropertyUnitModel unit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return UnitActionBottomSheet(
          propertyId: propertyId,
          unit: unit,
          onComplete: () {
            // Refresh property data after unit action
            _fetchProperties();
            Get.back();
          },
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    DocumentSnapshot property,
  ) {
    final propertyData = property.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete Property',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete:',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 8),
              Text(
                propertyData['name'] ?? 'This property',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Text(
                'This action cannot be undone and all associated data will be permanently deleted.',
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                deleteProperty(propertyId: property.id).then((_) {
                  _fetchProperties();
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMandateButton(
    PropertyUnitModel unit,
    DocumentSnapshot tenantDoc,
    AccountInformation? landlordAccountInfo,
    List<QueryDocumentSnapshot> mandates,
    String propertyId,
  ) {
    final tenantData = tenantDoc.data() as Map<String, dynamic>;
    final tenantId = tenantDoc.id;

    // Check if mandate exists
    final mandateExists = mandates.any((mandate) {
      final data = mandate.data() as Map<String, dynamic>;
      return data['tenantId'] == tenantId && data['unitId'] == unit.unitId;
    });

    final landlordHasAccountInfo = landlordAccountInfo != null;
    final tenantHasAccountInfo =
        tenantData['db_account_holder_name'] != null &&
        tenantData['db_account_number'] != null &&
        tenantData['db_bank_bic'] != null &&
        tenantData['db_branch_code'] != null;

    final canCreateMandate = landlordHasAccountInfo && tenantHasAccountInfo;

    if (mandateExists) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Mandate Created',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
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
                    landlordAccountInfo: landlordAccountInfo!,
                    propertyId: propertyId,
                  ),
                ),
              );
            }
          : () {
              String msg = !landlordHasAccountInfo
                  ? 'Please complete your account information in settings.'
                  : 'Tenant account information is incomplete.';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg), backgroundColor: Colors.orange),
              );
            },
      icon: const Icon(Icons.account_balance, size: 16),
      label: const Text('Create Mandate'),
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

  @override
  Widget build(BuildContext context) {
    // Check if we're on a larger screen
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          'My Properties',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _filterAnimation,
            ),
            onPressed: _toggleFilterPanel,
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search properties or units...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _applyFiltersAndSort();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFiltersAndSort();
              },
            ),
          ),

          // Filter Panel (Animated)
          SizeTransition(
            sizeFactor: _filterAnimation,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort Options
                    Text(
                      'Sort by',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSortChip('Newest', _sortOption == 'Newest'),
                          const SizedBox(width: 8),
                          _buildSortChip('Oldest', _sortOption == 'Oldest'),
                          const SizedBox(width: 8),
                          _buildSortChip('A–Z', _sortOption == 'A–Z'),
                          const SizedBox(width: 8),
                          _buildSortChip('Z–A', _sortOption == 'Z–A'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filter Options
                    Text(
                      'Filter by',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', _filterOption == 'All'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Single Unit',
                            _filterOption == 'Single Unit',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Multi Unit',
                            _filterOption == 'Multi Unit',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Fully Occupied',
                            _filterOption == 'Fully Occupied',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Has Vacancy',
                            _filterOption == 'Has Vacancy',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Reset Button
                    if (_filterOption != 'All' || _sortOption != 'Newest')
                      Center(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reset Filters'),
                          onPressed: () {
                            setState(() {
                              _filterOption = 'All';
                              _sortOption = 'Newest';
                              _searchController.clear();
                              _searchQuery = '';
                            });
                            _applyFiltersAndSort();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Status Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  '${_filteredProperties.length} Properties',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                if (_filterOption != 'All' || _sortOption != 'Newest')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _filterOption != 'All' ? _filterOption : _sortOption,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Property List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorView()
                : _filteredProperties.isEmpty
                ? _buildEmptyView()
                : _buildPropertyList(isLargeScreen),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(AddPropertyPage());
        },
        backgroundColor: AppTheme.primaryColor,
        label: Text(
          'Add Property',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSortChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortOption = label;
          });
          _applyFiltersAndSort();
        }
      },
      avatar: isSelected ? Icon(Icons.check, size: 16) : null,
      backgroundColor: Colors.grey[100],
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      showCheckmark: false,
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? AppTheme.primaryColor : Colors.black,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    Color chipColor;

    switch (label) {
      case 'Single Unit':
        chipColor = Colors.blue;
        break;
      case 'Multi Unit':
        chipColor = Colors.purple;
        break;
      case 'Fully Occupied':
        chipColor = Colors.green;
        break;
      case 'Has Vacancy':
        chipColor = Colors.orange;
        break;
      default:
        chipColor = AppTheme.primaryColor;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterOption = label;
          });
          _applyFiltersAndSort();
        }
      },
      avatar: isSelected ? Icon(Icons.check, size: 16) : null,
      backgroundColor: Colors.grey[100],
      selectedColor: chipColor.withOpacity(0.2),
      showCheckmark: false,
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? chipColor : Colors.black,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: isSelected ? chipColor : Colors.transparent,
          width: 1,
        ),
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
            onPressed: _fetchProperties,
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

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'No Properties Found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterOption != 'All'
                ? 'Try changing your search or filters'
                : 'Add your first property to get started',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Get.to(AddPropertyPage());
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Property'),
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

  Widget _buildPropertyList(bool isLargeScreen) {
    return ListView.builder(
      padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
      itemCount: _filteredProperties.length,
      physics: BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final propertyData =
            _filteredProperties[index].data() as Map<String, dynamic>;
        final propertyId = _filteredProperties[index].id;
        final property = PropertyModel.fromFirestore(
          _filteredProperties[index],
        );

        return FadeInUp(
          duration: Duration(milliseconds: 300 + (index * 30)),
          child: _buildPropertyCard(context, propertyId, property),
        );
      },
    );
  }

  Widget _buildPropertyCard(
    BuildContext context,
    String propertyId,
    PropertyModel property,
  ) {
    // Calculate occupancy statistics
    final totalUnits = property.units.length;
    final occupiedUnits = property.units
        .where((unit) => unit.tenantId != null)
        .length;
    final isFullyOccupied = totalUnits > 0 && occupiedUnits == totalUnits;
    final isExpanded = _expandedProperties.contains(propertyId);

    // Calculate average rent
    int totalRent = 0;
    for (var unit in property.units) {
      totalRent += unit.rent;
    }
    final averageRent = totalRent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Property Card (always visible)
          ClipRRect(
            borderRadius: isExpanded
                ? BorderRadius.vertical(top: Radius.circular(20))
                : BorderRadius.circular(20),
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: () => _navigateToPropertyDetails(propertyId, property),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Header with Image/Gradient
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA78BFA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Placeholder for property image
                          Center(
                            child: Icon(
                              Icons.home_rounded,
                              size: 48,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          // Property type badge
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                property.isMultiUnit
                                    ? 'Multi-Unit'
                                    : 'Single Unit',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Unit count
                          Positioned(
                            top: 12,
                            right: 52, // Leave space for the menu button
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$totalUnits ${totalUnits == 1 ? 'Unit' : 'Units'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Menu Button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(Icons.more_vert, color: Colors.white),
                              onPressed: () => _showPropertyOptions(
                                context,
                                _filteredProperties.firstWhere(
                                  (p) => p.id == propertyId,
                                ),
                              ),
                            ),
                          ),
                          // Occupancy status
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isFullyOccupied
                                    ? Colors.green
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isFullyOccupied
                                    ? 'Fully Occupied'
                                    : occupiedUnits > 0
                                    ? '$occupiedUnits/$totalUnits Occupied'
                                    : 'Vacant',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Property Info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property Name
                          Text(
                            property.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Address
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${property.address}, ${property.city}, ${property.state}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Stats Row
                          Row(
                            children: [
                              // Rent
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Rent',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '\OMR${averageRent.toStringAsFixed(0)}/mo',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Occupancy
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Occupancy',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: isFullyOccupied
                                                ? Colors.green
                                                : Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$occupiedUnits/$totalUnits Units',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Show Units Button (only for multi-unit properties)
                              // if (property.isMultiUnit ||
                              //     property.units.length > 1)
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _togglePropertyExpansion(propertyId),
                                icon: Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                ),
                                label: Text(
                                  isExpanded ? 'Hide Units' : 'Show Units',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor
                                      .withOpacity(0.1),
                                  foregroundColor: AppTheme.primaryColor,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
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

          // Expanded Units Section (conditionally visible)
          if (isExpanded)
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text(
                          'Units',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${property.units.length} total',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Units List
                  ...property.units.asMap().entries.map((entry) {
                    final index = entry.key;
                    final unit = entry.value;
                    return FadeInUp(
                      duration: Duration(milliseconds: 200 + (index * 50)),
                      child: _buildUnitCard(propertyId, unit),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(String propertyId, PropertyUnitModel unit) {
    final isOccupied = unit.tenantId != null;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToUnitDetails(propertyId, unit.unitId, unit),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Unit Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EEFE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE0D6FD),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Unit ${unit.unitNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Unit Type
                    Expanded(
                      child: Text(
                        unit.unitType,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Occupancy Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOccupied
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOccupied
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isOccupied ? 'Occupied' : 'Vacant',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isOccupied ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),

                    // Menu Button
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () =>
                          _showUnitOptions(context, propertyId, unit),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Unit Details
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.bedroom_parent_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${unit.bedrooms} bed',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.bathtub_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${unit.bathrooms} bath',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'OMR${unit.rent.toStringAsFixed(0)}/mo',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                // 🔹 Mandate Section
                if (isOccupied) ...[
                  const SizedBox(height: 16),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator(strokeWidth: 2);
                      }

                      AccountInformation? landlordAccountInfo;
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        if (userData['cr_account_holder_name'] != null) {
                          landlordAccountInfo = AccountInformation.fromMap(
                            userData,
                          );
                        }
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('mandates')
                            .where('propertyId', isEqualTo: propertyId)
                            .where('unitId', isEqualTo: unit.unitId)
                            .snapshots(),
                        builder: (context, mandateSnapshot) {
                          if (mandateSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator(
                              strokeWidth: 2,
                            );
                          }

                          final mandates = mandateSnapshot.data?.docs ?? [];
                          // No mandate → show Create Mandate button
                          if (mandates.isEmpty) {
                            final tenantId = unit.tenantId;
                            if (tenantId == null) {
                              return const Text(
                                'No tenant assigned for this unit.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              );
                            }
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  );
                                }
                                // ✅ Pass landlordAccountInfo, mandates, and propertyId
                                return _buildMandateButton(
                                  unit,
                                  tenantSnapshot.data!,
                                  landlordAccountInfo,
                                  mandates,
                                  propertyId,
                                );
                              },
                            );
                          }

                          // Mandate exists → show based on status
                          final mandateData =
                              mandates.first.data() as Map<String, dynamic>;
                          final status = mandateData['mmsStatus'].toString().toLowerCase();
                          print(status);

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
                                    () => MandateStatusPage(
                                      mandateId: mandates.first.id,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                  child: const Text(
                                    'Check Mandate Status',
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
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
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
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
