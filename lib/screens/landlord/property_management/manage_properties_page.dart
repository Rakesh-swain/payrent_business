import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/property_model.dart';
import 'package:payrent_business/screens/landlord/property_management/add_property_page.dart';
import 'package:payrent_business/screens/landlord/property_management/bulk_upload_page.dart';
import 'package:payrent_business/screens/landlord/property_management/property_list_page.dart';

class ManagePropertiesPage extends StatefulWidget {
  const ManagePropertiesPage({super.key});

  @override
  State<ManagePropertiesPage> createState() => _ManagePropertiesPageState();
}

class _ManagePropertiesPageState extends State<ManagePropertiesPage> {
  bool _isLoading = true;
  int _totalProperties = 0;
  int _totalUnits = 0;
  int _occupiedUnits = 0;
  int _vacantUnits = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPropertyStatistics();
  }

  Future<void> _fetchPropertyStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch all properties for the current user
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .get();

      int totalProperties = propertiesSnapshot.docs.length;
      int totalUnits = 0;
      int occupiedUnits = 0;

      // Calculate unit statistics
      for (var propertyDoc in propertiesSnapshot.docs) {
        try {
          final property = PropertyModel.fromFirestore(propertyDoc);
          
          // Count total units
          totalUnits += property.units.length;
          
          // Count occupied units (units with tenantId)
          occupiedUnits += property.units
              .where((unit) => unit.tenantId != null && unit.tenantId!.isNotEmpty)
              .length;
        } catch (e) {
          print('Error processing property ${propertyDoc.id}: $e');
          // Continue processing other properties even if one fails
        }
      }

      int vacantUnits = totalUnits - occupiedUnits;

      setState(() {
        _totalProperties = totalProperties;
        _totalUnits = totalUnits;
        _occupiedUnits = occupiedUnits;
        _vacantUnits = vacantUnits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error fetching property statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            Text(
              'Property Management',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your properties efficiently',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Add Property Card
            FadeInUp(
              duration: const Duration(milliseconds: 300),
              child: _buildActionCard(
                context: context,
                title: 'Add New Property',
                subtitle: 'Add a single property with all details',
                icon: Icons.add_home_outlined,
                color: AppTheme.primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPropertyPage(),
                    ),
                  ).then((_) {
                    // Refresh statistics when returning from add property page
                    _fetchPropertyStatistics();
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bulk Upload Card
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: _buildActionCard(
                context: context,
                title: 'Bulk Upload',
                subtitle: 'Upload multiple properties or tenants at once',
                icon: Icons.upload_file_outlined,
                color: const Color(0xFF8E44AD), // Purple
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BulkUploadPage(),
                    ),
                  ).then((_) {
                    // Refresh statistics when returning from bulk upload page
                    _fetchPropertyStatistics();
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // View Properties Card
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: _buildActionCard(
                context: context,
                title: 'View All Properties',
                subtitle: 'Manage your existing properties',
                icon: Icons.apartment_outlined,
                color: const Color(0xFF2980B9), // Blue
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PropertyListPage(),
                    ),
                  ).then((_) {
                    // Refresh statistics when returning from property list page
                    _fetchPropertyStatistics();
                  });
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Property Statistics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_isLoading)
                  IconButton(
                    onPressed: _fetchPropertyStatistics,
                    icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
                    tooltip: 'Refresh Statistics',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error loading statistics: $_errorMessage',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: _buildStatCard(
                      title: 'Total Properties',
                      value: _isLoading ? '...' : '$_totalProperties',
                      icon: Icons.home_outlined,
                      color: AppTheme.primaryColor,
                      isLoading: _isLoading,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: _buildStatCard(
                      title: 'Occupied Units',
                      value: _isLoading ? '...' : '$_occupiedUnits',
                      icon: Icons.people_outline,
                      color: const Color(0xFF2ECC71), // Green
                      isLoading: _isLoading,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: _buildStatCard(
                      title: 'Vacant Units',
                      value: _isLoading ? '...' : '$_vacantUnits',
                      icon: Icons.door_front_door_outlined,
                      color: const Color(0xFFE74C3C), // Red
                      isLoading: _isLoading,
                    ),
                  ),
                ),
              ],
            ),
            
            // Additional Stats Row
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: _buildStatCard(
                      title: 'Total Units',
                      value: _isLoading ? '...' : '$_totalUnits',
                      icon: Icons.apartment,
                      color: const Color(0xFF3498DB), // Blue
                      isLoading: _isLoading,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: _buildStatCard(
                      title: 'Occupancy Rate',
                      value: _isLoading 
                          ? '...' 
                          : _totalUnits > 0 
                              ? '${((_occupiedUnits / _totalUnits) * 100).toStringAsFixed(0)}%'
                              : '0%',
                      icon: Icons.trending_up,
                      color: const Color(0xFF9B59B6), // Purple
                      isLoading: _isLoading,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Empty space to maintain alignment
                Expanded(child: SizedBox()),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick Tips
            FadeInUp(
              duration: const Duration(milliseconds: 1100),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.infoColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.infoColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Tips',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.infoColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTipItem(
                      'Use bulk upload to save time when adding multiple properties',
                    ),
                    _buildTipItem(
                      'Statistics refresh automatically when you make changes',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppTheme.infoColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}