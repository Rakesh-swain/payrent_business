import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:payrent_business/controllers/bulk_upload_controller.dart';
import 'package:payrent_business/screens/landlord/property_management/template_viewer_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/property_model.dart';
import 'package:payrent_business/widgets/common/app_loading_indicator.dart';

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
  
  // Data for preview with editing support
  List<Map<String, dynamic>> _previewData = [];
  List<Map<String, dynamic>> _originalData = []; // For tracking changes
  BulkUploadController bulkUploadController = Get.put(BulkUploadController());

  
  // Upload results
  int _successCount = 0;
  int _errorCount = 0;
  List<String> _errorMessages = [];
  
  @override
  void initState() {
    super.initState();
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
                _previewData = List<Map<String, dynamic>>.from(parsedData);
                _originalData = List<Map<String, dynamic>>.from(parsedData);
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
  
  void _showTemplateFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Choose Template Format', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select your preferred template format',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFormatOption(context, 'CSV', Icons.insert_drive_file_outlined),
                _buildFormatOption(context, 'Excel', Icons.table_chart_outlined),
              ],
            ),
          ],
        ),
      ),
    ).then((format) {
      if (format != null) {
        _navigateToTemplateViewer(format);
      }
    });
  }

  Widget _buildFormatOption(BuildContext context, String format, IconData icon) {
    return InkWell(
      onTap: () => Navigator.pop(context, format),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              format,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTemplateViewer(String format) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateViewerPage(
          format: format.toLowerCase(),
          uploadType: _uploadType,
        ),
      ),
    );
  }
  
  Future<void> _uploadFile() async {
    setState(() {
      _isUploading = true;
      _successCount = 0;
      _errorCount = 0;
      _errorMessages = [];
    });
    
    try {
      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      if (_uploadType == 'properties') {
        await bulkUploadController.uploadProperties(_previewData);
      } else if (_uploadType == 'tenants') {
        await bulkUploadController.uploadTenants(_previewData);
      } else { // Both
        await bulkUploadController.uploadBoth(_previewData);
      }
      
      setState(() {
        _isUploading = false;
      });
      
      // Show success dialog
      _showUploadResultDialog(_errorCount == 0);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessages.add(e.toString());
        _errorCount++;
      });
      
      _showUploadResultDialog(false);
    }
  }
  
  // Upload properties to Firebase
// Upload properties to Firebase

  
  
  void _changeUploadType(String type) {
    setState(() {
      _uploadType = type;
      _selectedFile = null;
      _selectedFilePath = null;
      _previewData.clear();
      _originalData.clear();
      _currentStep = 0;
      _fileRowCount = 0;
      _fileSize = '';
      _isFileError = false;
      _fileErrorMessage = '';
    });
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
                        ? '$_successCount properties have been uploaded successfully'
                        : _uploadType == 'tenants'
                            ? '$_successCount tenants have been uploaded successfully'
                            : '$_successCount properties with tenants have been uploaded successfully'
                    : 'There were issues with the upload. Please check the errors below.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              
              // Show error messages
              if (_errorMessages.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _errorMessages.map((message) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  message,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              
              
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
                  child: Text(isSuccess ? 'Done' : 'Try Again',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      )),
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
        title: Text('Bulk Upload', style: GoogleFonts.poppins()),
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
                      : _currentStep < 1
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
                  child: _currentStep < 1
                      ? const Text('Next')
                      : _isUploading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: AppLoadingIndicator(size: 24),
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
        // _buildStepCircle(1, 'Map Columns'),
        // _buildStepConnector(1),
        _buildStepCircle(1, 'Review & Upload'),
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
            children: [
              Expanded(
                child: _buildUploadTypeOption(
                  'Properties',
                  Icons.home_outlined,
                  'properties',
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildUploadTypeOption(
                  'Tenants',
                  Icons.people_outline,
                  'tenants',
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildUploadTypeOption(
                  'Both',
                  Icons.apartment_outlined,
                  'both',
                ),
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
                      child: AppLoadingIndicator(),
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
                                    _originalData.clear();
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
                        onTap: _showTemplateFormatDialog,
                        child: Text(
                          'See Template Format',
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
            'Review and edit the data before uploading',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Editable data preview
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
              child: _buildEditableDataTable(),
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
  
  // Build an editable data table with TextField widgets
  Widget _buildEditableDataTable() {
    if (_previewData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No data to preview',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }
    
    final headers = _previewData.first.keys.toList();
    
    return DataTable(
      columnSpacing: 24,
      dataRowHeight: 64,
      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
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
      rows: List.generate(_previewData.length, (rowIndex) {
        return DataRow(
          cells: headers.map((header) {
            return DataCell(
              TextField(
                controller: TextEditingController(text: _previewData[rowIndex][header]?.toString() ?? ''),
                onChanged: (value) {
                  setState(() {
                    _previewData[rowIndex][header] = value;
                  });
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  isDense: true,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
  
  Widget _buildUploadTypeOption(String label, IconData icon, String type) {
    final bool isSelected = _uploadType == type;
    
    return InkWell(
      onTap: () => _changeUploadType(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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