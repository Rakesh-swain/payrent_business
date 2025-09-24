import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../controllers/property_controller.dart';
import '../../controllers/tenant_controller.dart';
import '../../models/property_model.dart';

class BulkUploadPage extends StatefulWidget {
   BulkUploadPage({Key? key}) : super(key: key);

  @override
  State<BulkUploadPage> createState() => _BulkUploadPageState();
}

class _BulkUploadPageState extends State<BulkUploadPage> {
  final PropertyController _propertyController = Get.find<PropertyController>();
  final TenantController _tenantController = Get.find<TenantController>();
  
  // Upload type selection
  final List<String> _uploadTypes = ['Properties', 'Tenants'];
  String _selectedUploadType = 'Properties';
  
  // File handling
  File? _selectedFile;
  String _fileName = '';
  List<List<dynamic>>? _fileData;
  
  // Upload status
  bool _isUploading = false;
  bool _validationError = false;
  String _statusMessage = '';
  List<String> _validationErrors = [];
  
  // Results
  int _successCount = 0;
  int _errorCount = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Upload'),
      ),
      body: SingleChildScrollView(
        padding:  EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Type Selection
            _buildSectionTitle('Select Upload Type'),
            
            SegmentedButton<String>(
              segments: _uploadTypes.map((type) {
                return ButtonSegment<String>(
                  value: type,
                  label: Text(type),
                );
              }).toList(),
              selected: {_selectedUploadType},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedUploadType = selection.first;
                  _resetUpload();
                });
              },
            ),
             SizedBox(height: 24.0),
            
            // File Upload Section
            _buildSectionTitle('Upload File'),
            
            Text(
              'Please upload a CSV or Excel file with the required format.',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
             SizedBox(height: 16.0),
            
            // File Selection
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:  EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      _fileName.isNotEmpty ? _fileName : 'No file selected',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                 SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: _selectFile,
                  child:  Text('Browse'),
                ),
              ],
            ),
             SizedBox(height: 24.0),
            
            // Template Download Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _downloadTemplate,
                icon:  Icon(Icons.download),
                label:  Text('Download Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
             SizedBox(height: 24.0),
            
            // Preview Section (if file is selected)
            if (_fileData != null && _fileData!.isNotEmpty) ...[
              _buildSectionTitle('File Preview'),
              
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: _getDataTableColumns(),
                    rows: _getDataTableRows(),
                    columnSpacing: 20.0,
                  ),
                ),
              ),
               SizedBox(height: 24.0),
            ],
            
            // Validation Errors (if any)
            if (_validationError && _validationErrors.isNotEmpty) ...[
              _buildSectionTitle('Validation Errors'),
              
              Container(
                padding:  EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final error in _validationErrors)
                      Padding(
                        padding:  EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Icon(Icons.error_outline, color: Colors.red, size: 16),
                             SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                error,
                                style:  TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
               SizedBox(height: 24.0),
            ],
            
            // Upload Status Message
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding:  EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: _validationError ? Colors.red[50] : Colors.green[50],
                  border: Border.all(
                    color: _validationError ? Colors.red[200]! : Colors.green[200]!,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      _validationError ? Icons.error_outline : Icons.check_circle_outline,
                      color: _validationError ? Colors.red : Colors.green,
                    ),
                     SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _validationError ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
               SizedBox(height: 24.0),
            ],
            
            // Upload Results
            if (_successCount > 0 || _errorCount > 0) ...[
              _buildSectionTitle('Upload Results'),
              
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding:  EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _successCount.toString(),
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                             SizedBox(height: 8.0),
                            Text(
                              'Successful',
                              style: TextStyle(
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                   SizedBox(width: 16.0),
                  Expanded(
                    child: Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding:  EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _errorCount.toString(),
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                             SizedBox(height: 8.0),
                            Text(
                              'Failed',
                              style: TextStyle(
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
               SizedBox(height: 24.0),
            ],
            
            // Upload Button
            Center(
              child: TextButton(
                onPressed: _selectedFile != null ? _processUpload : null,
                child: const Text('Upload'),
              ),
            ),
             SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }
  
  // Build section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding:  EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style:  TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // Reset upload state
  void _resetUpload() {
    setState(() {
      _selectedFile = null;
      _fileName = '';
      _fileData = null;
      _statusMessage = '';
      _validationError = false;
      _validationErrors = [];
      _successCount = 0;
      _errorCount = 0;
    });
  }
  
  // Select file for upload
  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() {
          _selectedFile = file;
          _fileName = result.files.first.name;
          _statusMessage = '';
          _validationError = false;
          _validationErrors = [];
        });
        
        // Parse the file
        await _parseFileContent();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting file: $e';
        _validationError = true;
      });
    }
  }
  
  // Parse file content
  Future<void> _parseFileContent() async {
    if (_selectedFile == null) return;
    
    try {
      final extension = _fileName.split('.').last.toLowerCase();
      
      if (extension == 'csv') {
        // Parse CSV file
        final input = _selectedFile!.readAsStringSync();
        final csv =  CsvToListConverter().convert(input);
        setState(() {
          _fileData = csv;
        });
      } else if (extension == 'xlsx' || extension == 'xls') {
        // Parse Excel file
        final bytes = _selectedFile!.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        
        if (excel.tables.isNotEmpty) {
          final sheet = excel.tables.keys.first;
          final rows = <List<dynamic>>[];
          
          for (final row in excel.tables[sheet]!.rows) {
            rows.add(row.map((cell) => cell?.value ?? '').toList());
          }
          
          setState(() {
            _fileData = rows;
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Unsupported file format';
          _validationError = true;
        });
      }
      
      // Validate the data
      _validateData();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error parsing file: $e';
        _validationError = true;
      });
    }
  }
  
  // Validate the data
  void _validateData() {
    if (_fileData == null || _fileData!.isEmpty) {
      setState(() {
        _validationError = true;
        _validationErrors = ['File is empty'];
      });
      return;
    }
    
    final errors = <String>[];
    final headers = _fileData!.first;
    
    // Check if it's a property or tenant upload
    if (_selectedUploadType == 'Properties') {
      // Property upload validation
      final requiredHeaders = [
        'name', 'address', 'city', 'state', 'zip_code', 'type', 'is_multi_unit'
      ];
      
      // Check headers
      for (final header in requiredHeaders) {
        if (!headers.contains(header)) {
          errors.add('Missing required column: $header');
        }
      }
      
      // Check data rows
      for (int i = 1; i < _fileData!.length; i++) {
        final row = _fileData![i];
        if (row.length != headers.length) {
          errors.add('Row $i has incorrect number of columns');
          continue;
        }
        
        final nameIndex = headers.indexOf('name');
        if (nameIndex >= 0 && (row[nameIndex] == null || row[nameIndex].toString().isEmpty)) {
          errors.add('Row $i: Property name is required');
        }
        
        final addressIndex = headers.indexOf('address');
        if (addressIndex >= 0 && (row[addressIndex] == null || row[addressIndex].toString().isEmpty)) {
          errors.add('Row $i: Property address is required');
        }
        
        // More validations as needed
      }
    } else {
      // Tenant upload validation
      final requiredHeaders = [
        'first_name', 'last_name', 'email', 'phone', 'property_id', 
        'unit_number', 'lease_start_date', 'lease_end_date', 
        'rent_amount', 'rent_due_day'
      ];
      
      // Check headers
      for (final header in requiredHeaders) {
        if (!headers.contains(header)) {
          errors.add('Missing required column: $header');
        }
      }
      
      // Check data rows
      for (int i = 1; i < _fileData!.length; i++) {
        final row = _fileData![i];
        if (row.length != headers.length) {
          errors.add('Row $i has incorrect number of columns');
          continue;
        }
        
        final firstNameIndex = headers.indexOf('first_name');
        if (firstNameIndex >= 0 && (row[firstNameIndex] == null || row[firstNameIndex].toString().isEmpty)) {
          errors.add('Row $i: First name is required');
        }
        
        final lastNameIndex = headers.indexOf('last_name');
        if (lastNameIndex >= 0 && (row[lastNameIndex] == null || row[lastNameIndex].toString().isEmpty)) {
          errors.add('Row $i: Last name is required');
        }
        
        final emailIndex = headers.indexOf('email');
        if (emailIndex >= 0 && (row[emailIndex] == null || row[emailIndex].toString().isEmpty)) {
          errors.add('Row $i: Email is required');
        }
        
        // More validations as needed
      }
    }
    
    setState(() {
      _validationError = errors.isNotEmpty;
      _validationErrors = errors;
      if (_validationError) {
        _statusMessage = 'Validation failed. Please correct the errors.';
      } else {
        _statusMessage = 'File validated successfully. Ready to upload.';
      }
    });
  }
  
  // Download template file
  Future<void> _downloadTemplate() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _selectedUploadType == 'Properties'
          ? 'property_template.xlsx'
          : 'tenant_template.xlsx';
          
      // Create Excel template
      final excel = Excel.createExcel();
      final sheet = excel.sheets.values.first;
      
      // Add headers
      if (_selectedUploadType == 'Properties') {
        sheet.appendRow([
           TextCellValue('name'),  TextCellValue('address'),  TextCellValue('city'),  TextCellValue('state'),  TextCellValue('zip_code'),  TextCellValue('type'), 
           TextCellValue('is_multi_unit'),  TextCellValue('description'),  TextCellValue('unit_number'),  TextCellValue('unit_type'),
           TextCellValue('bedrooms'),  TextCellValue('bathrooms'),  TextCellValue('monthly_rent'),  TextCellValue('security_deposit'),  TextCellValue('notes')
        ]);
        
        // Add sample data
        sheet.appendRow([
           TextCellValue('Sample Property'),  TextCellValue('123 Main St'),  TextCellValue('New York'),  TextCellValue('NY'),  TextCellValue('10001'),
           TextCellValue('Apartment'),  TextCellValue('TRUE'),  TextCellValue('Sample description'),  TextCellValue('Unit 1'),  TextCellValue('Standard'),
           TextCellValue('2'),  TextCellValue('1'),  TextCellValue('1500'),  TextCellValue('2000'),  TextCellValue('Sample notes')
        ]);
      } else {
        sheet.appendRow([
           TextCellValue('first_name'),  TextCellValue('last_name'),  TextCellValue('email'),  TextCellValue('phone'),  TextCellValue('property_id'),
           TextCellValue('unit_number'),  TextCellValue('lease_start_date'),  TextCellValue('lease_end_date'),
           TextCellValue('rent_amount'),  TextCellValue('rent_due_day'),  TextCellValue('security_deposit'),  TextCellValue('notes')
        ]);
        
        // Add sample data
        sheet.appendRow([
           TextCellValue('John'),  TextCellValue('Doe'),  TextCellValue('john.doe@example.com'),  TextCellValue('555-123-4567'),
           TextCellValue('property_id_here'),  TextCellValue('Unit 1'),  TextCellValue('2023-01-01'),  TextCellValue('2024-01-01'),
           TextCellValue('1500'),  TextCellValue('1'),  TextCellValue('2000'),  TextCellValue('Sample notes')
        ]);
      }
      
      // Save the file
      final file = File('${directory.path}/$fileName');
      final bytes = excel.encode();
      if (bytes != null) file.writeAsBytesSync(bytes);
      
      setState(() {
        _statusMessage = 'Template downloaded to: ${file.path}';
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template saved to: ${file.path}'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating template: $e';
        _validationError = true;
      });
    }
  }
  
  // Process the upload
  Future<void> _processUpload() async {
    if (_fileData == null || _fileData!.isEmpty || _validationError) {
      return;
    }
    
    setState(() {
      _isUploading = true;
      _statusMessage = 'Uploading...';
      _successCount = 0;
      _errorCount = 0;
    });
    
    try {
      final headers = _fileData!.first;
      
      if (_selectedUploadType == 'Properties') {
        await _uploadProperties(headers);
      } else {
        await _uploadTenants(headers);
      }
      
      setState(() {
        _isUploading = false;
        _statusMessage = 'Upload completed: $_successCount successful, $_errorCount failed';
        _validationError = _errorCount > 0;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusMessage = 'Error during upload: $e';
        _validationError = true;
      });
    }
  }
  
  // Upload properties
  Future<void> _uploadProperties(List<dynamic> headers) async {
    final nameIndex = headers.indexOf('name');
    final addressIndex = headers.indexOf('address');
    final cityIndex = headers.indexOf('city');
    final stateIndex = headers.indexOf('state');
    final zipCodeIndex = headers.indexOf('zip_code');
    final typeIndex = headers.indexOf('type');
    final isMultiUnitIndex = headers.indexOf('is_multi_unit');
    final descriptionIndex = headers.indexOf('description');
    
    // Unit related columns
    final unitNumberIndex = headers.indexOf('unit_number');
    final unitTypeIndex = headers.indexOf('unit_type');
    final bedroomsIndex = headers.indexOf('bedrooms');
    final bathroomsIndex = headers.indexOf('bathrooms');
    final monthlyRentIndex = headers.indexOf('monthly_rent');
    final securityDepositIndex = headers.indexOf('security_deposit');
    final notesIndex = headers.indexOf('notes');
    
    // Process each row (skip header)
    for (int i = 1; i < _fileData!.length; i++) {
      final row = _fileData![i];
      if (row.isEmpty || row.every((cell) => cell == null || cell.toString().isEmpty)) {
        continue; // Skip empty rows
      }
      
      try {
        // Extract property data
        final name = nameIndex >= 0 ? row[nameIndex].toString() : '';
        final address = addressIndex >= 0 ? row[addressIndex].toString() : '';
        final city = cityIndex >= 0 ? row[cityIndex].toString() : '';
        final state = stateIndex >= 0 ? row[stateIndex].toString() : '';
        final zipCode = zipCodeIndex >= 0 ? row[zipCodeIndex].toString() : '';
        final type = typeIndex >= 0 ? row[typeIndex].toString() : 'Single Family';
        
        // Convert "TRUE", "true", etc. to boolean
        bool isMultiUnit = false;
        if (isMultiUnitIndex >= 0) {
          final value = row[isMultiUnitIndex].toString().toLowerCase();
          isMultiUnit = value == 'true' || value == 'yes' || value == '1';
        }
        
        final description = descriptionIndex >= 0 ? row[descriptionIndex]?.toString() : null;
        
        // Create property unit
        final units = <PropertyUnitModel>[];
        final unitNumber = unitNumberIndex >= 0 ? row[unitNumberIndex]?.toString() ?? 'Main' : 'Main';
        final unitType = unitTypeIndex >= 0 ? row[unitTypeIndex]?.toString() ?? 'Standard' : 'Standard';
        
        // Parse numeric values
        int bedrooms = 1;
        if (bedroomsIndex >= 0 && row[bedroomsIndex] != null) {
          bedrooms = int.tryParse(row[bedroomsIndex].toString()) ?? 1;
        }
        
        double bathrooms = 1.0;
        if (bathroomsIndex >= 0 && row[bathroomsIndex] != null) {
          bathrooms = double.tryParse(row[bathroomsIndex].toString()) ?? 1.0;
        }
        
        double monthlyRent = 0.0;
        if (monthlyRentIndex >= 0 && row[monthlyRentIndex] != null) {
          monthlyRent = double.tryParse(row[monthlyRentIndex].toString()) ?? 0.0;
        }
        
        double? securityDeposit;
        if (securityDepositIndex >= 0 && row[securityDepositIndex] != null) {
          securityDeposit = double.tryParse(row[securityDepositIndex].toString());
        }
        
        final notes = notesIndex >= 0 ? row[notesIndex]?.toString() : null;
        
        units.add(PropertyUnitModel(
          unitNumber: unitNumber,
          unitType: unitType,
          bedrooms: bedrooms,
          bathrooms: bathrooms,
          monthlyRent: monthlyRent,
          securityDeposit: securityDeposit,
          notes: notes,
        ));
        
        // Add the property
        await _propertyController.addProperty(
          name: name,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          type: type,
          isMultiUnit: isMultiUnit,
          units: units,
          description: description,
        );
        
        setState(() {
          _successCount++;
        });
      } catch (e) {
        print('Error adding property from row $i: $e');
        setState(() {
          _errorCount++;
          _validationErrors.add('Row $i: ${e.toString()}');
        });
      }
    }
  }
  
  // Upload tenants
  Future<void> _uploadTenants(List<dynamic> headers) async {
    final firstNameIndex = headers.indexOf('first_name');
    final lastNameIndex = headers.indexOf('last_name');
    final emailIndex = headers.indexOf('email');
    final phoneIndex = headers.indexOf('phone');
    final propertyIdIndex = headers.indexOf('property_id');
    final unitNumberIndex = headers.indexOf('unit_number');
    final unitIdIndex = headers.indexOf('unit_id');
    final leaseStartDateIndex = headers.indexOf('lease_start_date');
    final leaseEndDateIndex = headers.indexOf('lease_end_date');
    final rentAmountIndex = headers.indexOf('rent_amount');
    final rentDueDayIndex = headers.indexOf('rent_due_day');
    final securityDepositIndex = headers.indexOf('security_deposit');
    final notesIndex = headers.indexOf('notes');
    
    // Process each row (skip header)
    for (int i = 1; i < _fileData!.length; i++) {
      final row = _fileData![i];
      if (row.isEmpty || row.every((cell) => cell == null || cell.toString().isEmpty)) {
        continue; // Skip empty rows
      }
      
      try {
        // Extract tenant data
        final firstName = firstNameIndex >= 0 ? row[firstNameIndex].toString() : '';
        final lastName = lastNameIndex >= 0 ? row[lastNameIndex].toString() : '';
        final email = emailIndex >= 0 ? row[emailIndex].toString() : '';
        final phone = phoneIndex >= 0 ? row[phoneIndex].toString() : '';
        final propertyId = propertyIdIndex >= 0 ? row[propertyIdIndex].toString() : '';
        final unitNumber = unitNumberIndex >= 0 ? row[unitNumberIndex].toString() : '';
        final unitId = unitIdIndex >= 0 ? row[unitIdIndex]?.toString() : null;
        
        // Parse lease dates
        DateTime leaseStartDate = DateTime.now();
        if (leaseStartDateIndex >= 0 && row[leaseStartDateIndex] != null) {
          try {
            leaseStartDate = DateTime.parse(row[leaseStartDateIndex].toString());
          } catch (_) {
            // Use default if parsing fails
          }
        }
        
        DateTime leaseEndDate = DateTime.now().add( Duration(days: 365));
        if (leaseEndDateIndex >= 0 && row[leaseEndDateIndex] != null) {
          try {
            leaseEndDate = DateTime.parse(row[leaseEndDateIndex].toString());
          } catch (_) {
            // Use default if parsing fails
          }
        }
        
        // Parse numeric values
        double rentAmount = 0.0;
        if (rentAmountIndex >= 0 && row[rentAmountIndex] != null) {
          rentAmount = double.tryParse(row[rentAmountIndex].toString()) ?? 0.0;
        }
        
        int rentDueDay = 1;
        if (rentDueDayIndex >= 0 && row[rentDueDayIndex] != null) {
          rentDueDay = int.tryParse(row[rentDueDayIndex].toString()) ?? 1;
          if (rentDueDay < 1) rentDueDay = 1;
          if (rentDueDay > 31) rentDueDay = 31;
        }
        
        double? securityDeposit;
        if (securityDepositIndex >= 0 && row[securityDepositIndex] != null) {
          securityDeposit = double.tryParse(row[securityDepositIndex].toString());
        }
        
        final notes = notesIndex >= 0 ? row[notesIndex]?.toString() : null;
        
        // Add the tenant
        await _tenantController.addTenant(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          propertyId: propertyId,
          unitNumber: unitNumber,
          unitId: unitId,
          leaseStartDate: leaseStartDate,
          leaseEndDate: leaseEndDate,
          rentAmount: rentAmount,
          rentDueDay: rentDueDay,
          securityDeposit: securityDeposit,
          notes: notes,
        );
        
        setState(() {
          _successCount++;
        });
      } catch (e) {
        print('Error adding tenant from row $i: $e');
        setState(() {
          _errorCount++;
          _validationErrors.add('Row $i: ${e.toString()}');
        });
      }
    }
  }
  
  // Generate DataTable columns for preview
  List<DataColumn> _getDataTableColumns() {
    if (_fileData == null || _fileData!.isEmpty) {
      return [];
    }
    
    final headers = _fileData!.first;
    return headers.map((header) => DataColumn(label: Text(header.toString()))).toList();
  }
  
  // Generate DataTable rows for preview
  List<DataRow> _getDataTableRows() {
    if (_fileData == null || _fileData!.length <= 1) {
      return [];
    }
    
    // Show up to 5 rows
    final rowsToShow = _fileData!.length > 6
        ? _fileData!.sublist(1, 6)
        : _fileData!.sublist(1);
        
    return rowsToShow.map((row) {
      return DataRow(
        cells: row.map((cell) => DataCell(Text(cell.toString()))).toList(),
      );
    }).toList();
  }
}