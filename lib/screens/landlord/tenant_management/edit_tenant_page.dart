import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/tenant_controller.dart';
import 'package:payrent_business/controllers/property_controller.dart';
import 'package:payrent_business/models/tenant_model.dart';
import 'package:intl/intl.dart';

class EditTenantPage extends StatefulWidget {
  final String tenantId;

  const EditTenantPage({super.key, required this.tenantId});

  @override
  State<EditTenantPage> createState() => _EditTenantPageState();
}

class _EditTenantPageState extends State<EditTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final TenantController _tenantController = Get.find<TenantController>();
  final PropertyController _propertyController = Get.find<PropertyController>();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rentAmountController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _rentDueDayController = TextEditingController();
  final _notesController = TextEditingController();
  final _unitNumberController = TextEditingController();

  // Form state
  String? _selectedPropertyId;
  String _selectedPaymentFrequency = 'monthly';
  DateTime? _leaseStartDate;
  DateTime? _leaseEndDate;
  String _selectedStatus = 'active';

  bool _isLoading = true;
  bool _isSaving = false;
  List<DocumentSnapshot> _properties = [];
  DocumentSnapshot? _tenantDoc;

  @override
  void initState() {
    super.initState();
    _fetchData();
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

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch tenant data
      _tenantDoc = await _tenantController.getTenantById(widget.tenantId);
      
      if (_tenantDoc == null || !_tenantDoc!.exists) {
        throw Exception('Tenant not found');
      }

      // Fetch properties
      await _propertyController.fetchProperties();
      _properties = _propertyController.properties;

      _populateForm();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load tenant data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateForm() {
    if (_tenantDoc == null) return;

    final data = _tenantDoc!.data() as Map<String, dynamic>;

    _firstNameController.text = data['firstName'] ?? '';
    _lastNameController.text = data['lastName'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _rentAmountController.text = (data['rentAmount'] ?? 0).toString();
    _securityDepositController.text = (data['securityDeposit'] ?? 0).toString();
    _rentDueDayController.text = (data['rentDueDay'] ?? 1).toString();
    _notesController.text = data['notes'] ?? '';
    _unitNumberController.text = data['unitNumber'] ?? '';

    _selectedPropertyId = data['propertyId'];
    _selectedPaymentFrequency = data['paymentFrequency'] ?? 'monthly';
    _selectedStatus = data['status'] ?? 'active';

    if (data['leaseStartDate'] != null) {
      _leaseStartDate = (data['leaseStartDate'] as Timestamp).toDate();
    }
    if (data['leaseEndDate'] != null) {
      _leaseEndDate = (data['leaseEndDate'] as Timestamp).toDate();
    }
  }

  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final success = await _tenantController.updateTenant(
        tenantId: widget.tenantId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        propertyId: _selectedPropertyId,
        unitNumber: _unitNumberController.text.trim(),
        leaseStartDate: _leaseStartDate,
        leaseEndDate: _leaseEndDate,
        rentAmount: int.tryParse(_rentAmountController.text),
        paymentFrequency: _selectedPaymentFrequency,
        rentDueDay: int.tryParse(_rentDueDayController.text),
        securityDeposit: int.tryParse(_securityDepositController.text),
        notes: _notesController.text.trim(),
        status: _selectedStatus,
      );

      if (success) {
        Get.back();
        Get.snackbar('Success', 'Tenant updated successfully');
      } else {
        Get.snackbar('Error', _tenantController.errorMessage.value);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update tenant: $e');
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
          title: Text('Edit Tenant', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Edit Tenant', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500)),
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
              // Personal Information
              _buildSection(
                'Personal Information',
                Icons.person_outline,
                [
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
                    label: 'Email *',
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
                    label: 'Phone *',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildStatusDropdown(),
                ],
              ),

              const SizedBox(height: 24),

              // Property Information
              _buildSection(
                'Property Information',
                Icons.home_outlined,
                [
                  _buildPropertyDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _unitNumberController,
                    label: 'Unit Number',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Lease Information
              _buildSection(
                'Lease Information',
                Icons.description_outlined,
                [
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

              // Additional Information
              _buildSection(
                'Additional Information',
                Icons.note_outlined,
                [
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notes',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTenant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Update Tenant',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
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
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
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
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        suffixText: suffixText,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
    );
  }

  Widget _buildPropertyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPropertyId,
      decoration: InputDecoration(
        labelText: 'Property',
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
          child: Text('Select Property'),
        ),
        ..._properties.map((property) {
          final data = property.data() as Map<String, dynamic>;
          return DropdownMenuItem<String>(
            value: property.id,
            child: Text(
              data['name'] ?? 'Unknown Property',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() => _selectedPropertyId = value);
      },
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
    );
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

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
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
      items: ['active', 'inactive'].map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(
            status[0].toUpperCase() + status.substring(1),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedStatus = value!);
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
                  onSurface: Colors.black,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('MMM dd, yyyy').format(date)
                        : 'Select date',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: date != null ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}