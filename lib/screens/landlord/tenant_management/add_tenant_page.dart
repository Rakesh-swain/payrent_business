import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/tenant_controller.dart';
import 'package:payrent_business/controllers/property_controller.dart';

class AddTenantPage extends StatefulWidget {
  final String? propertyId; // Optional property ID if coming from property details
  
  const AddTenantPage({super.key, this.propertyId});

  @override
  State<AddTenantPage> createState() => _AddTenantPageState();
}

class _AddTenantPageState extends State<AddTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final TenantController _tenantController = Get.find<TenantController>();
  final PropertyController _propertyController = Get.find<PropertyController>();
  
  // Mandatory fields - Required for Firebase consistency
  final _firstNameController = TextEditingController(); // firstName
  final _lastNameController = TextEditingController();  // lastName
  final _emailController = TextEditingController();     // email
  final _phoneController = TextEditingController();     // phone
  
  // Optional fields - Match bulk upload structure
  String? _selectedPropertyId;                          // propertyId
  String? _selectedUnitId;                              // unitId
  final _rentAmountController = TextEditingController(); // rentAmount
  String _selectedPaymentFrequency = 'monthly';         // paymentFrequency
  DateTime? _leaseStartDate;                            // leaseStartDate
  DateTime? _leaseEndDate;                              // leaseEndDate
  final _securityDepositController = TextEditingController(); // securityDeposit
  final _rentDueDayController = TextEditingController(); // rentDueDay
  final _notesController = TextEditingController();     // notes
  final _unitNumberController = TextEditingController(); // unitNumber
  
  bool _isLoading = false;
  bool _isSaving = false;
  List<DocumentSnapshot> _properties = [];
  List<Map<String, dynamic>> _availableUnits = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with property ID if provided
    if (widget.propertyId != null) {
      _selectedPropertyId = widget.propertyId;
    }
    
    // Set default values
    _rentDueDayController.text = '1'; // Default to 1st of month
    
    _fetchProperties();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rentAmountController.dispose();
    _securityDepositController.dispose();
    _rentDueDayController.dispose();
    _notesController.dispose();
    _unitNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchProperties() async {
    setState(() => _isLoading = true);
    
    try {
      await _propertyController.fetchProperties();
      await _tenantController.fetchTenants(); // Need tenants to check occupancy
      
      // Filter to only show properties with vacant units
      _properties = _getPropertiesWithVacantUnits();
      
      // If property ID is provided, load units for that property
      if (widget.propertyId != null && _properties.isNotEmpty) {
        final property = _properties.firstWhere(
          (p) => p.id == widget.propertyId,
          orElse: () => _properties.first,
        );
        
        if (property.exists) {
          await _loadAvailableUnits(widget.propertyId!);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load properties: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // Get properties that have at least one vacant unit
  List<DocumentSnapshot> _getPropertiesWithVacantUnits() {
    List<DocumentSnapshot> vacantProperties = [];
    
    for (final property in _propertyController.properties) {
      final data = property.data() as Map<String, dynamic>;
      final units = data['units'] ?? [];
      
      if (units is List && units.isNotEmpty) {
        // Check if any unit is vacant
        bool hasVacantUnit = false;
        for (final unit in units) {
          final unitData = unit as Map<String, dynamic>;
          final unitId = unitData['id'] ?? '';
          
          // Check if this unit is occupied
          final isOccupied = _tenantController.tenants.any((tenant) {
            final tenantData = tenant.data() as Map<String, dynamic>;
            return tenantData['propertyId'] == property.id && 
                   (tenantData['unitId'] == unitId || tenantData['unitNumber'] == unitData['number']);
          });
          
          if (!isOccupied) {
            hasVacantUnit = true;
            break;
          }
        }
        
        if (hasVacantUnit) {
          vacantProperties.add(property);
        }
      } else {
        // If no units defined, consider the entire property as one unit
        final isOccupied = _tenantController.tenants.any((tenant) {
          final tenantData = tenant.data() as Map<String, dynamic>;
          return tenantData['propertyId'] == property.id;
        });
        
        if (!isOccupied) {
          vacantProperties.add(property);
        }
      }
    }
    
    return vacantProperties;
  }
  
  // Load available (vacant) units for a selected property
  Future<void> _loadAvailableUnits(String propertyId) async {
    final property = _properties.firstWhere((p) => p.id == propertyId);
    final data = property.data() as Map<String, dynamic>;
    final units = data['units'] ?? [];
    
    _availableUnits.clear();
    
    if (units is List && units.isNotEmpty) {
      for (final unit in units) {
        final unitData = unit as Map<String, dynamic>;
        final unitId = unitData['id'] ?? '';
        final unitNumber = unitData['number'] ?? '';
        
        // Check if this unit is occupied
        final isOccupied = _tenantController.tenants.any((tenant) {
          final tenantData = tenant.data() as Map<String, dynamic>;
          return tenantData['propertyId'] == propertyId && 
                 (tenantData['unitId'] == unitId || tenantData['unitNumber'] == unitNumber);
        });
        
        if (!isOccupied) {
          _availableUnits.add({
            'id': unitId,
            'number': unitNumber,
            'rent': unitData['rent'] ?? 0,
            'type': unitData['type'] ?? 'Unit',
          });
        }
      }
    } else {
      // If no units defined, add the whole property as one unit
      _availableUnits.add({
        'id': 'main',
        'number': 'Main Unit',
        'rent': data['rent'] ?? 0,
        'type': 'Property',
      });
    }
    
    // Reset unit selection when property changes
    _selectedUnitId = null;
    
    setState(() {});
  }
  
  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Get unit info if selected
      String unitNumber = '';
      if (_selectedUnitId != null && _availableUnits.isNotEmpty) {
        final selectedUnit = _availableUnits.firstWhere(
          (unit) => unit['id'] == _selectedUnitId,
          orElse: () => {},
        );
        unitNumber = selectedUnit['number'] ?? '';
        
        // Set rent amount from unit if not manually entered
        if (_rentAmountController.text.isEmpty && selectedUnit['rent'] != null) {
          _rentAmountController.text = selectedUnit['rent'].toString();
        }
      }
      
      final tenantId = await _tenantController.addTenant(
        // Mandatory fields
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        
        // Optional fields
        propertyId: _selectedPropertyId,
        unitId: _selectedUnitId,
        unitNumber: unitNumber,
        leaseStartDate: _leaseStartDate,
        leaseEndDate: _leaseEndDate,
        rentAmount: int.tryParse(_rentAmountController.text),
        paymentFrequency: _selectedPaymentFrequency,
        rentDueDay: int.tryParse(_rentDueDayController.text),
        securityDeposit: int.tryParse(_securityDepositController.text),
        notes: _notesController.text.trim(),
      );
      
      if (tenantId != null) {
        Get.back();
        Get.snackbar('Success', 'Tenant added successfully');
      } else {
        Get.snackbar('Error', _tenantController.errorMessage.value);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add tenant: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Add Tenant', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Add Tenant', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveTenant,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mandatory Information
              _buildSection(
                'Personal Information *',
                Icons.person_outline,
                [
                  Text(
                    'Required fields to create a tenant',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name *',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name *',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address *',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!GetUtils.isEmail(value.trim())) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number *',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Optional Property Information
              _buildSection(
                'Property Information',
                Icons.home_outlined,
                [
                  Text(
                    'Optional: Assign to a vacant property and unit',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPropertyDropdown(),
                  if (_selectedPropertyId != null && _availableUnits.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildUnitDropdown(),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Optional Lease Information
              _buildSection(
                'Lease Information',
                Icons.description_outlined,
                [
                  Text(
                    'Optional: Set lease terms (can be updated later)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDateField('Lease Start Date', _leaseStartDate, (date) => _leaseStartDate = date)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDateField('Lease End Date', _leaseEndDate, (date) => _leaseEndDate = date)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _rentAmountController,
                          label: 'Rent Amount',
                          keyboardType: TextInputType.number,
                          prefixText: '\$',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPaymentFrequencyDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _rentDueDayController,
                          label: 'Rent Due Day',
                          keyboardType: TextInputType.number,
                          suffixText: 'of month',
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final day = int.tryParse(value);
                              if (day == null || day < 1 || day > 31) {
                                return 'Enter a valid day (1-31)';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _securityDepositController,
                          label: 'Security Deposit',
                          keyboardType: TextInputType.number,
                          prefixText: '\$',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Optional Additional Information
              _buildSection(
                'Additional Information',
                Icons.note_outlined,
                [
                  Text(
                    'Optional: Add any notes about the tenant',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notes',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Add Button
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTenant,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppTheme.primaryGradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Add Tenant',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Only properties with vacant units are shown. Select a property to see available units.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? prefixText,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: keyboardType == TextInputType.name 
          ? TextCapitalization.words 
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        suffixText: suffixText,
      ),
      style: GoogleFonts.poppins(fontSize: 14),
    );
  }

  Widget _buildPropertyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPropertyId,
      decoration: InputDecoration(
        labelText: 'Select Property (Only Vacant)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Select Property (Optional)'),
        ),
        ..._properties.map((property) {
          final data = property.data() as Map<String, dynamic>;
          final units = data['units'] ?? [];
          final vacantCount = _getVacantUnitCount(property.id);
          
          return DropdownMenuItem<String>(
            value: property.id,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Unknown Property',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$vacantCount vacant unit${vacantCount != 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.successColor),
                ),
              ],
            ),
          );
        }).toList(),
      ],
      onChanged: (value) async {
        setState(() => _selectedPropertyId = value);
        if (value != null) {
          await _loadAvailableUnits(value);
        } else {
          setState(() {
            _availableUnits.clear();
            _selectedUnitId = null;
          });
        }
      },
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUnitId,
      decoration: InputDecoration(
        labelText: 'Select Unit',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Select Unit (Optional)'),
        ),
        ..._availableUnits.map((unit) {
          return DropdownMenuItem<String>(
            value: unit['id'],
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit['number'] ?? 'Unknown Unit',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Rent: \$${unit['rent']} • ${unit['type']}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'VACANT',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() => _selectedUnitId = value);
        
        // Auto-fill rent amount from selected unit
        if (value != null) {
          final selectedUnit = _availableUnits.firstWhere(
            (unit) => unit['id'] == value,
            orElse: () => {},
          );
          if (selectedUnit['rent'] != null && _rentAmountController.text.isEmpty) {
            _rentAmountController.text = selectedUnit['rent'].toString();
          }
        }
      },
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
    );
  }

  int _getVacantUnitCount(String propertyId) {
    final property = _propertyController.properties.firstWhere((p) => p.id == propertyId);
    final data = property.data() as Map<String, dynamic>;
    final units = data['units'] ?? [];
    
    if (units is List && units.isNotEmpty) {
      int vacantCount = 0;
      for (final unit in units) {
        final unitData = unit as Map<String, dynamic>;
        final unitId = unitData['id'] ?? '';
        
        final isOccupied = _tenantController.tenants.any((tenant) {
          final tenantData = tenant.data() as Map<String, dynamic>;
          return tenantData['propertyId'] == propertyId && 
                 (tenantData['unitId'] == unitId || tenantData['unitNumber'] == unitData['number']);
        });
        
        if (!isOccupied) vacantCount++;
      }
      return vacantCount;
    } else {
      // Single unit property
      final isOccupied = _tenantController.tenants.any((tenant) {
        final tenantData = tenant.data() as Map<String, dynamic>;
        return tenantData['propertyId'] == propertyId;
      });
      return isOccupied ? 0 : 1;
    }
  }

  Widget _buildPaymentFrequencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentFrequency,
      decoration: InputDecoration(
        labelText: 'Payment Frequency',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: ['weekly', 'monthly', 'quarterly', 'yearly'].map((frequency) {
        return DropdownMenuItem<String>(
          value: frequency,
          child: Text(
            frequency[0].toUpperCase() + frequency.substring(1),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedPaymentFrequency = value!);
      },
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppTheme.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (selectedDate != null) {
          onChanged(selectedDate);
          setState(() {});
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          hintText: 'Select date',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          date != null
              ? DateFormat('dd/MM/yyyy').format(date)
              : 'Select date',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: date != null
                ? AppTheme.textPrimary
                : AppTheme.textLight,
          ),
        ),
      ),
    );
  }
}