import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/tenant_management/add_tenant_page.dart';
import 'package:payrent_business/screens/landlord/tenant_management/tenant_detail_page.dart';

class TenantListPage extends StatefulWidget {
  const TenantListPage({super.key});

  @override
  State<TenantListPage> createState() => _TenantListPageState();
}

class _TenantListPageState extends State<TenantListPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Paid', 'Due', 'Overdue'];
  
  // Sample tenant data
  final List<Map<String, dynamic>> _tenants = [
    {
      'id': '1',
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'phone': '(123) 456-7890',
      'property': 'Modern Apartment in Downtown',
      'propertyId': '1',
      'rent': 2200,
      'status': 'Paid',
      'nextDue': '2023-09-15',
      'leaseEnd': '2024-02-15',
      'image': 'assets/profile.png',
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'email': 'jane.smith@example.com',
      'phone': '(234) 567-8901',
      'property': 'Luxury Condo with View',
      'propertyId': '3',
      'rent': 3500,
      'status': 'Due',
      'nextDue': '2023-09-01',
      'leaseEnd': '2024-03-01',
      'image': 'assets/profile.png',
    },
    {
      'id': '3',
      'name': 'Robert Johnson',
      'email': 'robert.johnson@example.com',
      'phone': '(345) 678-9012',
      'property': '2-Bedroom Townhouse',
      'propertyId': '4',
      'rent': 2800,
      'status': 'Overdue',
      'nextDue': '2023-08-15',
      'leaseEnd': '2023-12-15',
      'image': 'assets/profile.png',
    },
    {
      'id': '4',
      'name': 'Michael Brown',
      'email': 'michael.brown@example.com',
      'phone': '(456) 789-0123',
      'property': 'Penthouse Apartment',
      'propertyId': '5',
      'rent': 4200,
      'status': 'Paid',
      'nextDue': '2023-09-10',
      'leaseEnd': '2024-01-10',
      'image': 'assets/profile.png',
    },
  ];
  
  List<Map<String, dynamic>> get filteredTenants {
    if (_selectedFilter == 'All') {
      return _tenants;
    } else {
      return _tenants.where((tenant) => tenant['status'] == _selectedFilter).toList();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:  Text('My Tenants',style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              )),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search action
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
            child: SingleChildScrollView( physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) => _buildFilterChip(filter)).toList(),
              ),
            ),
          ),
          
          // Tenants Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Showing ${filteredTenants.length} Tenants',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Tenant List
          Expanded(
            child: filteredTenants.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTenants.length,
                    physics: BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final tenant = filteredTenants[index];
                      return FadeInUp(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        child: _buildTenantCard(tenant),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTenantPage()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        label: Row(
          children: [
            const Icon(Icons.person_add_outlined,color: Colors.white,),
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
                  )
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
  
  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    Color statusColor;
    switch (tenant['status']) {
      case 'Paid':
        statusColor = AppTheme.successColor;
        break;
      case 'Due':
        statusColor = AppTheme.warningColor;
        break;
      case 'Overdue':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.textLight;
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TenantDetailPage(tenantId: tenant['id']),
          ),
        );
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
                                tenant['property'],
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
                            tenant['status'],
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
                    value: '\$${tenant['rent']}/mo',
                    icon: Icons.attach_money_outlined,
                  ),
                  _buildInfoItem(
                    label: 'Next Due',
                    value: _formatDate(tenant['nextDue']),
                    icon: Icons.calendar_today_outlined,
                    valueColor: tenant['status'] == 'Overdue'
                        ? AppTheme.errorColor
                        : tenant['status'] == 'Due'
                            ? AppTheme.warningColor
                            : null,
                  ),
                  _buildInfoItem(
                    label: 'Lease End',
                    value: _formatDate(tenant['leaseEnd']),
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
  
  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final month = _getMonth(date.month);
    return '${date.day} $month';
  }
  
  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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
              ...['All', 'Paid', 'Due', 'Overdue'].map((filter) {
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
            'Add your first tenant to get started',
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
              );
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