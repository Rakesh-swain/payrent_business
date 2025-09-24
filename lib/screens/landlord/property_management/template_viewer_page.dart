import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import 'package:payrent_business/config/theme.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:payrent_business/services/storage_service.dart';

class TemplateViewerPage extends StatefulWidget {
  final String templateType; // 'property', 'tenant', or 'combined'
  final String title;

  const TemplateViewerPage({
    super.key, 
    required this.templateType,
    required this.title,
  });

  @override
  State<TemplateViewerPage> createState() => _TemplateViewerPageState();
}

class _TemplateViewerPageState extends State<TemplateViewerPage> {
  bool _isLoading = true;
  List<List<dynamic>> _csvData = [];
  String _errorMessage = '';
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _loadTemplateData();
  }

  Future<void> _loadTemplateData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Determine the template file name based on the type
      final String templateFileName = widget.templateType == 'property'
          ? 'property_template.csv'
          : widget.templateType == 'tenant'
              ? 'tenant_template.csv'
              : 'combined_template.csv';

      // Load the template from assets
      final String templateContent = await rootBundle.loadString('assets/templates/$templateFileName');

      // Parse the CSV data
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(templateContent);

      setState(() {
        _csvData = csvData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load template: ${e.toString()}';
      });
      print('Error loading template: $e');
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _isFullscreen 
          ? null 
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _toggleFullscreen,
                  tooltip: 'Fullscreen view',
                ),
                IconButton(
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: () {
                    // Implement download functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Template download started...'),
                      ),
                    );
                  },
                  tooltip: 'Download template',
                ),
              ],
            ),
      body: Stack(
        children: [
          if (_isFullscreen)
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(
                    Icons.fullscreen_exit,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFullscreen,
                  tooltip: 'Exit fullscreen',
                ),
              ),
            ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? _buildErrorState()
                  : _buildTemplateView(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
            'Error',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTemplateData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateView() {
    if (_csvData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template description
            if (!_isFullscreen) ...[
              Text(
                'Template Structure',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getTemplateDescription(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Required Fields',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getRequiredFields().map((field) {
                  return Chip(
                    label: Text(
                      field,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // CSV data table
            Expanded(
              child: Container(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowHeight: 48,
                        dataRowHeight: 56,
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        columns: _csvData.isNotEmpty
                            ? _csvData.first.map((header) {
                                return DataColumn(
                                  label: Text(
                                    header.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList()
                            : [],
                        rows: _csvData.length > 1
                            ? _csvData.sublist(1).map((row) {
                                return DataRow(
                                  cells: row.map((cell) {
                                    return DataCell(
                                      Text(
                                        cell.toString(),
                                        style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }).toList()
                            : [],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom note
            if (!_isFullscreen) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Using this template',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.infoColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Download this template, fill in your data following the format above, and then upload it using the bulk upload feature.',
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTemplateDescription() {
    switch (widget.templateType) {
      case 'property':
        return 'This template is used for adding multiple properties at once. It includes all the essential fields to define properties in your portfolio.';
      case 'tenant':
        return 'This template is used for adding multiple tenants at once. Make sure the properties referenced already exist in your account.';
      case 'combined':
        return 'This template lets you add both properties and tenants in a single operation. Use this when setting up properties that already have tenants.';
      default:
        return 'Use this template to bulk upload your data.';
    }
  }

  List<String> _getRequiredFields() {
    switch (widget.templateType) {
      case 'property':
        return [
          'Property Name', 
          'Address', 
          'City', 
          'State', 
          'Zip', 
          'Property Type', 
          'Monthly Rent'
        ];
      case 'tenant':
        return [
          'First Name', 
          'Last Name', 
          'Email', 
          'Phone', 
          'Property', 
          'Unit', 
          'Lease Start', 
          'Lease End'
        ];
      case 'combined':
        return [
          'Property Name', 
          'Address', 
          'City', 
          'State', 
          'Zip', 
          'Property Type', 
          'Monthly Rent', 
          'Tenant First Name', 
          'Tenant Last Name', 
          'Tenant Email', 
          'Tenant Phone', 
          'Unit', 
          'Lease Start', 
          'Lease End'
        ];
      default:
        return [];
    }
  }
}