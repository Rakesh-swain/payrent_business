import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/tenant_controller.dart';
import 'package:payrent_business/models/account_information_model.dart';
import 'package:payrent_business/services/branch_service.dart';

class AddTenantPage extends StatefulWidget {
  final String? propertyId; // Retained for potential future use
  
  const AddTenantPage({super.key, this.propertyId});

  @override
  State<AddTenantPage> createState() => _AddTenantPageState();
}

class _AddTenantPageState extends State<AddTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final TenantController _tenantController = Get.find<TenantController>();
  
  // Personal Information Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Account Information Controllers
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _idNumberController = TextEditingController();

  // Additional Information
  final _notesController = TextEditingController();
  
  // Account Information Variables
  IdType _selectedIdType = IdType.civilId;
  String _selectedBankBic = '';
  String _selectedBranchCode = '';
  List<String> _availableBankBics = [];
  List<BranchInfo> _availableBranches = [];
  
  // State Management
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _availableBankBics = BranchService.getAllBankBics();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final tenantId = await _tenantController.addTenant(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        // Only personal and account information; property/lease details omitted
        notes: _notesController.text.trim(),
        accountHolderName: _accountHolderNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        idType: _selectedIdType.value,
        idNumber: _idNumberController.text.trim(),
        bankBic: _selectedBankBic,
        branchCode: _selectedBranchCode,
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
                    'All fields in this section are mandatory',
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
                     inputFormatters: [LengthLimitingTextInputFormatter(10)],
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      if (value.trim().length < 7) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account Information Section
              _buildSection(
                'Account Information *',
                [
                  Text(
                    'All fields in this section are mandatory',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Account Holder Name Field
                  TextFormField(
                    controller: _accountHolderNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name *',
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Enter the full name as on bank account',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Account holder name is required';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Account Number Field
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Account Number *',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                      hintText: 'Enter bank account number',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Account number is required';
                      }
                      final trimmed = value.trim();
                      if (!RegExp(r'^\d{6,}$').hasMatch(trimmed)) {
                        return 'Enter a valid account number';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ID Type Dropdown
                  DropdownButtonFormField<IdType>(
                    value: _selectedIdType,
                    decoration: const InputDecoration(
                      labelText: 'ID Type *',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    items: IdType.values.map((IdType type) {
                      return DropdownMenuItem<IdType>(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (IdType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedIdType = newValue;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ID Number Field
                  TextFormField(
                    controller: _idNumberController,
                    decoration: const InputDecoration(
                      labelText: 'ID Number *',
                      prefixIcon: Icon(Icons.badge_outlined),
                      hintText: 'Enter identification number',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ID number is required';
                      }
                      if (value.trim().length < 4) {
                        return 'Enter a valid ID number';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bank BIC Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedBankBic.isEmpty ? null : _selectedBankBic,
                    decoration: const InputDecoration(
                      labelText: 'Bank *',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                      hintText: 'Select bank',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select a bank'),
                      ),
                      ..._availableBankBics.map((String bankBic) {
                        return DropdownMenuItem<String>(
                          value: bankBic,
                          child: Text(bankBic),
                        );
                      }).toList(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a bank';
                      }
                      return null;
                    },
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBankBic = newValue ?? '';
                        _selectedBranchCode = '';
                        if (newValue != null && newValue.isNotEmpty) {
                          _availableBranches = BranchService.getBranchesForBank(newValue);
                        } else {
                          _availableBranches.clear();
                        }
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Branch Code Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedBranchCode.isEmpty ? null : _selectedBranchCode,
                    decoration: InputDecoration(
                      labelText: 'Branch *',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      hintText: _selectedBankBic.isEmpty ? 'Please select a bank first' : 'Select branch',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select a branch'),
                      ),
                      ..._availableBranches.map((BranchInfo branch) {
                        return DropdownMenuItem<String>(
                          value: branch.branchCode,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                branch.branchName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Code: ${branch.branchCode}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a branch';
                      }
                      return null;
                    },
                    onChanged: _selectedBankBic.isEmpty 
                        ? null 
                        : (String? newValue) {
                            setState(() {
                              _selectedBranchCode = newValue ?? '';
                            });
                          },
                  ),
                  
                  // Selected Branch Information Display
                  if (_selectedBranchCode.isNotEmpty && _selectedBankBic.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: () {
                        final branchInfo = BranchService.getBranchInfo(_selectedBankBic, _selectedBranchCode);
                        if (branchInfo != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Branch',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                branchInfo.branchName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                branchInfo.branchCode,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                branchInfo.branchDescription,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }(),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Additional Information Section (Optional)
              _buildSection(
                'Additional Information (Optional)',
                [
                  Text(
                    'This section is optional',
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
                        'Only personal and account information are required. Additional information is optional.',
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
}
