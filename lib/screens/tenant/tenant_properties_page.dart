import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/services/tenant_auth_service.dart';
import 'package:payrent_business/screens/tenant/tenant_property_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payrent_business/widgets/common/app_loading_indicator.dart';

class TenantPropertiesPage extends StatefulWidget {
  const TenantPropertiesPage({super.key});

  @override
  State<TenantPropertiesPage> createState() => _TenantPropertiesPageState();
}

class _TenantPropertiesPageState extends State<TenantPropertiesPage> {
  final TenantAuthService _tenantAuthService = TenantAuthService();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _assignedProperties = [];
  String _tenantId = '';
  String _landlordId = '';

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      setState(() => _isLoading = true);
      
      // Get tenant info from shared preferences
      final prefs = await SharedPreferences.getInstance();
      _tenantId = prefs.getString('tenantId') ?? '';
      _landlordId = prefs.getString('landlordId') ?? '';
      
      if (_tenantId.isEmpty || _landlordId.isEmpty) {
        print('Tenant or landlord ID not found');
        setState(() => _isLoading = false);
        return;
      }
      
      // Fetch tenant full data including properties
      final tenantData = await _tenantAuthService.getTenantFullData(_landlordId, _tenantId);
      if (tenantData != null) {
        setState(() {
          _assignedProperties = List<Map<String, dynamic>>.from(
            tenantData['assignedProperties'] ?? []
          );
        });
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading properties: $e');
      setState(() => _isLoading = false);
    }
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
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadProperties,
        child: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : _assignedProperties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_work_outlined,
                          size: 100,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No properties assigned',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contact your landlord for property assignment',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _assignedProperties.length,
                    itemBuilder: (context, index) {
                      final property = _assignedProperties[index];
                      
                      return FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: Duration(milliseconds: index * 100),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => TenantPropertyDetailPage(
                              propertyData: property,
                            ));
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Property Image or Placeholder
                                Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor.withOpacity(0.8),
                                        AppTheme.primaryColor.withOpacity(0.6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Icon(
                                          Icons.home,
                                          size: 60,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                      if (property['isMultiUnit'] == true)
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.apartment,
                                                  size: 16,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Unit ${property['unitNumber']}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                              ],
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
                                      Text(
                                        property['propertyName'] ?? 
                                        property['address'] ?? 
                                        'Property ${index + 1}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${property['address'] ?? ''}, ${property['city']}, ${property['state']}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: AppTheme.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Property Info Grid
                                      Row(
                                        children: [
                                          // Bedrooms
                                          if (property['bedrooms'] != null)
                                            _buildInfoChip(
                                              Icons.bed_outlined,
                                              '${property['bedrooms']} Bed',
                                            ),
                                          const SizedBox(width: 8),
                                          
                                          // Bathrooms
                                          if (property['bathrooms'] != null)
                                            _buildInfoChip(
                                              Icons.bathtub_outlined,
                                              '${property['bathrooms']} Bath',
                                            ),
                                          const SizedBox(width: 8),
                                          
                                          // Area
                                          if (property['area'] != null)
                                            _buildInfoChip(
                                              Icons.square_foot,
                                              '${property['area']} sqft',
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Rent Amount
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Monthly Rent',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              currencyFormat.format(
                                                property['rentAmount'] ?? 0
                                              ),
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Lease Info
                                      if (property['leaseStartDate'] != null || 
                                          property['leaseEndDate'] != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_outlined,
                                                size: 16,
                                                color: AppTheme.textSecondary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Lease Period',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${_formatDate(property['leaseStartDate'])} - ${_formatDate(property['leaseEndDate'])}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        return date;
      }
      return DateFormat('MMM yyyy').format(date.toDate());
    } catch (e) {
      return 'N/A';
    }
  }
}