import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/property_controller.dart';
import 'package:payrent_business/screens/landlord/property_management/add_property_page.dart';
import 'package:payrent_business/screens/landlord/property_management/bulk_upload_page.dart';
import 'package:payrent_business/screens/landlord/property_management/property_detail_page.dart';

class PropertyListPage extends StatefulWidget {
  const PropertyListPage({super.key});

  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> {
  String _selectedFilter = 'All Properties';
  final List<String> _filters = ['All Properties', 'Single Unit', 'Multi Unit', 'Vacant', 'Occupied'];
  
  // Track expanded property cards
  final Set<String> _expandedProperties = {};
  
  // Use PropertyController instead of static data
  final PropertyController _propertyController = Get.find<PropertyController>();
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Fetch properties when page loads
    _propertyController.fetchProperties();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Apply filters based on selection
  void _filterProperties(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    
    if (filter == 'All Properties') {
      _propertyController.filteredProperties.value = _propertyController.properties;
      return;
    }
    
    // Filter the properties based on selection
    final List<DocumentSnapshot> filtered = _propertyController.properties.where((property) {
      final data = property.data() as Map<String, dynamic>;
      
      if (filter == 'Single Unit' || filter == 'Multi Unit') {
        return data['type'] == filter;
      } 
      else if (filter == 'Vacant' || filter == 'Occupied') {
        // For properties with units, check if any match the filter
        final bool isMultiUnit = data['type'] == 'Multi Unit';
        
        if (isMultiUnit && data['units'] != null) {
          final List<dynamic> units = data['units'] as List<dynamic>;
          return units.any((unit) => unit['status'] == filter);
        } else {
          // For single units, check the status directly
          return data['status'] == filter;
        }
      }
      
      return true;
    }).toList();
    
    _propertyController.filteredProperties.value = filtered;
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Properties',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              // Navigate to bulk upload page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BulkUploadPage(),
                ),
              );
            },
            tooltip: 'Bulk Upload',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _selectedFilter == filter
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                      selected: _selectedFilter == filter,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
                      onSelected: (selected) {
                        if (selected) {
                          _filterProperties(filter);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Properties Count
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Showing ${_propertyController.filteredProperties.length} Properties',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          )),
          
          const SizedBox(height: 8),
          
          // Property List with loading state
          Expanded(
            child: Obx(() {
              if (_propertyController.isLoading.value) {
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
                        onPressed: () => _propertyController.fetchProperties(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (_propertyController.filteredProperties.isEmpty) {
                return _buildEmptyState();
              } else {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _propertyController.filteredProperties.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final property = _propertyController.filteredProperties[index];
                    return FadeInUp(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      child: _buildPropertyCard(property),
                    );
                  },
                );
              }
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPropertyPage(),
            ),
          ).then((_) {
            // Refresh properties when returning from add property page
            _propertyController.fetchProperties();
          });
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No properties found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All Properties'
                  ? 'Add your first property to get started'
                  : 'No properties match the current filter',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPropertyPage()),
                ).then((_) {
                  // Refresh the list when returning
                  _propertyController.fetchProperties();
                });
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Add Property'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPropertyCard(DocumentSnapshot property) {
    final data = property.data() as Map<String, dynamic>;
    
    // Extract values with null safety
    final String id = property.id;
    final String name = data['name'] ?? 'Unnamed Property';
    final String address = data['address'] ?? '';
    final String city = data['city'] ?? '';
    final String state = data['state'] ?? '';
    final String zipCode = data['zipCode'] ?? '';
    final String fullAddress = '$address, $city, $state $zipCode';
    final String type = data['type'] ?? 'Single Unit';
    final String imageUrl = data['images'] != null && (data['images'] as List).isNotEmpty
        ? (data['images'] as List).first as String
        : '';
        
    final bool isMultiUnit = type == 'Multi Unit';
    final bool isExpanded = _expandedProperties.contains(id);
    
    // Get units data for multi-unit properties
    List<Map<String, dynamic>> units = [];
    if (isMultiUnit && data['units'] != null) {
      units = List<Map<String, dynamic>>.from(data['units'] as List<dynamic>);
    }
    
    // For single units, get status and rent amount
    String status = 'Vacant';
    double rent = 0.0;
    
    if (!isMultiUnit) {
      status = data['status'] ?? 'Vacant';
      
      // Handle different number types from Firestore
      if (data['rent'] is int) {
        rent = (data['rent'] as int).toDouble();
      } else if (data['rent'] is double) {
        rent = data['rent'] as double;
      } else if (data['rent'] != null) {
        rent = double.tryParse(data['rent'].toString()) ?? 0.0;
      }
    }
    
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image and Header - Clickable to navigate to detail
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyDetailPage(propertyId: id),
                  ),
                ).then((_) {
                  // Refresh when returning from detail page
                  _propertyController.fetchProperties();
                });
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Image
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {},
                            )
                          : null,
                      color: Colors.grey.shade200,
                    ),
                    child: Stack(
                      children: [
                        if (imageUrl.isEmpty)
                          Center(
                            child: Icon(
                              Icons.home_outlined,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Property Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Name
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Property Address
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                fullAddress,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                _showPropertyOptionsBottomSheet(id, data);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider for multi-unit properties
            if (isMultiUnit && units.isNotEmpty) const Divider(height: 1),
            
            // Units for multi-unit properties
            if (isMultiUnit && units.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Always show first unit
                    if (units.isNotEmpty) _buildUnitItem(units[0]),
                    
                    // Handle multiple units
                    if (units.length > 1)
                      isExpanded 
                        // Show all units when expanded
                        ? Column(
                            children: [
                              for (int i = 1; i < units.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _buildUnitItem(units[i]),
                                ),
                              const SizedBox(height: 12),
                              // Show "Collapse" button when expanded
                              InkWell(
                                onTap: () => _togglePropertyExpansion(id),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Collapse',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.keyboard_arrow_up,
                                          size: 16,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        // Show "+X more" when collapsed
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: InkWell(
                              onTap: () => _togglePropertyExpansion(id),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '+${units.length - 1} more units',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            
            // Single unit status and rent
            if (!isMultiUnit)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'Vacant'
                            ? AppTheme.warningColor.withOpacity(0.1)
                            : AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: status == 'Vacant'
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                        ),
                      ),
                    ),
                    
                    // Rent
                    Text(
                      '\$${rent.toStringAsFixed(0)}/mo',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUnitItem(Map<String, dynamic> unit) {
    // Extract values with null safety
    final String number = unit['number'] ?? '';
    final String type = unit['type'] ?? '';
    final String status = unit['status'] ?? 'Vacant';
    
    // Handle different number types from Firestore
    double rent = 0.0;
    if (unit['rent'] is int) {
      rent = (unit['rent'] as int).toDouble();
    } else if (unit['rent'] is double) {
      rent = unit['rent'] as double;
    } else if (unit['rent'] != null) {
      rent = double.tryParse(unit['rent'].toString()) ?? 0.0;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Unit number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Unit - $number',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'Vacant'
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status == 'Vacant'
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Unit type and rent
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      type,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rent
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rent',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${rent.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Menu
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 16,
                  ),
                  onPressed: () {
                    _showUnitOptionsBottomSheet(unit);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Properties',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter property name or address',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            _propertyController.filterProperties(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _propertyController.fetchProperties();
              Navigator.pop(context);
            },
            child: const Text('CLEAR'),
          ),
          ElevatedButton(
            onPressed: () {
              _propertyController.filterProperties(_searchController.text);
              Navigator.pop(context);
            },
            child: const Text('SEARCH'),
          ),
        ],
      ),
    );
  }
  
  void _showPropertyOptionsBottomSheet(String propertyId, Map<String, dynamic> propertyData) {
    final String type = propertyData['type'] ?? 'Single Unit';
    
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
                'Property Options',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionItem(
                icon: Icons.visibility_outlined,
                label: 'View Details',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailPage(propertyId: propertyId),
                    ),
                  ).then((_) {
                    _propertyController.fetchProperties();
                  });
                },
              ),
              _buildOptionItem(
                icon: Icons.edit_outlined,
                label: 'Edit Property',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit property (implement this later)
                },
              ),
              if (type == 'Multi Unit')
                _buildOptionItem(
                  icon: Icons.add_home_outlined,
                  label: 'Add Unit',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to add unit (implement this later)
                  },
                ),
              _buildOptionItem(
                icon: Icons.person_add_outlined,
                label: 'Add Tenant',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to add tenant with this property pre-selected (implement this later)
                },
              ),
              _buildOptionItem(
                icon: Icons.delete_outline,
                label: 'Delete Property',
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(propertyId);
                },
                isDestructive: true,
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showDeleteConfirmationDialog(String propertyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Property',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this property? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _propertyController.deleteProperty(propertyId).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Property deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting property: ${error.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
  
  void _showUnitOptionsBottomSheet(Map<String, dynamic> unit) {
    final String number = unit['number'] ?? '';
    final String status = unit['status'] ?? 'Vacant';
    
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
                'Unit $number Options',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionItem(
                icon: Icons.visibility_outlined,
                label: 'View Unit Details',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to unit details (implement this later)
                },
              ),
              _buildOptionItem(
                icon: Icons.edit_outlined,
                label: 'Edit Unit',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit unit (implement this later)
                },
              ),
              _buildOptionItem(
                icon: status == 'Vacant'
                    ? Icons.person_add_outlined
                    : Icons.person_outlined,
                label: status == 'Vacant'
                    ? 'Add Tenant'
                    : 'Manage Tenant',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to tenant management (implement this later)
                },
              ),
              if (status == 'Occupied')
                _buildOptionItem(
                  icon: Icons.payments_outlined,
                  label: 'Record Payment',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to record payment (implement this later)
                  },
                ),
              _buildOptionItem(
                icon: Icons.delete_outline,
                label: 'Delete Unit',
                onTap: () {
                  Navigator.pop(context);
                  // Show delete confirmation (implement this later)
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
}