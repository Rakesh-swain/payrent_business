import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/property_management/add_property_page.dart';
import 'package:payrent_business/screens/landlord/property_management/bulk_upload_page.dart';
import 'package:payrent_business/screens/landlord/property_management/property_detail_page.dart';

class PropertyListPage extends StatefulWidget {
  const PropertyListPage({super.key});

  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> {
  bool _isLoading = false;
  String _selectedFilter = 'All Properties';
  final List<String> _filters = ['All Properties', 'Single Unit', 'Multi Unit', 'Vacant', 'Occupied'];
  
  // Track expanded property cards
  final Set<String> _expandedProperties = {};
  
  // Sample property data
  final List<Map<String, dynamic>> _properties = [
    {
      'id': '1',
      'name': 'Serene Apartments',
      'address': '123 Main Street, Anytown, MA 01234',
      'type': 'Multi Unit',
      'image': 'assets/home.png',
      'units': [
        {
          'id': '101',
          'number': '101',
          'type': 'Apartment',
          'rent': 1500,
          'status': 'Occupied',
        },
        {
          'id': '102',
          'number': '102',
          'type': 'Apartment',
          'rent': 1600,
          'status': 'Vacant',
        },
        {
          'id': '103',
          'number': '103',
          'type': 'Apartment',
          'rent': 1550,
          'status': 'Occupied',
        },
      ],
    },
    {
      'id': '2',
      'name': 'Coastal Villa',
      'address': '456 Ocean Drive, Seaside, CA 90210',
      'type': 'Single Unit',
       'image': 'assets/home.png',
      'rent': 2200,
      'status': 'Occupied',
    },
    {
      'id': '3',
      'name': 'Urban Heights',
      'address': '789 Downtown Blvd, Metropolis, NY 10001',
      'type': 'Multi Unit',
       'image': 'assets/home.png',
      'units': [
        {
          'id': '201',
          'number': '201',
          'type': 'Studio',
          'rent': 1300,
          'status': 'Vacant',
        },
        {
          'id': '202',
          'number': '202',
          'type': 'Studio',
          'rent': 1300,
          'status': 'Vacant',
        },
      ],
    },
    {
      'id': '4',
      'name': 'Suburban House',
      'address': '123 Maple Ave, Greenville, TX 75401',
      'type': 'Single Unit',
       'image': 'assets/home.png',
      'rent': 1800,
      'status': 'Vacant',
    },
  ];
  
  List<Map<String, dynamic>> _filteredProperties = [];
  
  @override
  void initState() {
    super.initState();
    _filterProperties();
  }
  
  void _filterProperties() {
    if (_selectedFilter == 'All Properties') {
      _filteredProperties = List.from(_properties);
    } else if (_selectedFilter == 'Single Unit') {
      _filteredProperties = _properties.where((p) => p['type'] == 'Single Unit').toList();
    } else if (_selectedFilter == 'Multi Unit') {
      _filteredProperties = _properties.where((p) => p['type'] == 'Multi Unit').toList();
    } else if (_selectedFilter == 'Vacant') {
      _filteredProperties = _properties.where((p) {
        if (p['type'] == 'Single Unit') {
          return p['status'] == 'Vacant';
        } else {
          // For multi-unit properties, include if any unit is vacant
          List units = p['units'] as List;
          return units.any((unit) => unit['status'] == 'Vacant');
        }
      }).toList();
    } else if (_selectedFilter == 'Occupied') {
      _filteredProperties = _properties.where((p) {
        if (p['type'] == 'Single Unit') {
          return p['status'] == 'Occupied';
        } else {
          // For multi-unit properties, include if any unit is occupied
          List units = p['units'] as List;
          return units.any((unit) => unit['status'] == 'Occupied');
        }
      }).toList();
    }
    
    setState(() {});
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
        title: const Text('My Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
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
                          setState(() {
                            _selectedFilter = filter;
                          });
                          _filterProperties();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Property List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProperties.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProperties.length,
                        itemBuilder: (context, index) {
                          final property = _filteredProperties[index];
                          return _buildPropertyCard(property);
                        },
                      ),
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
          );
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
              'Add your first property to get started',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final bool isMultiUnit = property['type'] == 'Multi Unit';
    final bool isExpanded = _expandedProperties.contains(property['id']);
    final List<dynamic> units = isMultiUnit ? property['units'] : [];
    
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
                    builder: (context) => PropertyDetailPage(propertyId: property['id']),
                  ),
                );
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
                      image: DecorationImage(
                        image: AssetImage(property['image']),
                        fit: BoxFit.contain,
                        onError: (exception, stackTrace) {},
                      ),
                      color: Colors.grey.shade200,
                    ),
                    child: Stack(
                      children: [
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
                              property['type'],
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
                          property['name'],
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
                                property['address'],
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
                                _showPropertyOptionsBottomSheet(property);
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
            if (isMultiUnit) const Divider(height: 1),
            
            // Units for multi-unit properties
            if (isMultiUnit)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Always show first unit
                    _buildUnitItem(units[0]),
                    
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
                                onTap: () => _togglePropertyExpansion(property['id']),
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
                              onTap: () => _togglePropertyExpansion(property['id']),
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
                        color: property['status'] == 'Vacant'
                            ? AppTheme.warningColor.withOpacity(0.1)
                            : AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        property['status'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: property['status'] == 'Vacant'
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                        ),
                      ),
                    ),
                    
                    // Rent
                    Text(
                      '\$${property['rent']}/mo',
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
                  'Unit - ${unit['number']}',
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
                  color: unit['status'] == 'Vacant'
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  unit['status'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: unit['status'] == 'Vacant'
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
                      unit['type'],
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
                      '\$${unit['rent']}',
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
  
  void _showPropertyOptionsBottomSheet(Map<String, dynamic> property) {
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
                      builder: (context) => PropertyDetailPage(propertyId: property['id']),
                    ),
                  );
                },
              ),
              _buildOptionItem(
                icon: Icons.edit_outlined,
                label: 'Edit Property',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit property
                },
              ),
              if (property['type'] == 'Multi Unit')
                _buildOptionItem(
                  icon: Icons.add_home_outlined,
                  label: 'Add Unit',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to add unit
                  },
                ),
              _buildOptionItem(
                icon: Icons.person_add_outlined,
                label: 'Add Tenant',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to add tenant
                },
              ),
              _buildOptionItem(
                icon: Icons.delete_outline,
                label: 'Delete Property',
                onTap: () {
                  Navigator.pop(context);
                  // Show delete confirmation
                },
                isDestructive: true,
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showUnitOptionsBottomSheet(Map<String, dynamic> unit) {
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
                'Unit ${unit['number']} Options',
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
                  // Navigate to unit details
                },
              ),
              _buildOptionItem(
                icon: Icons.edit_outlined,
                label: 'Edit Unit',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit unit
                },
              ),
              _buildOptionItem(
                icon: unit['status'] == 'Vacant'
                    ? Icons.person_add_outlined
                    : Icons.person_outlined,
                label: unit['status'] == 'Vacant'
                    ? 'Add Tenant'
                    : 'Manage Tenant',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to tenant management
                },
              ),
              if (unit['status'] == 'Occupied')
                _buildOptionItem(
                  icon: Icons.payments_outlined,
                  label: 'Record Payment',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to record payment
                  },
                ),
              _buildOptionItem(
                icon: Icons.delete_outline,
                label: 'Delete Unit',
                onTap: () {
                  Navigator.pop(context);
                  // Show delete confirmation
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