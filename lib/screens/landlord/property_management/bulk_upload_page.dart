// lib/screens/landlord/property_management/bulk_upload_page.dart

import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:payrent_business/config/theme.dart';

class BulkUploadPage extends StatefulWidget {
  const BulkUploadPage({super.key});

  @override
  State<BulkUploadPage> createState() => _BulkUploadPageState();
}

class _BulkUploadPageState extends State<BulkUploadPage> {
  bool _isLoading = false;
  bool _isUploading = false;
  String? _selectedFile;
  String? _selectedFilePath;
  String _uploadType = 'properties';
  int _fileRowCount = 0;
  String _fileSize = '';
  bool _isFileError = false;
  String _fileErrorMessage = '';
  
  // Step indicator
  int _currentStep = 0;
  
  // Sample data for preview
  final List<Map<String, dynamic>> _previewData = [];
  
  // Sample column mappings
   Map<String, String> _columnMappings = {};
   List<String> _requiredColumns = [];
   List<String> _availableColumns = [];
  
  @override
  void initState() {
    super.initState();
    _initializeColumns();
  }
  Future<int> _androidVersion() async {
  var version = await DeviceInfoPlugin().androidInfo;
  return version.version.sdkInt;
}

  void _initializeColumns() {
    // Initialize based on upload type
    if (_uploadType == 'properties') {
      _requiredColumns = [
        'Property Name',
        'Address',
        'City',
        'State',
        'Zip',
        'Property Type',
        'Monthly Rent',
      ];
      
      _availableColumns = [
        'Property Name',
        'Address',
        'City',
        'State',
        'Zip',
        'Property Type',
        'Monthly Rent',
        'Bedrooms',
        'Bathrooms',
        'Square Feet',
        'Year Built',
        'Description',
      ];
    } else if (_uploadType == 'tenants') {
      _requiredColumns = [
        'First Name',
        'Last Name',
        'Email',
        'Phone',
        'Property',
        'Unit',
        'Lease Start',
        'Lease End',
      ];
      
      _availableColumns = [
        'First Name',
        'Last Name',
        'Email',
        'Phone',
        'Property',
        'Unit',
        'Lease Start',
        'Lease End',
        'Monthly Rent',
        'Security Deposit',
        'Emergency Contact Name',
        'Emergency Contact Phone',
      ];
    } else if (_uploadType == 'both') {
      _requiredColumns = [
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
        'Lease Start',
        'Lease End',
      ];
      
      _availableColumns = [
        'Property Name',
        'Address',
        'City',
        'State',
        'Zip',
        'Property Type',
        'Monthly Rent',
        'Bedrooms',
        'Bathrooms',
        'Square Feet',
        'Tenant First Name',
        'Tenant Last Name',
        'Tenant Email',
        'Tenant Phone',
        'Lease Start',
        'Lease End',
        'Security Deposit',
        'Emergency Contact Name',
        'Emergency Contact Phone',
      ];
    }
    
    // Initialize default mappings
    _columnMappings.clear();
    for (var column in _requiredColumns) {
      _columnMappings[column] = column;
    }
  }
  
