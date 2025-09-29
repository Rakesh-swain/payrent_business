import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../controllers/account_information_controller.dart';
import '../../models/account_information_model.dart';
import '../../widgets/appbar.dart';

class AccountInformationPage extends StatefulWidget {
  final bool isEditing;

  const AccountInformationPage({super.key, this.isEditing = false});

  @override
  State<AccountInformationPage> createState() => _AccountInformationPageState();
}

class _AccountInformationPageState extends State<AccountInformationPage> {
  late final AccountInformationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AccountInformationController());
    
    // Load existing data if editing
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadAccountInformation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: appBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'Account Information',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333333),
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 700),
                      child: Text(
                        'Please provide your banking details for payment processing',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B737A),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Account Holder Name Field
                  FadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    child: _buildTextFormField(
                      controller: controller.accountHolderNameController,
                      label: 'Account Holder Name',
                      hint: 'Enter the full name as on bank account',
                      icon: Icons.person_outline_rounded,
                      fieldKey: 'accountHolderName',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Account Number Field
                  FadeInRight(
                    duration: const Duration(milliseconds: 900),
                    child: _buildTextFormField(
                      controller: controller.accountNumberController,
                      label: 'Account Number',
                      hint: 'Enter your bank account number',
                      icon: Icons.account_balance_outlined,
                      fieldKey: 'accountNumber',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ID Type Dropdown
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1000),
                    child: _buildIdTypeDropdown(),
                  ),

                  const SizedBox(height: 20),

                  // ID Number Field
                  FadeInRight(
                    duration: const Duration(milliseconds: 1100),
                    child: _buildTextFormField(
                      controller: controller.idNumberController,
                      label: 'ID Number',
                      hint: 'Enter your identification number',
                      icon: Icons.badge_outlined,
                      fieldKey: 'idNumber',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bank BIC Dropdown
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1200),
                    child: _buildBankBicDropdown(),
                  ),

                  const SizedBox(height: 20),

                  // Branch Code Dropdown
                  FadeInRight(
                    duration: const Duration(milliseconds: 1300),
                    child: _buildBranchCodeDropdown(),
                  ),

                  const SizedBox(height: 20),

                  // Selected Branch Information Display
                  Obx(() {
                    final branchInfo = controller.selectedBranchInfo.value;
                    if (branchInfo != null) {
                      return FadeInUp(
                        duration: const Duration(milliseconds: 1400),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4F287D).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Branch',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4F287D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                branchInfo.branchName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                branchInfo.branchDescription,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B737A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 32),

                  // Error message
                  Obx(() {
                    final errorMessage = controller.errorMessage.value;
                    if (errorMessage.isNotEmpty && controller.formSubmitted.value) {
                      return FadeIn(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // Save Button
                  FadeInUp(
                    duration: const Duration(milliseconds: 1500),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () async {
                                await controller.saveAccountInformation();
                              },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF4F287D).withOpacity(0.4),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7869E6), Color(0xFF4F287D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            alignment: Alignment.center,
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.isEditing ? 'Update' : 'Save',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.save_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String fieldKey,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF333333),
          ),
          decoration: _buildInputDecoration(
            label,
            hint: hint,
            hasError: this.controller.hasError(fieldKey),
          ).copyWith(
            prefixIcon: Icon(
              icon,
              color: this.controller.hasError(fieldKey)
                  ? Colors.red
                  : const Color(0xFF6B737A),
            ),
          ),
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: TextInputAction.next,
        )),
        Obx(() {
          if (this.controller.hasError(fieldKey)) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, top: 6),
              child: Text(
                'This field is required',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.red,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildIdTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID Type *',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
            ),
          ),
          child: DropdownButtonFormField<IdType>(
            value: controller.selectedIdType.value,
            onChanged: controller.onIdTypeChanged,
            decoration: _buildInputDecoration(
              '',
              hasError: false,
            ).copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: const Icon(
                Icons.credit_card_outlined,
                color: Color(0xFF6B737A),
              ),
            ),
            items: IdType.values.map((IdType type) {
              return DropdownMenuItem<IdType>(
                value: type,
                child: Text(
                  type.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                ),
              );
            }).toList(),
          ),
        )),
      ],
    );
  }

  Widget _buildBankBicDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bank *',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: controller.hasError('bankBic') ? Colors.red : const Color(0xFFE0E0E0),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: controller.selectedBankBic.value.isEmpty ? null : controller.selectedBankBic.value,
            onChanged: controller.onBankBicChanged,
            decoration: _buildInputDecoration(
              '',
              hasError: controller.hasError('bankBic'),
            ).copyWith(
              hintText: 'Select your bank',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Icon(
                Icons.account_balance_outlined,
                color: controller.hasError('bankBic') ? Colors.red : const Color(0xFF6B737A),
              ),
            ),
            items: controller.availableBankBics.map((String bankBic) {
              return DropdownMenuItem<String>(
                value: bankBic,
                child: Text(
                  '${controller.getBankDisplayName(bankBic)} ($bankBic)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                ),
              );
            }).toList(),
          ),
        )),
        Obx(() {
          if (controller.hasError('bankBic')) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, top: 6),
              child: Text(
                'Please select a bank',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.red,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildBranchCodeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Branch *',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: controller.hasError('branchCode') ? Colors.red : const Color(0xFFE0E0E0),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: controller.selectedBranchCode.value.isEmpty ? null : controller.selectedBranchCode.value,
            onChanged: controller.selectedBankBic.value.isEmpty ? null : controller.onBranchCodeChanged,
            decoration: _buildInputDecoration(
              '',
              hasError: controller.hasError('branchCode'),
            ).copyWith(
              hintText: controller.selectedBankBic.value.isEmpty 
                  ? 'Please select a bank first' 
                  : 'Select branch',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: controller.hasError('branchCode') ? Colors.red : const Color(0xFF6B737A),
              ),
            ),
            items: controller.availableBranches.map((BranchInfo branch) {
              return DropdownMenuItem<String>(
                value: branch.branchCode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      branch.branchName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      'Code: ${branch.branchCode}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B737A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        )),
        Obx(() {
          if (controller.hasError('branchCode')) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, top: 6),
              child: Text(
                'Please select a branch',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.red,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  InputDecoration _buildInputDecoration(
    String labelText, {
    String? hint,
    bool required = true,
    bool hasError = false,
  }) {
    final borderColor = hasError ? Colors.red : const Color(0xFFE0E0E0);
    final focusedBorderColor = hasError ? Colors.red : const Color(0xFF4F287D);

    return InputDecoration(
      labelText: required && labelText.isNotEmpty ? "$labelText *" : labelText,
      hintText: hint,
      labelStyle: GoogleFonts.poppins(
        color: hasError ? Colors.red : const Color(0xFF6B737A),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFFA0A0A0),
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusedBorderColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}