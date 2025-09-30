import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/tenant_controller.dart';
import 'package:payrent_business/models/account_information_model.dart';
import 'package:payrent_business/services/branch_service.dart';

class EditTenantPage extends StatefulWidget {
  final String tenantId;

  const EditTenantPage({super.key, required this.tenantId});

  @override
  State<EditTenantPage> createState() => _EditTenantPageState();
}

class _EditTenantPageState extends State<EditTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final TenantController _tenantController = Get.find<TenantController>();

  // Personal info controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Account info controllers
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _idNumberController = TextEditingController();

  // Account info state
  IdType _selectedIdType = IdType.civilId;
  String _selectedBankBic = '';
  String _selectedBranchCode = '';
  List<String> _availableBankBics = [];
  List<BranchInfo> _availableBranches = [];

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  DocumentSnapshot? _tenantDoc;

  @override
  void initState() {
    super.initState();
    _availableBankBics = BranchService.getAllBankBics();
    _fetchData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      _tenantDoc = await _tenantController.getTenantById(widget.tenantId);
      if (_tenantDoc == null || !_tenantDoc!.exists) {
        throw Exception('Tenant not found');
      }
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

    // Personal
    _firstNameController.text = data['firstName'] ?? '';
    _lastNameController.text = data['lastName'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';

    // Account
    _accountHolderNameController.text = data['db_account_holder_name'] ?? '';
    _accountNumberController.text = data['db_account_number'] ?? '';
    _idNumberController.text = data['db_id_number'] ?? '';

    final idTypeStr = data['db_id_type'] as String?;
    if (idTypeStr != null && idTypeStr.isNotEmpty) {
      try {
        _selectedIdType = IdType.fromString(idTypeStr);
      } catch (_) {
        _selectedIdType = IdType.civilId;
      }
    }

    _selectedBankBic = data['db_bank_bic'] ?? '';
    _selectedBranchCode = data['db_branch_code'] ?? '';

    if (_selectedBankBic.isNotEmpty) {
      _availableBranches = BranchService.getBranchesForBank(_selectedBankBic);
      // Ensure selected branch exists in available list
      final exists = _availableBranches.any((b) => b.branchCode == _selectedBranchCode);
      if (!exists) _selectedBranchCode = '';
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
        accountHolderName: _accountHolderNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        idType: _selectedIdType.value,
        idNumber: _idNumberController.text.trim(),
        bankBic: _selectedBankBic,
        branchCode: _selectedBranchCode,
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
                      if (value.trim().length < 7) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account Information
              _buildSection(
                'Account Information',
                Icons.account_balance_outlined,
                [
                  _buildTextField(
                    controller: _accountHolderNameController,
                    label: 'Account Holder Name *',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Account holder name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _accountNumberController,
                    label: 'Account Number *',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Account number is required';
                      }
                      if (!RegExp(r'^\\d{6,}\$').hasMatch(value.trim())) {
                        return 'Enter a valid account number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildIdTypeDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _idNumberController,
                    label: 'ID Number *',
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
                  _buildBankDropdown(),
                  const SizedBox(height: 16),
                  _buildBranchDropdown(),

                  if (_selectedBranchCode.isNotEmpty && _selectedBankBic.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSelectedBranchInfo(),
                  ],
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

  Widget _buildIdTypeDropdown() {
    return DropdownButtonFormField<IdType>(
      value: _selectedIdType,
      decoration: InputDecoration(
        labelText: 'ID Type *',
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
      items: IdType.values.map((IdType type) {
        return DropdownMenuItem<IdType>(
          value: type,
          child: Text(type.displayName, style: GoogleFonts.poppins(fontSize: 14)),
        );
      }).toList(),
      onChanged: (IdType? newValue) {
        if (newValue != null) {
          setState(() => _selectedIdType = newValue);
        }
      },
      validator: (value) => value == null ? 'Select ID Type' : null,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
    );
  }

  Widget _buildBankDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBankBic.isEmpty ? null : _selectedBankBic,
      decoration: InputDecoration(
        labelText: 'Bank *',
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
          child: Text('Select a bank'),
        ),
        ..._availableBankBics.map((String bankBic) {
          return DropdownMenuItem<String>(
            value: bankBic,
            child: Text(bankBic, style: GoogleFonts.poppins(fontSize: 14)),
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
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
    );
  }

  Widget _buildBranchDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBranchCode.isEmpty ? null : _selectedBranchCode,
      decoration: InputDecoration(
        labelText: 'Branch *',
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
          child: Text('Select a branch'),
        ),
        ..._availableBranches.map((BranchInfo branch) {
          return DropdownMenuItem<String>(
            value: branch.branchCode,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(branch.branchName, style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(width: 8),
                Text('(${branch.branchCode})', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
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
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
    );
  }

  Widget _buildSelectedBranchInfo() {
    final branchInfo = BranchService.getBranchInfo(_selectedBankBic, _selectedBranchCode);
    if (branchInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected Branch', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
          const SizedBox(height: 6),
          Text(branchInfo.branchName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(branchInfo.branchCode, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(branchInfo.branchDescription, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
