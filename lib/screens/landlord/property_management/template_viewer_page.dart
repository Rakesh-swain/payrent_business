// lib/screens/landlord/property_management/template_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:payrent_business/config/theme.dart';

class TemplateViewerPage extends StatelessWidget {
  final String format;
  final String uploadType;

  const TemplateViewerPage({
    Key? key,
    required this.format,
    required this.uploadType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${format.toUpperCase()} Template',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Add a feature to export/share the template if needed
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template export feature coming soon')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
      body: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Template Information',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTemplateDescription(),
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildInfoChip(
                            uploadType == 'properties'
                                ? 'For property uploads'
                                : uploadType == 'tenants'
                                    ? 'For tenant uploads'
                                    : 'For property & tenant uploads',
                            uploadType == 'properties'
                                ? Icons.home
                                : uploadType == 'tenants'
                                    ? Icons.person
                                    : Icons.apartment,
                          ),
                          // const SizedBox(width: 8),
                          // _buildInfoChip(
                          //   format.toUpperCase(),
                          //   format == 'csv'
                          //       ? Icons.insert_drive_file_outlined
                          //       : Icons.table_chart_outlined,
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Template Preview',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildTemplateViewer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryColor),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12),
      ),
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildTemplateViewer() {
    // Get the appropriate template data based on upload type
    final templateData = _getTemplateData();
    
    // Get headers and rows
    final headers = templateData['headers'] as List<String>;
    final rows = templateData['rows'] as List<List<String>>;
    
    // Create the template viewer UI
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
            verticalInside: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          columns: headers.map((header) {
            return DataColumn(
              label: Text(
                header,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          rows: rows.map((row) {
            return DataRow(
              cells: row.map((cell) {
                return DataCell(
                  Text(
                    cell,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

String _getTemplateDescription() {
  if (uploadType == 'properties') {
    return 'This template shows the required format for uploading properties. Each row represents either a property or a unit within a multi-unit property. For multi-unit properties, use the same Property Name for all units and set "Is Multi Unit" to TRUE.';
  } else if (uploadType == 'tenants') {
    return 'This template shows the required format for uploading tenants. Each row represents one tenant with basic contact information. Property and lease details are managed separately.';
  } else {
    return 'This template shows the required format for uploading both properties and tenants together. For multi-unit properties, use the same Property Name for all units, set "Is Multi Unit" to TRUE, and include tenant details for each unit.';
  }
}

Map<String, dynamic> _getTemplateData() {
  if (uploadType == 'properties') {
    return {
      'headers': [
        'Property Name', 'Address', 'City', 'State', 'Zip', 'Property Type',
        'Payment Frequency', 'Is Multi Unit', 'Unit Number', 'Unit Type', 'Bedrooms', 'Bathrooms', 'Rent'
      ],
      'rows': [
        // Single unit property example
        [
          'Highland Villa', '789 Highland Ave', 'Austin', 'TX', '78703',
          'Single Family', 'Monthly', 'FALSE', 'Main', 'Standard', '4', '3', '2750'
        ],
        // Multi-unit property examples (same property, multiple units)
        [
          'Lakeside Apartment', '123 Lake View Dr', 'Chicago', 'IL', '60601',
          'Apartment', 'Monthly', 'TRUE', 'A101', 'Studio', '0', '1', '950'
        ],
        [
          'Lakeside Apartment', '123 Lake View Dr', 'Chicago', 'IL', '60601',
          'Apartment', 'Monthly', 'TRUE', 'A102', '1BR', '1', '1', '1250'
        ],
        [
          'Lakeside Apartment', '123 Lake View Dr', 'Chicago', 'IL', '60601',
          'Apartment', 'Monthly', 'TRUE', 'A103', '2BR', '2', '1', '1850'
        ],
      ],
    };
  } else if (uploadType == 'tenants') {
    return {
      'headers': [
        'First Name', 'Last Name', 'Email', 'Phone'
      ],
      'rows': [
        [
          'John', 'Doe', 'john.doe@example.com', '(312) 555-7890'
        ],
        [
          'Sarah', 'Johnson', 'sarah.j@example.com', '(415) 555-1234'
        ],
        [
          'Michael', 'Smith', 'msmith@example.com', '(512) 555-3456'
        ],
      ],
    };
  } else { // Both
    return {
      'headers': [
        'Property Name', 'Address', 'City', 'State', 'Zip', 'Property Type',
        'Payment Frequency', 'Is Multi Unit', 'Unit Number', 'Unit Type', 'Bedrooms', 'Bathrooms', 'Rent',
        'Tenant First Name', 'Tenant Last Name', 'Email', 'Phone',
        'Lease Start', 'Lease End', 'Security Deposit'
      ],
      'rows': [
        // Single unit property with tenant
        [
          'Highland Villa', '789 Highland Ave', 'Austin', 'TX', '78703',
          'Single Family', 'Monthly', 'FALSE', 'Main', 'Standard', '4', '3', '2750',
          'Michael', 'Smith', 'msmith@example.com', '(512) 555-3456',
          '2023-08-01', '2024-07-31', '4125'
        ],
        // Multi-unit property with tenants (same property, multiple units)
        [
          'Lakeside Apartment', '123 Lake View Dr', 'Chicago', 'IL', '60601',
          'Apartment', 'Monthly', 'TRUE', 'A101', 'Studio', '0', '1', '950',
          'John', 'Doe', 'john.doe@example.com', '(312) 555-7890',
          '2023-06-01', '2024-05-31', '1425'
        ],
        [
          'Lakeside Apartment', '123 Lake View Dr', 'Chicago', 'IL', '60601',
          'Apartment', 'Monthly', 'TRUE', 'A102', '1BR', '1', '1', '1250',
          'Sarah', 'Johnson', 'sarah.j@example.com', '(415) 555-1234',
          '2023-04-15', '2024-04-14', '1875'
        ],
      ],
    };
  }
}
}