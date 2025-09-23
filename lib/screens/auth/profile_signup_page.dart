import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:payrent_business/controllers/user_profile_controller.dart';
import 'package:payrent_business/screens/auth/signup_successful_page.dart';
import 'package:payrent_business/widgets/appbar.dart';

class ProfileSignupPage extends StatefulWidget {
  final bool isPhoneRequired;
  const ProfileSignupPage({super.key, required this.isPhoneRequired});

  @override
  State<ProfileSignupPage> createState() => _ProfileSignupPageState();
}

class _ProfileSignupPageState extends State<ProfileSignupPage> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessNameController = TextEditingController();
  UserProfileController userProfileController = Get.put(UserProfileController());

  final Set<String> _invalidFields = {};
  bool _formSubmitted = false; // Track if form has been submitted
  String? formError;
  String _selectedAccountType = 'Landlord'; // Default selection

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp phoneRegex = RegExp(r'^[0-9]{10}$');

  bool get isFormComplete {
    if (widget.isPhoneRequired) {
      // When phone is required, check name, phone, business name and account type
      return _nameController.text.trim().isNotEmpty &&
          _mobileController.text.trim().isNotEmpty &&
          phoneRegex.hasMatch(_mobileController.text.trim()) &&
          _businessNameController.text.trim().isNotEmpty &&
          _selectedAccountType.isNotEmpty;
    } else {
      // When phone is not required, check name, email, business name and account type
      return _nameController.text.trim().isNotEmpty &&
          emailRegex.hasMatch(_emailController.text.trim()) &&
          _businessNameController.text.trim().isNotEmpty &&
          _selectedAccountType.isNotEmpty;
    }
  }

  bool _hasError(String field) =>
      _invalidFields.contains(field) && _formSubmitted;

  void _validateForm() {
    _invalidFields.clear();

    // Always validate name and business name
    if (_nameController.text.trim().isEmpty) _invalidFields.add('name');
    if (_businessNameController.text.trim().isEmpty) _invalidFields.add('business');
    if (_selectedAccountType.isEmpty) _invalidFields.add('accountType');

    // Validate based on isPhoneRequired
    if (!widget.isPhoneRequired) {
      // Validate mobile
      if (_mobileController.text.trim().isEmpty || 
          !phoneRegex.hasMatch(_mobileController.text.trim())) {
        _invalidFields.add('mobile');
      }
    } else {
      // Validate email
      if (_emailController.text.trim().isEmpty ||
          !emailRegex.hasMatch(_emailController.text.trim())) {
        _invalidFields.add('email');
      }
    }

    if (_invalidFields.isNotEmpty) {
      formError = "Please fill all required fields correctly.";
    } else {
      formError = null;
    }
  }

  InputDecoration buildInputDecoration(String labelText, {String? hintText, bool required = false, bool hasError = false}) {
    final borderColor = hasError ? Colors.red : const Color(0xFFE0E0E0);
    final focusedBorderColor = hasError ? Colors.red : const Color(0xFF4F287D);
    
    return InputDecoration(
      labelText: required ? "$labelText *" : labelText,
      hintText: hintText,
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
      prefixIconColor: hasError ? Colors.red : const Color(0xFF6B737A),
      suffixIconColor: hasError ? Colors.red : const Color(0xFF6B737A),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: appBar(context),
      body: SingleChildScrollView( physics: const BouncingScrollPhysics(),
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
                        'Personal Information',
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
                        'Please fill in your details below',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B737A),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Full Name Field
                  FadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF333333),
                          ),
                          decoration: buildInputDecoration(
                            "Full Name",
                            hintText: "Enter your full name",
                            required: true, 
                            hasError: _hasError('name'),
                          ).copyWith(
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: _hasError('name') ? Colors.red : const Color(0xFF6B737A),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                        if (_hasError('name'))
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 6),
                            child: Text(
                              "Please enter your full name",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Business Name Field
                  FadeInRight(
                    duration: const Duration(milliseconds: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _businessNameController,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF333333),
                          ),
                          decoration: buildInputDecoration(
                            "Business Name",
                            hintText: "Enter your business name",
                            required: true,
                            hasError: _hasError('business'),
                          ).copyWith(
                            prefixIcon: Icon(
                              Icons.business_outlined,
                              color: _hasError('business') ? Colors.red : const Color(0xFF6B737A),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                        if (_hasError('business'))
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 6),
                            child: Text(
                              "Business name is required",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Conditionally show Mobile or Email field
                  if (!widget.isPhoneRequired)
                    FadeInLeft(
                      duration: const Duration(milliseconds: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _mobileController,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                            decoration: buildInputDecoration(
                              "Mobile Number",
                              hintText: "Enter your 10-digit mobile number",
                              required: true,
                              hasError: _hasError('mobile'),
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.phone_android_rounded,
                                color: _hasError('mobile') ? Colors.red : const Color(0xFF6B737A),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            textInputAction: TextInputAction.next,
                          ),
                          if (_hasError('mobile'))
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 6),
                              child: Text(
                                "Please enter a valid 10-digit mobile number",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    FadeInRight(
                      duration: const Duration(milliseconds: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                            decoration: buildInputDecoration(
                              "Email Address",
                              hintText: "Enter your email address",
                              required: true,
                              hasError: _hasError('email'),
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: _hasError('email') ? Colors.red : const Color(0xFF6B737A),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          if (_hasError('email'))
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 6),
                              child: Text(
                                "Please enter a valid email address",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Account Type Selection
                  FadeInLeft(
                    duration: const Duration(milliseconds: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Account Type *",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _hasError('accountType') ? Colors.red : const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAccountTypeOption(
                                type: "Landlord",
                                isSelected: _selectedAccountType == "Landlord",
                                icon: Icons.home_work_outlined,
                                hasError: _hasError('accountType'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAccountTypeOption(
                                type: "Tenant",
                                isSelected: _selectedAccountType == "Tenant",
                                icon: Icons.person_outline_rounded,
                                hasError: _hasError('accountType'),
                              ),
                            ),
                          ],
                        ),
                        if (_hasError('accountType'))
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 6),
                            child: Text(
                              "Please select an account type",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Error message
                  if (formError != null && _formSubmitted)
                    FadeIn(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                formError!,
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
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Continue Button
                  FadeInUp(
                    duration: const Duration(milliseconds: 1200),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _formSubmitted = true;
                          });
                          
                          _validateForm();
                          
                          if (_invalidFields.isEmpty) {
                            setState(() => formError = null);
                            userProfileController.completeProfileSetup(
                              name: _nameController.text.trim(),
                              businessName: _businessNameController.text.trim(),
                              userType: _selectedAccountType,
                              email: widget.isPhoneRequired ? '' : _emailController.text.trim(),
                              phone: widget.isPhoneRequired ? _mobileController.text.trim() : '',
                            );
                           
                            
                          
                          } else {
                            setState(() => formError = "Please fill all required fields correctly.");
                          }
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
  
  Widget _buildAccountTypeOption({
    required String type,
    required bool isSelected,
    required IconData icon,
    required bool hasError,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAccountType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECE6F0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError ? Colors.red : 
                   isSelected ? const Color(0xFF4F287D) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF4F287D) : const Color(0xFF6B737A),
            ),
            const SizedBox(height: 12),
            Text(
              type,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF4F287D) : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}