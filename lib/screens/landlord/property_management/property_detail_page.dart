import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_detail_page.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class PropertyDetailPage extends StatefulWidget {
  final String propertyId;
  
  const PropertyDetailPage({super.key, required this.propertyId});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Map<String, dynamic>? _propertyData;
  bool _isLoading = true;
  
  // Sample tenant data
  final List<Map<String, dynamic>> _tenants = [
    {
      'id': '1',
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'phone': '+1 (123) 456-7890',
      'image': 'assets/tenant1.jpg',
      'status': 'Active',
      'leaseStart': '2023-01-15',
      'leaseEnd': '2024-01-15',
    },
    {
      'id': '2',
      'name': 'Emma Wilson',
      'email': 'emma.wilson@example.com',
      'phone': '+1 (234) 567-8901',
      'image': 'assets/tenant2.jpg',
      'status': 'Active',
      'leaseStart': '2023-02-01',
      'leaseEnd': '2024-02-01',
    },
  ];
  
  // Sample maintenance history
  final List<Map<String, dynamic>> _maintenanceHistory = [
    {
      'id': '1',
      'title': 'Leaking Faucet',
      'description': 'The kitchen sink faucet is leaking and needs repair.',
      'status': 'Completed',
      'date': '2023-08-10',
      'completedDate': '2023-08-12',
      'cost': 150.00,
      'priority': 'Medium',
    },
    {
      'id': '2',
      'title': 'Air Conditioner Not Cooling',
      'description': 'The bedroom AC is not cooling properly.',
      'status': 'In Progress',
      'date': '2023-08-15',
      'completedDate': null,
      'cost': null,
      'priority': 'High',
    },
    {
      'id': '3',
      'title': 'Repaint Walls',
      'description': 'Scheduled repainting of living room walls.',
      'status': 'Scheduled',
      'date': '2023-08-20',
      'scheduledDate': '2023-09-10',
      'completedDate': null,
      'cost': 550.00,
      'priority': 'Low',
    },
  ];
  
  // Sample documents
  final List<Map<String, dynamic>> _documents = [
    {
      'id': '1',
      'title': 'Property Deed',
      'type': 'PDF',
      'size': '3.5 MB',
      'uploadDate': '2023-01-10',
      'url': 'https://example.com/documents/deed.pdf',
    },
    {
      'id': '2',
      'title': 'Property Insurance',
      'type': 'PDF',
      'size': '1.8 MB',
      'uploadDate': '2023-01-15',
      'url': 'https://example.com/documents/insurance.pdf',
    },
    {
      'id': '3',
      'title': 'Property Photos',
      'type': 'ZIP',
      'size': '12.4 MB',
      'uploadDate': '2023-01-12',
      'url': 'https://example.com/documents/photos.zip',
    },
  ];
  
  // Sample financial data
  final List<Map<String, dynamic>> _financialHistory = [
    {
      'id': '1',
      'title': 'Rent Income',
      'amount': 2200.00,
      'date': '2023-08-15',
      'type': 'Income',
    },
    {
      'id': '2',
      'title': 'Maintenance',
      'amount': 150.00,
      'date': '2023-08-12',
      'type': 'Expense',
    },
    {
      'id': '3',
      'title': 'Property Tax',
      'amount': 450.00,
      'date': '2023-07-30',
      'type': 'Expense',
    },
    {
      'id': '4',
      'title': 'Rent Income',
      'amount': 2200.00,
      'date': '2023-07-15',
      'type': 'Income',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch property data
    _fetchPropertyData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchPropertyData() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Sample data
    _propertyData = {
      'id': widget.propertyId,
      'name': 'Modern Apartment in Downtown',
      'address': '123 Main St, Apt 303, New York, NY 10001',
      'type': 'Apartment',
      'bedrooms': 2,
      'bathrooms': 2,
      'area': 1200,
      'areaUnit': 'sq ft',
      'rent': 2200,
      'status': 'Occupied',
      'occupancyRate': 1.0, // 100% occupied
      'acquisitionDate': '2020-06-15',
      'images': [
        'assets/property1.jpg',
        'assets/property1_interior1.jpg',
        'assets/property1_interior2.jpg',
      ],
      'features': [
        'Air Conditioning',
        'In-unit Laundry',
        'Hardwood Floors',
        'Stainless Steel Appliances',
        'Balcony',
        'Gym Access',
      ],
      'location': {
        'latitude': 40.7128,
        'longitude': -74.0060,
      },
      'financials': {
        'monthlyIncome': 2200,
        'yearlyIncome': 26400,
        'expenses': {
          'monthly': 420,
          'yearly': 5040,
        },
        'netIncome': {
          'monthly': 1780,
          'yearly': 21360,
        },
        'roi': 5.8,
      },
    };
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Property Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Determine status color
    Color statusColor;
    switch (_propertyData!['status']) {
      case 'Occupied':
        statusColor = AppTheme.successColor;
        break;
      case 'Vacant':
        statusColor = AppTheme.warningColor;
        break;
      case 'Maintenance':
        statusColor = AppTheme.infoColor;
        break;
      default:
        statusColor = AppTheme.textLight;
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Property Image
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Property Image
                  Image.asset(
                    _propertyData!['images'][0],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.home_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Property information
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _propertyData!['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _propertyData!['address'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showOptionsBottomSheet();
                },
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Summary Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _propertyData!['status'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _propertyData!['type'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '\$${NumberFormat('#,##0').format(_propertyData!['rent'])}/mo',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          // Property Features
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPropertyFeature(
                                icon: Icons.king_bed_outlined,
                                label: '${_propertyData!['bedrooms']} Beds',
                              ),
                              _buildPropertyFeature(
                                icon: Icons.bathtub_outlined,
                                label: '${_propertyData!['bathrooms']} Baths',
                              ),
                              _buildPropertyFeature(
                                icon: Icons.straighten_outlined,
                                label: '${NumberFormat('#,##0').format(_propertyData!['area'])} ${_propertyData!['areaUnit']}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          // Occupancy Rate
                          Row(
                            children: [
                              CircularPercentIndicator(
                                radius: 35.0,
                                lineWidth: 8.0,
                                percent: _propertyData!['occupancyRate'],
                                center: Text(
                                  '${(_propertyData!['occupancyRate'] * 100).toInt()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                progressColor: AppTheme.primaryColor,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                circularStrokeCap: CircularStrokeCap.round,
                                animation: true,
                                animationDuration: 1000,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Occupancy Rate',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _propertyData!['occupancyRate'] == 1.0
                                          ? 'Property is fully occupied'
                                          : _propertyData!['occupancyRate'] == 0.0
                                              ? 'Property is vacant'
                                              : 'Property is partially occupied',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
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
                ),
                
                // Financial Summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial Summary',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFinancialStat(
                                label: 'Monthly Income',
                                value: '\$${NumberFormat('#,##0').format(_propertyData!['financials']['monthlyIncome'])}',
                                icon: Icons.attach_money_outlined,
                                iconColor: AppTheme.successColor,
                              ),
                              _buildFinancialStat(
                                label: 'Monthly Expenses',
                                value: '\$${NumberFormat('#,##0').format(_propertyData!['financials']['expenses']['monthly'])}',
                                icon: Icons.money_off_outlined,
                                iconColor: AppTheme.errorColor,
                              ),
                              _buildFinancialStat(
                                label: 'Net Monthly',
                                value: '\$${NumberFormat('#,##0').format(_propertyData!['financials']['netIncome']['monthly'])}',
                                icon: Icons.account_balance_wallet_outlined,
                                iconColor: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.infoColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.trending_up,
                                  size: 16,
                                  color: AppTheme.infoColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Annual ROI: ${_propertyData!['financials']['roi']}%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.infoColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tab Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: AppTheme.textSecondary,
                        indicatorColor: AppTheme.primaryColor,
                        indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                        tabs: const [
                          Tab(text: 'Details'),
                          Tab(text: 'Tenants'),
                          Tab(text: 'Maintenance'),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Tab Content
                SizedBox(
                  height: 500, // Fixed height for tab content
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Details Tab
                        _buildDetailsTab(),
                        
                        // Tenants Tab
                        _buildTenantsTab(),
                        
                        // Maintenance Tab
                        _buildMaintenanceTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show action sheet with options
          _showActionsBottomSheet();
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildPropertyFeature({
    required IconData icon,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFinancialStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailsTab() {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Images
          Text(
            'Photos',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _propertyData!['images'].length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(_propertyData!['images'][index]),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {},
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Property Features
          Text(
            'Features',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_propertyData!['features'] as List).map<Widget>((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  feature,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Property Documents
          Text(
            'Documents',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_documents.length, (index) {
            final document = _documents[index];
            return _buildDocumentItem(document);
          }),
          
          const SizedBox(height: 20),
          
          // Financial History
          Text(
            'Financial History',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_financialHistory.length, (index) {
            final transaction = _financialHistory[index];
            return _buildFinancialHistoryItem(transaction);
          }),
        ],
      ),
    );
  }
  
  Widget _buildTenantsTab() {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Tenants',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Add tenant functionality
                },
                icon: const Icon(
                  Icons.person_add_outlined,
                  size: 16,
                ),
                label: const Text('Add'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (_tenants.isEmpty)
            Container(
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
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tenants yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a tenant to start collecting rent',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_tenants.length, (index) {
              final tenant = _tenants[index];
              return _buildTenantItem(tenant);
            }),
        ],
      ),
    );
  }
  
  Widget _buildMaintenanceTab() {
    return SingleChildScrollView( physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Maintenance History',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Add maintenance request functionality
                },
                icon: const Icon(
                  Icons.add_outlined,
                  size: 16,
                ),
                label: const Text('Request'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Maintenance Requests
          ...List.generate(_maintenanceHistory.length, (index) {
            final request = _maintenanceHistory[index];
            return _buildMaintenanceItem(request);
          }),
        ],
      ),
    );
  }
  
  Widget _buildDocumentItem(Map<String, dynamic> document) {
    IconData fileIcon;
    Color fileColor;
    
    switch (document['type']) {
      case 'PDF':
        fileIcon = Icons.picture_as_pdf_outlined;
        fileColor = Colors.red;
        break;
      case 'JPG':
      case 'PNG':
        fileIcon = Icons.image_outlined;
        fileColor = Colors.blue;
        break;
      case 'ZIP':
        fileIcon = Icons.folder_zip_outlined;
        fileColor = Colors.orange;
        break;
      default:
        fileIcon = Icons.insert_drive_file_outlined;
        fileColor = Colors.grey;
    }
    
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              fileIcon,
              size: 24,
              color: fileColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${document['type']} • ${document['size']} • ${_formatDate(document['uploadDate'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            color: AppTheme.primaryColor,
            onPressed: () {
              // Download document
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinancialHistoryItem(Map<String, dynamic> transaction) {
    final bool isIncome = transaction['type'] == 'Income';
    final Color typeColor = isIncome ? AppTheme.successColor : AppTheme.errorColor;
    
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
              color: typeColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction['date']),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? "+" : "-"}\$${NumberFormat('#,##0.00').format(transaction['amount'])}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: typeColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTenantItem(Map<String, dynamic> tenant) {
    // Determine status color
    Color statusColor;
    switch (tenant['status']) {
      case 'Active':
        statusColor = AppTheme.successColor;
        break;
      case 'Inactive':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.textLight;
    }
    
    // Calculate lease remaining
    final leaseStart = DateTime.parse(tenant['leaseStart']);
    final leaseEnd = DateTime.parse(tenant['leaseEnd']);
    final today = DateTime.now();
    
    final totalDays = leaseEnd.difference(leaseStart).inDays;
    final daysElapsed = today.difference(leaseStart).inDays;
    
    double progress = daysElapsed / totalDays;
    progress = progress.clamp(0.0, 1.0); // Ensure progress is between 0 and 1
    
    final remainingDays = leaseEnd.difference(today).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to tenant details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TenantDetailPage(
                tenantId: tenant['id'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Row(
              children: [
                // Tenant Image
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(tenant['image']),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(width: 16),
                // Tenant Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tenant['status'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tenant['email'],
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
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tenant['phone'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Lease progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lease: ${_formatDate(tenant['leaseStart'])} - ${_formatDate(tenant['leaseEnd'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  color: AppTheme.primaryColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  '$remainingDays days remaining',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMaintenanceItem(Map<String, dynamic> request) {
    Color statusColor;
    
    switch (request['status']) {
      case 'Completed':
        statusColor = AppTheme.successColor;
        break;
      case 'In Progress':
        statusColor = AppTheme.infoColor;
        break;
      case 'Scheduled':
        statusColor = AppTheme.warningColor;
        break;
      default:
        statusColor = AppTheme.textLight;
    }
    
    Color priorityColor;
    
    switch (request['priority']) {
      case 'High':
        priorityColor = AppTheme.errorColor;
        break;
      case 'Medium':
        priorityColor = AppTheme.warningColor;
        break;
      case 'Low':
        priorityColor = AppTheme.successColor;
        break;
      default:
        priorityColor = AppTheme.textLight;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request['title'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
                child: Text(
                  request['status'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request['description'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reported: ${_formatDate(request['date'])}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    size: 14,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request['priority']} Priority',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: priorityColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (request['status'] == 'Completed' && request['cost'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.attach_money_outlined,
                  size: 14,
                  color: AppTheme.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Cost: \$${NumberFormat('#,##0.00').format(request['cost'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
          if (request['status'] == 'Scheduled' && request['scheduledDate'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 14,
                  color: AppTheme.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Scheduled for: ${_formatDate(request['scheduledDate'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
                'Property Options',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionItem(
                icon: Icons.edit_outlined,
                label: 'Edit Property',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit property page
                },
              ),
              _buildOptionItem(
                icon: Icons.pin_drop_outlined,
                label: 'View on Map',
                onTap: () {
                  Navigator.pop(context);
                  // View property on map
                },
              ),
              _buildOptionItem(
                icon: Icons.description_outlined,
                label: 'Upload Documents',
                onTap: () {
                  Navigator.pop(context);
                  // Upload documents
                },
              ),
              if (_propertyData!['status'] == 'Occupied')
                _buildOptionItem(
                  icon: Icons.home_outlined,
                  label: 'Mark as Vacant',
                  onTap: () {
                    Navigator.pop(context);
                    // Show confirmation dialog
                    _showConfirmationDialog(
                      title: 'Mark as Vacant',
                      message: 'Are you sure you want to mark this property as vacant?',
                      onConfirm: () {
                        // Update property status
                        setState(() {
                          _propertyData!['status'] = 'Vacant';
                          _propertyData!['occupancyRate'] = 0.0;
                        });
                      },
                    );
                  },
                  isDestructive: true,
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _showActionsBottomSheet() {
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
                'Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionItem(
                icon: Icons.person_add_outlined,
                label: 'Add Tenant',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to add tenant page
                },
              ),
              _buildOptionItem(
                icon: Icons.home_repair_service_outlined,
                label: 'Create Maintenance Request',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to create maintenance request page
                },
              ),
              _buildOptionItem(
                icon: Icons.attach_money_outlined,
                label: 'Record Payment',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to record payment page
                },
              ),
              _buildOptionItem(
                icon: Icons.description_outlined,
                label: 'Upload Document',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to upload document page
                },
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
  
  void _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
  
  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM, yyyy').format(date);
  }
}