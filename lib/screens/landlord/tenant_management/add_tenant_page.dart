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
  
  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rentAmountController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _rentDueDayController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Form Data
  String? _selectedPropertyId;
  String? _selectedUnitId;
  String _selectedPaymentFrequency = 'monthly';
  DateTime? _leaseStartDate;
  DateTime? _leaseEndDate;
  
  // State Management
  bool _isLoading = false;
  bool _isSaving = false;
  List<DocumentSnapshot> _properties = [];
  List<Map<String, dynamic>> _availableUnits = [];
  
  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }
  
  Future<void> _fetchProperties() async {
    setState(() => _isLoading = true);
    
    try {
      await _propertyController.fetchProperties();
      await _tenantController.fetchTenants();
      
      // Filter to only show properties with vacant units
      _properties = _getPropertiesWithVacantUnits();
      
      // Auto-load units if propertyId is provided
      if (widget.propertyId != null) {
        _selectedPropertyId = widget.propertyId;
        await _loadAvailableUnits(widget.propertyId!);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load properties: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  List<DocumentSnapshot> _getPropertiesWithVacantUnits() {
    List<DocumentSnapshot> vacantProperties = [];
    
    for (final property in _propertyController.properties) {
      final data = property.data() as Map<String, dynamic>;
      final units = data['units'] ?? [];
      
      if (units is List && units.isNotEmpty) {
        // Multi-unit property - check if any unit is vacant
        bool hasVacantUnit = false;
        for (final unit in units) {
          final unitData = unit as Map<String, dynamic>;
          final unitId = unitData['id'] ?? '';
          
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
        // Single-unit property - check if property is vacant
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
  
  Future<void> _loadAvailableUnits(String propertyId) async {
    final property = _properties.firstWhere((p) => p.id == propertyId);
    final data = property.data() as Map<String, dynamic>;
    final units = data['units'] ?? [];
    
    _availableUnits.clear();
    
    if (units is List && units.isNotEmpty) {
      // Multi-unit property
      for (final unit in units) {
        final unitData = unit as Map<String, dynamic>;
        final unitId = unitData['id'] ?? '';
        final unitNumber = unitData['number'] ?? '';
        
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
            'bedrooms': unitData['bedrooms'] ?? 1,
            'bathrooms': unitData['bathrooms'] ?? 1,
          });
        }
      }
    } else {
      // Single-unit property (whole property as one unit)
      _availableUnits.add({
        'id': 'main',
        'number': 'Main Unit',
        'rent': data['rent'] ?? 0,
        'type': 'Property',
        'bedrooms': data['bedrooms'] ?? 1,
        'bathrooms': data['bathrooms'] ?? 1,
      });
    }
    
    // Reset unit selection when property changes
    _selectedUnitId = null;
    _rentAmountController.clear();
    
    setState(() {});
  }
  
  void _onUnitSelected(String? unitId) {
    setState(() => _selectedUnitId = unitId);
    
    if (unitId != null) {
      // Find the selected unit and auto-fill rent amount
      final selectedUnit = _availableUnits.firstWhere(
        (unit) => unit['id'] == unitId,
        orElse: () => {},
      );
      
      if (selectedUnit.isNotEmpty && selectedUnit['rent'] != null) {
        _rentAmountController.text = selectedUnit['rent'].toString();
      }
    } else {
      // Clear rent when no unit is selected
      _rentAmountController.clear();
    }
  }
  
  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      String unitNumber = '';
      if (_selectedUnitId != null && _availableUnits.isNotEmpty) {
        final selectedUnit = _availableUnits.firstWhere(
          (unit) => unit['id'] == _selectedUnitId,
          orElse: () => {},
        );
        unitNumber = selectedUnit['number'] ?? '';
      }
      
      final tenantId = await _tenantController.addTenant(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
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
        Get.snackbar('Success', 'Tenant added successfully', backgroundColor: AppTheme.successColor);
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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSection(
                'Personal Information *',
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
                        child: TextFormField(
                          controller: _firstNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'First Name *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
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
                        child: TextFormField(
                          controller: _lastNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Last Name *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
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
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
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
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
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

              // Property Assignment Section
              _buildSection(
                'Property Assignment',
                [
                  Text(
                    'Optional: Assign to a vacant property and unit',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Property Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedPropertyId,
                    decoration: const InputDecoration(
                      labelText: 'Select Property',
                      prefixIcon: Icon(Icons.home_outlined),
                      hintText: 'Choose a property',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No Property Selected'),
                      ),
                      ..._properties.map((property) {
                        final data = property.data() as Map<String, dynamic>;
                        final vacantCount = _getVacantUnitCount(property.id);
                        
                        return DropdownMenuItem<String>(
                          value: property.id,
                          child: Text(
                            data['name'] ?? 'Unknown Property',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                          _rentAmountController.clear();
                        });
                      }
                    },
                  ),
                  
                  // Unit Dropdown (appears only when property is selected)
                  if (_selectedPropertyId != null && _availableUnits.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedUnitId,
                      decoration: const InputDecoration(
                        labelText: 'Select Unit',
                        prefixIcon: Icon(Icons.door_front_door_outlined),
                        hintText: 'Choose a unit',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Unit Selected'),
                        ),
                        ..._availableUnits.map((unit) {
                          return DropdownMenuItem<String>(
                            value: unit['id'],
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          unit['number'] ?? 'Unknown Unit',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Rent: \$${unit['rent']} • ${unit['bedrooms']}BR/${unit['bathrooms']}BA',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
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
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: _onUnitSelected,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Lease Information Section
              _buildSection(
                'Lease Information',
                [
                  Text(
                    'Optional: Set lease terms and rent details',
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
                        child: TextFormField(
                          controller: _rentAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _selectedUnitId != null ? 'Rent Amount (Auto-filled)' : 'Rent Amount',
                            prefixIcon: const Icon(Icons.attach_money),
                            prefixText: '\$',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPaymentFrequency,
                          decoration: const InputDecoration(
                            labelText: 'Payment Frequency',
                            prefixIcon: Icon(Icons.schedule_outlined),
                          ),
                          items: ['weekly', 'monthly', 'quarterly', 'yearly'].map((frequency) {
                            return DropdownMenuItem<String>(
                              value: frequency,
                              child: Text(frequency[0].toUpperCase() + frequency.substring(1)),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedPaymentFrequency = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rentDueDayController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Rent Due Day',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            suffixText: 'of month',
                          ),
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
                        child: TextFormField(
                          controller: _securityDepositController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Security Deposit',
                            prefixIcon: Icon(Icons.security_outlined),
                            prefixText: '\$',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Additional Information Section
              _buildSection(
                'Additional Information',
                [
                  Text(
                    'Optional: Add any notes about the tenant',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.note_outlined),
                      hintText: 'Any additional notes about the tenant...',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit Button
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

              // Info Note
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

  Widget _buildSection(String title, List<Widget> children) {
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
}