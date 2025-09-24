import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/screens/landlord/property_management/add_property_page.dart';
import 'package:payrent_business/screens/landlord/property_management/bulk_upload_page.dart';
import 'package:payrent_business/screens/landlord/property_management/property_list_page.dart';

class ManagePropertiesPage extends StatelessWidget {
  const ManagePropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   title:  Text('Manage Properties',style: GoogleFonts.poppins(
      //                 fontSize: 22,
      //                 fontWeight: FontWeight.w500,
      //               ),),
      // ),
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
                  );
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
                      builder: (context) =>  BulkUploadPage(),
                    ),
                  );
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
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Section
            Text(
              'Property Statistics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: _buildStatCard(
                      title: 'Total Properties',
                      value: '4',
                      icon: Icons.home_outlined,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: _buildStatCard(
                      title: 'Occupied',
                      value: '2',
                      icon: Icons.people_outline,
                      color: const Color(0xFF2ECC71), // Green
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: _buildStatCard(
                      title: 'Vacant',
                      value: '2',
                      icon: Icons.door_front_door_outlined,
                      color: const Color(0xFFE74C3C), // Red
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick Tips
            FadeInUp(
              duration: const Duration(milliseconds: 900),
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
                      'Add detailed information to attract quality tenants',
                    ),
                    _buildTipItem(
                      'Keep your property photos up to date',
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
            child: Icon(
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