  Future<void> _selectFile() async {
    setState(() {
      _isLoading = true;
      _isFileError = false;
      _fileErrorMessage = '';
    });
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;
        
        if (filePath != null) {
          final fileName = file.name;
          final extension = path.extension(fileName).toLowerCase();
          
          // Calculate file size
          final fileSize = await _getFileSize(filePath);
          
          if (extension == '.csv' || extension == '.xlsx' || extension == '.xls') {
            // Parse the file
            final parsedData = await _parseFile(filePath, extension);
            
            if (parsedData.isNotEmpty) {
              setState(() {
                _selectedFile = fileName;
                _selectedFilePath = filePath;
                _fileSize = fileSize;
                _fileRowCount = parsedData.length;
                _previewData.clear();
                _previewData.addAll(parsedData);
                _isLoading = false;
              });
            } else {
              setState(() {
                _isLoading = false;
                _isFileError = true;
                _fileErrorMessage = 'Could not parse the file or file is empty';
              });
            }
          } else {
            setState(() {
              _isLoading = false;
              _isFileError = true;
              _fileErrorMessage = 'Unsupported file format. Please use CSV or Excel files.';
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _isFileError = true;
            _fileErrorMessage = 'Could not access file path';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isFileError = true;
        _fileErrorMessage = 'Error selecting file: ${e.toString()}';
      });
    }
  }
  
  Future<String> _getFileSize(String filePath) async {
    final file = File(filePath);
    final bytes = await file.length();
    
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  Future<List<Map<String, dynamic>>> _parseFile(String filePath, String extension) async {
    try {
      if (extension == '.csv') {
        return await _parseCSV(filePath);
      } else if (extension == '.xlsx' || extension == '.xls') {
        return await _parseExcel(filePath);
      }
      return [];
    } catch (e) {
      setState(() {
        _isFileError = true;
        _fileErrorMessage = 'Error parsing file: ${e.toString()}';
      });
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> _parseCSV(String filePath) async {
    final file = File(filePath);
    final contents = await file.readAsString();
    
    final csvTable = const CsvToListConverter().convert(contents);
    
    if (csvTable.isEmpty) {
      return [];
    }
    
    final headers = csvTable[0].map((e) => e.toString()).toList();
    final List<Map<String, dynamic>> result = [];
    
    // Skip header row
    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      if (row.length != headers.length) continue;
      
      final Map<String, dynamic> rowData = {};
      for (int j = 0; j < headers.length; j++) {
        rowData[headers[j]] = row[j].toString();
      }
      
      result.add(rowData);
    }
    
    return result;
  }
  
  Future<List<Map<String, dynamic>>> _parseExcel(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    
    if (excel.tables.isEmpty) {
      return [];
    }
    
    final sheet = excel.tables.keys.first;
    final table = excel.tables[sheet];
    
    if (table == null || table.rows.isEmpty) {
      return [];
    }
    
    final headers = table.rows[0].map((cell) => cell?.value.toString() ?? '').toList();
    final List<Map<String, dynamic>> result = [];
    
    // Skip header row
    for (int i = 1; i < table.rows.length; i++) {
      final row = table.rows[i];
      if (row.length != headers.length) continue;
      
      final Map<String, dynamic> rowData = {};
      for (int j = 0; j < headers.length; j++) {
        rowData[headers[j]] = row[j]?.value.toString() ?? '';
      }
      
      result.add(rowData);
    }
    
    return result;
  }
  
  Future<void> downloadTemplate() async {
    try {
      // Request storage permission
      // var status = await Permission.storage.request();

      PermissionStatus status;
if (Platform.isAndroid && (await _androidVersion()) >= 30) {
  status = await Permission.manageExternalStorage.request();
} else {
  status = await Permission.storage.request();
}
        if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission is required to download templates')),
        );
        return;
      }
      // Get the template content based on upload type
      final templateName = _uploadType == 'properties' 
          ? 'property_template.csv' 
          : _uploadType == 'tenants' 
              ? 'tenant_template.csv' 
              : 'combined_template.csv';
      
      // Load the template from assets
      String templateContent = '';
      
      if (_uploadType == 'properties') {
        templateContent = '''Property Name,Address,City,State,Zip,Property Type,Monthly Rent,Bedrooms,Bathrooms,Square Feet,Year Built,Description
Lakeside Apartment,123 Lake View Dr,Chicago,IL,60601,Apartment,1850,2,1,950,2005,Modern apartment with lake view and updated kitchen. Close to public transportation and shopping centers.
Oakwood Townhouse,456 Oak Street,San Francisco,CA,94107,Townhouse,3200,3,2.5,1650,1998,Spacious townhouse with private backyard and garage. Recently renovated with hardwood floors throughout.
Highland Villa,789 Highland Ave,Austin,TX,78703,Single-Family,2750,4,3,2200,2010,Beautiful family home in quiet neighborhood with large yard. Features open floor plan and updated appliances.''';
      } else if (_uploadType == 'tenants') {
        templateContent = '''First Name,Last Name,Email,Phone,Property,Unit,Lease Start,Lease End,Monthly Rent,Security Deposit,Emergency Contact Name,Emergency Contact Phone
John,Doe,john.doe@example.com,(312) 555-7890,Lakeside Apartment,Unit 303,2023-06-01,2024-05-31,1850,2775,Mary Doe,(312) 555-9876
Sarah,Johnson,sarah.j@example.com,(415) 555-1234,Oakwood Townhouse,Unit B,2023-04-15,2024-04-14,3200,4800,Robert Johnson,(415) 555-5678
Michael,Smith,msmith@example.com,(512) 555-3456,Highland Villa,Main House,2023-08-01,2024-07-31,2750,4125,Jennifer Smith,(512) 555-7890
Emily,Williams,emily.w@example.com,(312) 555-4321,Lakeside Apartment,Unit 305,2023-07-15,2024-07-14,1850,2775,Thomas Williams,(312) 555-8765''';
      } else {
        templateContent = '''Property Name,Address,City,State,Zip,Property Type,Monthly Rent,Bedrooms,Bathrooms,Square Feet,Tenant First Name,Tenant Last Name,Tenant Email,Tenant Phone,Unit,Lease Start,Lease End,Security Deposit,Emergency Contact Name,Emergency Contact Phone
Lakeside Apartment,123 Lake View Dr,Chicago,IL,60601,Apartment,1850,2,1,950,John,Doe,john.doe@example.com,(312) 555-7890,Unit 303,2023-06-01,2024-05-31,2775,Mary Doe,(312) 555-9876
Oakwood Townhouse,456 Oak Street,San Francisco,CA,94107,Townhouse,3200,3,2.5,1650,Sarah,Johnson,sarah.j@example.com,(415) 555-1234,Unit B,2023-04-15,2024-04-14,4800,Robert Johnson,(415) 555-5678
Highland Villa,789 Highland Ave,Austin,TX,78703,Single-Family,2750,4,3,2200,Michael,Smith,msmith@example.com,(512) 555-3456,Main House,2023-08-01,2024-07-31,4125,Jennifer Smith,(512) 555-7890''';
      }
      
      // Get the download directory
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, templateName);
      
      // Write the template to a file
      final file = File(filePath);
      await file.writeAsString(templateContent);
      
      // Show success message with file path
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template downloaded to: $filePath'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading template: ${e.toString()}')),
      );
    }
  }
  
  void _uploadFile() async {
    setState(() {
      _isUploading = true;
    });
    
    // Simulate upload process
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isUploading = false;
    });
    
    // Show success dialog
    _showUploadResultDialog(true);
  }
  
  void _changeUploadType(String type) {
    setState(() {
      _uploadType = type;
      _selectedFile = null;
      _selectedFilePath = null;
      _previewData.clear();
      _currentStep = 0;
      _fileRowCount = 0;
      _fileSize = '';
      _isFileError = false;
      _fileErrorMessage = '';
    });
    _initializeColumns();
  }
  
  void _nextStep() {
    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
      }
    });
  }
  
  void _prevStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }
  
  void _showUploadResultDialog(bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSuccess
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  size: 48,
                  color: isSuccess ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess ? 'Upload Successful' : 'Upload Failed',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isSuccess ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? _uploadType == 'properties'
                        ? '$_fileRowCount properties have been uploaded successfully'
                        : _uploadType == 'tenants'
                            ? '$_fileRowCount tenants have been uploaded successfully'
                            : '$_fileRowCount properties with tenants have been uploaded successfully'
                    : 'There was an issue uploading your file. Please try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              if (isSuccess)
                Text(
                  'Upload ID: BLK${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (isSuccess) {
                      Navigator.of(context).pop(); // Return to property list
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? AppTheme.primaryColor : AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isSuccess ? 'Done' : 'Try Again'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bulk Upload'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stepper
          Padding(
            padding: const EdgeInsets.all(16),
            child: FadeInDown(
              duration: const Duration(milliseconds: 300),
              child: _buildStepper(),
            ),
          ),
          
          // Content based on current step
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentStep == 0)
                    _buildStep1()
                  else if (_currentStep == 1)
                    _buildStep2()
                  else if (_currentStep == 2)
                    _buildStep3(),
                ],
              ),
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _prevStep,
                    child: Text(
                      'Back',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  const SizedBox(),
                
                ElevatedButton(
                  onPressed: _currentStep == 0 && _selectedFile == null
                      ? null
                      : _currentStep < 2
                          ? _nextStep
                          : _isUploading
                              ? null
                              : _uploadFile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _currentStep < 2
                      ? const Text('Next')
                      : _isUploading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Uploading...',
                                  style: GoogleFonts.poppins(),
                                ),
                              ],
                            )
                          : const Text('Upload'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepper() {
    return Row(
      children: [
        _buildStepCircle(0, 'Select File'),
        _buildStepConnector(0),
        _buildStepCircle(1, 'Map Columns'),
        _buildStepConnector(1),
        _buildStepCircle(2, 'Review & Upload'),
      ],
    );
  }
  
  Widget _buildStepCircle(int step, String label) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
              border: isCurrent
                  ? Border.all(
                      color: AppTheme.primaryColor,
                      width: 2,
                    )
                  : null,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              color: isCurrent ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepConnector(int step) {
    bool isActive = _currentStep > step;
    
    return Container(
      width: 40,
      height: 2,
      color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
    );
  }
  
  Widget _buildStep1() {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you want to upload?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          // Upload type selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildUploadTypeOption(
                'Properties',
                Icons.home_outlined,
                'properties',
              ),
              _buildUploadTypeOption(
                'Tenants',
                Icons.people_outline,
                'tenants',
              ),
              _buildUploadTypeOption(
                'Both',
                Icons.apartment_outlined,
                'both',
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Select file to upload',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // File upload box
          GestureDetector(
            onTap: _isLoading ? null : _selectFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFileError 
                      ? AppTheme.errorColor 
                      : _selectedFile != null
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                  width: 1,
                ) ,
              ),
              child: _isLoading 
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isFileError) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: 40,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _fileErrorMessage,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _selectFile,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Try Again'),
                          ),
                        ] else if (_selectedFile == null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Click to select a CSV or Excel file',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'or drag and drop it here',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _selectedFile!.endsWith('.csv')
                                      ? Icons.insert_drive_file_outlined
                                      : Icons.table_chart_outlined,
                                  size: 32,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedFile!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_fileRowCount rows • $_fileSize • Ready to process',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedFile = null;
                                    _selectedFilePath = null;
                                    _previewData.clear();
                                    _fileRowCount = 0;
                                    _fileSize = '';
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.infoColor.withOpacity(0.3),
                width: 1,
              ),
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
                        'File Format Requirements',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.infoColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _uploadType == 'properties'
                            ? 'CSV or Excel file with columns for property details (name, address, type, etc.)'
                            : _uploadType == 'tenants'
                                ? 'CSV or Excel file with columns for tenant details (name, email, phone, property, etc.)'
                                : 'CSV or Excel file with columns for both property and tenant details',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: downloadTemplate,
                        child: Text(
                          'Download Template',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep2() {
    // Get file columns from the preview data
    final fileColumns = _previewData.isNotEmpty 
        ? _previewData.first.keys.toList() 
        : ['Column A', 'Column B', 'Column C', 'Column D', 'Column E', 'Column F', 'Column G', 'Column H'];
    
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Map Columns',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Match columns from your file to the required fields in our system',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Column mapping
          Container(
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
                // Column mappings
                ..._requiredColumns.map((column) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Required Field',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                column,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _columnMappings[column],
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: 'Select column',
                            ),
                            items: fileColumns.map((String column) {
                              return DropdownMenuItem<String>(
                                value: column,
                                child: Text(
                                  column,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _columnMappings[column] = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Auto-map button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Auto-mapping functionality
                final Map<String, String> newMappings = {};
                
                // Try to match columns exactly
                for (var requiredColumn in _requiredColumns) {
                  if (fileColumns.contains(requiredColumn)) {
                    newMappings[requiredColumn] = requiredColumn;
                  }
                }
                
                // For any remaining columns, try case-insensitive match
                for (var requiredColumn in _requiredColumns) {
                  if (!newMappings.containsKey(requiredColumn)) {
                    for (var fileColumn in fileColumns) {
                      if (fileColumn.toLowerCase() == requiredColumn.toLowerCase()) {
                        newMappings[requiredColumn] = fileColumn;
                        break;
                      }
                    }
                  }
                }
                
                // Update mappings
                setState(() {
                  _columnMappings = {..._columnMappings, ...newMappings};
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Columns mapped automatically',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppTheme.infoColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                'Auto-Map Columns',
                style: GoogleFonts.poppins(),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep3() {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Upload',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review the data before uploading to ensure everything is correct',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Data preview
          Container(
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                dataRowHeight: 64,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                border: TableBorder(
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                columns: _previewData.isEmpty
                    ? [const DataColumn(label: Text('No data to preview'))]
                    : _previewData.first.keys.map((key) {
                        return DataColumn(
                          label: Text(
                            key,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                rows: _previewData.isEmpty
                    ? [
                        DataRow(cells: [DataCell(Container())]),
                      ]
                    : _previewData.map((data) {
                        return DataRow(
                          cells: data.values.map((value) {
                            return DataCell(
                              Text(
                                value.toString(),
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Upload summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  'File',
                  _selectedFile ?? 'No file selected',
                  Icons.insert_drive_file_outlined,
                ),
                const Divider(height: 24),
                _buildSummaryItem(
                  'Type',
                  _uploadType == 'properties'
                      ? 'Properties'
                      : _uploadType == 'tenants'
                          ? 'Tenants'
                          : 'Properties & Tenants',
                  _uploadType == 'properties'
                      ? Icons.home_outlined
                      : _uploadType == 'tenants'
                          ? Icons.people_outline
                          : Icons.apartment_outlined,
                ),
                const Divider(height: 24),
                _buildSummaryItem(
                  'Records',
                  '${_previewData.length} records will be processed',
                  Icons.format_list_numbered_outlined,
                ),
                if (_uploadType == 'both' || _uploadType == 'properties') ...[
                  const Divider(height: 24),
                  _buildSummaryItem(
                    'Properties',
                    '${_previewData.length} properties will be created',
                    Icons.home_outlined,
                  ),
                ],
                if (_uploadType == 'both' || _uploadType == 'tenants') ...[
                  const Divider(height: 24),
                  _buildSummaryItem(
                    'Tenants',
                    '${_previewData.length} tenants will be created',
                    Icons.people_outlined,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUploadTypeOption(String label, IconData icon, String type) {
    final bool isSelected = _uploadType == type;
    
    return InkWell(
      onTap: () => _changeUploadType(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
