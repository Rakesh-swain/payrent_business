import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart' hide Ink;
import 'dart:io';
import 'package:payrent_business/controllers/phone_auth_controller.dart';
import 'package:payrent_business/controllers/user_profile_controller.dart';
import 'package:payrent_business/controllers/auth_controller.dart';
import 'package:payrent_business/screens/auth/signup_successful_page.dart';
import 'package:payrent_business/widgets/appbar.dart';
import 'package:payrent_business/models/account_information_model.dart';
import 'package:payrent_business/services/branch_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  // Account Information Controllers
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _idNumberController = TextEditingController();
 
  final PhoneAuthController phoneAuthController = Get.find<PhoneAuthController>();
  final ImagePicker _imagePicker = ImagePicker();

  final Set<String> _invalidFields = {};
  bool _formSubmitted = false;
  bool _isProcessingOCR = false;
  String? formError;
  String _selectedAccountType = 'Landlord';
  
  // Account Information Variables
  IdType _selectedIdType = IdType.civilId;
  String _selectedBankBic = '';
  String _selectedBranchCode = '';
 List<BranchInfo> _allBranches = [];
 BranchInfo? _selectedBranch;

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp phoneRegex = RegExp(r'^[0-9]{10}$');

  bool get isFormComplete {
    if (widget.isPhoneRequired) {
      return _nameController.text.trim().isNotEmpty &&
          _mobileController.text.trim().isNotEmpty &&
          phoneRegex.hasMatch(_mobileController.text.trim()) &&
          _businessNameController.text.trim().isNotEmpty &&
          _selectedAccountType.isNotEmpty;
    } else {
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

    if (_nameController.text.trim().isEmpty) _invalidFields.add('name');
    if (_businessNameController.text.trim().isEmpty)
      _invalidFields.add('business');
    if (_selectedAccountType.isEmpty) _invalidFields.add('accountType');

    if (!widget.isPhoneRequired) {
      if (_mobileController.text.trim().isEmpty ||
          !phoneRegex.hasMatch(_mobileController.text.trim())) {
        _invalidFields.add('mobile');
      }
    } else {
      if (_emailController.text.trim().isEmpty ||
          !emailRegex.hasMatch(_emailController.text.trim())) {
        _invalidFields.add('email');
      }
    }

    if (_selectedAccountType == 'Landlord') {
      if (_idNumberController.text.trim().isEmpty) {
        _invalidFields.add('idNumber');
      }
    }

    if (_invalidFields.isNotEmpty) {
      formError = "Please fill all required fields correctly.";
    } else {
      formError = null;
    }
  }

  // OCR Processing Methods
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan Bank Cheque',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Choose how you want to capture your bank cheque',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    subtitle: 'Take a photo',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageAndProcess(ImageSource.camera);
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    subtitle: 'Choose from gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageAndProcess(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Color(0xFF4F287D)),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageAndProcess(ImageSource source) async {
    try {
      setState(() {
        _isProcessingOCR = true;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        await _processImageWithOCR(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    } finally {
      setState(() {
        _isProcessingOCR = false;
      });
    }
  }

  Future<void> _processImageWithOCR(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer();
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isNotEmpty) {
        _parseChequeData(recognizedText.text);
        _showSuccessSnackBar('Cheque data extracted successfully!');
      } else {
        _showErrorSnackBar('No text found in the image. Please try again with a clearer image.');
      }
      
      textRecognizer.close();
    } catch (e) {
      _showErrorSnackBar('Error processing image: $e');
    }
  }

  void _parseChequeData(String extractedText) {
    final lines = extractedText.split('\n');
    
    // Common patterns for different data
    final accountNumberPattern = RegExp(r'\b\d{10,16}\b'); // Account numbers are typically 10-16 digits
    final routingNumberPattern = RegExp(r'\b\d{9}\b'); // Routing numbers are 9 digits
    
    // Bank name patterns (common banks)
    final bankPatterns = {
      'NBK': 'NBOKKWKW',
      'NATIONAL BANK OF KUWAIT': 'NBOKKWKW',
      'CBK': 'CBKUKWKW',
      'COMMERCIAL BANK': 'CBKUKWKW',
      'ABK': 'ABKUKWKW',
      'AHLI BANK': 'ABKUKWKW',
      'KFH': 'KFHOKWKW',
      'KUWAIT FINANCE HOUSE': 'KFHOKWKW',
      'GULF BANK': 'GULBKWKW',
      'WARBA BANK': 'WARBKWKW',
      'BOUBYAN BANK': 'BOUBKWKW',
    };

    String foundAccountNumber = '';
    String foundBankBic = '';
    String foundAccountHolderName = '';

    // Extract account number
    final accountMatches = accountNumberPattern.allMatches(extractedText);
    if (accountMatches.isNotEmpty) {
      // Usually the longest number is the account number
      foundAccountNumber = accountMatches
          .map((match) => match.group(0)!)
          .reduce((a, b) => a.length > b.length ? a : b);
    }

    // Extract bank name and map to BIC
    for (final line in lines) {
      final upperLine = line.toUpperCase();
      for (final entry in bankPatterns.entries) {
        if (upperLine.contains(entry.key)) {
          foundBankBic = entry.value;
          break;

          
        }
      }
      if (foundBankBic.isNotEmpty) break;
    }

    // Extract account holder name (usually appears after "PAY TO" or similar)
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      if (line.contains('PAY TO') || line.contains('PAYEE') || line.contains('NAME')) {
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.isNotEmpty && !accountNumberPattern.hasMatch(nextLine)) {
            foundAccountHolderName = nextLine;
            break;
          }
        }
      }
    }

    // If no specific pattern found, try to find a name-like string
    if (foundAccountHolderName.isEmpty) {
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.length > 3 && 
            trimmedLine.length < 50 && 
            RegExp(r'^[A-Za-z\s]+$').hasMatch(trimmedLine) &&
            !trimmedLine.toUpperCase().contains('BANK') &&
            !trimmedLine.toUpperCase().contains('CHEQUE')) {
          foundAccountHolderName = trimmedLine;
          break;
        }
      }
    }

    // Update form fields
    setState(() {
      if (foundAccountNumber.isNotEmpty) {
        _accountNumberController.text = foundAccountNumber;
      }
      
      if (foundAccountHolderName.isNotEmpty) {
        _accountHolderNameController.text = foundAccountHolderName;
      }

      if (foundBankBic.isNotEmpty && _allBranches.any((b) => b.bankBic == foundBankBic)) {
        _selectedBankBic = foundBankBic;
        _allBranches = [BranchService.getBranchesForBank(foundBankBic)];
        // Auto-select first branch if available
        if (_allBranches.isNotEmpty) {
          _selectedBranchCode = _allBranches.first.branchCode;
        }
      }
    });

    // Show what was extracted
    _showExtractionResultDialog(foundAccountNumber, foundBankBic, foundAccountHolderName);
  }

  void _showExtractionResultDialog(String accountNumber, String bankBic, String accountHolderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Extracted Information',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (accountHolderName.isNotEmpty) ...[
              Text('Account Holder:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              Text(accountHolderName, style: GoogleFonts.poppins()),
              SizedBox(height: 8),
            ],
            if (accountNumber.isNotEmpty) ...[
              Text('Account Number:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              Text(accountNumber, style: GoogleFonts.poppins()),
              SizedBox(height: 8),
            ],
            if (bankBic.isNotEmpty) ...[
              Text('Bank:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              Text(bankBic, style: GoogleFonts.poppins()),
              SizedBox(height: 8),
            ],
            SizedBox(height: 8),
            Text(
              'Please verify the extracted information and make corrections if needed.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins(color: Color(0xFF4F287D))),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Save profile and account information
  Future<void> _saveProfileAndAccountInfo() async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.firebaseUser.value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic> profileData = {
        'email': _emailController.text.trim(),
        'phone': _mobileController.text.isEmpty 
            ? phoneAuthController.mobileNumber.value 
            : _mobileController.text.trim(),
        'name': _nameController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'userType': _selectedAccountType,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isVerified': false,
      };

      if (_selectedAccountType == 'Landlord') {
        final accountInfo = AccountInformation(
          accountHolderName: _accountHolderNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          idType: _selectedIdType,
          idNumber: _idNumberController.text.trim(),
          bankBic: _selectedBankBic,
          branchCode: _selectedBranchCode,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        profileData.addAll(accountInfo.toFirestore());
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profileData);

      Get.off(() => SignupSuccessfulPage(accountType: _selectedAccountType == "Landlord"));
      
    } catch (e) {
      setState(() {
        formError = 'Failed to save information: $e';
      });
      print('Error saving profile and account info: $e');
    }
  }

  InputDecoration buildInputDecoration(
    String labelText, {
    String? hintText,
    bool required = false,
    bool hasError = false,
  }) {
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
  void initState() {
    print(phoneAuthController.mobileNumber.value);
    _allBranches = BranchService.getAllBranchList();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _idNumberController.dispose();
    super.dispose();
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
                          decoration:
                              buildInputDecoration(
                                "Full Name",
                                hintText: "Enter your full name",
                                required: true,
                                hasError: _hasError('name'),
                              ).copyWith(
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: _hasError('name')
                                      ? Colors.red
                                      : const Color(0xFF6B737A),
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
                          decoration:
                              buildInputDecoration(
                                "Business Name",
                                hintText: "Enter your business name",
                                required: true,
                                hasError: _hasError('business'),
                              ).copyWith(
                                prefixIcon: Icon(
                                  Icons.business_outlined,
                                  color: _hasError('business')
                                      ? Colors.red
                                      : const Color(0xFF6B737A),
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
                            decoration:
                                buildInputDecoration(
                                  "Mobile Number",
                                  hintText: "Enter your 10-digit mobile number",
                                  required: true,
                                  hasError: _hasError('mobile'),
                                ).copyWith(
                                  prefixIcon: Icon(
                                    Icons.phone_android_rounded,
                                    color: _hasError('mobile')
                                        ? Colors.red
                                        : const Color(0xFF6B737A),
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
                            decoration:
                                buildInputDecoration(
                                  "Email Address",
                                  hintText: "Enter your email address",
                                  required: true,
                                  hasError: _hasError('email'),
                                ).copyWith(
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: _hasError('email')
                                        ? Colors.red
                                        : const Color(0xFF6B737A),
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
                            color: _hasError('accountType')
                                ? Colors.red
                                : const Color(0xFF333333),
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

                  // Account Information for Landlords
                  if (_selectedAccountType == 'Landlord') ...[
                    const SizedBox(height: 32),
                    
                    // Account Information Header
                    FadeInUp(
                      duration: const Duration(milliseconds: 1200),
                      child: Center(
                        child: Text(
                          'Account Information',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF333333),
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    FadeInUp(
                      duration: const Duration(milliseconds: 1250),
                      child: Center(
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

                    const SizedBox(height: 16),

                    // OCR Scan Option
                    FadeInUp(
                      duration: const Duration(milliseconds: 1275),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F287D).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4F287D).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.document_scanner,
                                  color: const Color(0xFF4F287D),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Quick Fill with Bank Cheque',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4F287D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan or upload a photo of your bank cheque to automatically fill account details',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF6B737A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isProcessingOCR ? null : _showImageSourceDialog,
                                icon: _isProcessingOCR 
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Icon(Icons.camera_alt, size: 16),
                                label: Text(
                                  _isProcessingOCR ? 'Processing...' : 'Scan Cheque',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F287D),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Account Holder Name Field
                    FadeInLeft(
                      duration: const Duration(milliseconds: 1300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _accountHolderNameController,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                            decoration: buildInputDecoration(
                              "Account Holder Name",
                              hintText: "Enter the full name as on bank account",
                              required: true,
                              hasError: _hasError('accountHolderName'),
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: _hasError('accountHolderName')
                                    ? Colors.red
                                    : const Color(0xFF6B737A),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                          ),
                          if (_hasError('accountHolderName'))
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 6),
                              child: Text(
                                "Account holder name is required",
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

                    // Account Number Field
                    FadeInRight(
                      duration: const Duration(milliseconds: 1350),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _accountNumberController,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                            decoration: buildInputDecoration(
                              "Account Number",
                              hintText: "Enter your bank account number",
                              required: true,
                              hasError: _hasError('accountNumber'),
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.account_balance_outlined,
                                color: _hasError('accountNumber')
                                    ? Colors.red
                                    : const Color(0xFF6B737A),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textInputAction: TextInputAction.next,
                          ),
                          if (_hasError('accountNumber'))
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 6),
                              child: Text(
                                "Account number is required",
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

                    // ID Type Dropdown
                    FadeInLeft(
                      duration: const Duration(milliseconds: 1400),
                      child: Column(
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
                          Container(
                            decoration: BoxDecoration(
                            ),
                            child: DropdownButtonFormField<IdType>(
                              borderRadius:  BorderRadius.circular(12),
                              value: _selectedIdType,
                              onChanged: (IdType? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedIdType = newValue;
                                  });
                                }
                              },
                              decoration: buildInputDecoration(
                                '',
                                hasError: false,
                              ).copyWith(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ID Number Field
                    FadeInRight(
                      duration: const Duration(milliseconds: 1450),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _idNumberController,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                            decoration: buildInputDecoration(
                              "ID Number",
                              hintText: "Enter your identification number",
                              required: true,
                              hasError: _hasError('idNumber'),
                            ).copyWith(
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color: _hasError('idNumber')
                                    ? Colors.red
                                    : const Color(0xFF6B737A),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          if (_hasError('idNumber'))
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 6),
                              child: Text(
                                "ID number is required",
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

                    // Bank BIC Dropdown
                    FadeInLeft(
                      duration: const Duration(milliseconds: 1500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank BIC',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                              borderRadius: BorderRadius.circular(12),
                              value: _selectedBankBic.isEmpty ? null : _selectedBankBic,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedBankBic = newValue;
                                    _selectedBranchCode = '';
                                    _allBranches = [BranchService.getBranchesForBank(newValue)];
                                  });
                                }
                              },
                              decoration: buildInputDecoration(
                                '',
                                hasError: _hasError('bankBic'),
                              ).copyWith(
                                hintText: 'Select your bank',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                prefixIcon: Icon(
                                  Icons.account_balance_outlined,
                                  color: _hasError('bankBic') ? Colors.red : const Color(0xFF6B737A),
                                ),
                              ),
                              items: _allBranches.map((BranchInfo branch) {
                                return DropdownMenuItem<String>(
                                  value: branch.bankBic,
                                  child: Text(
                                    branch.bankBic,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          if (_hasError('bankBic'))
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 6),
                              child: Text(
                                "Please select a bank",
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

                    // Branch Code Dropdown
                    FadeInRight(
                      duration: const Duration(milliseconds: 1550),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Branch',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            borderRadius: BorderRadius.circular(12),
                              value: _selectedBranchCode.isEmpty ? null : _selectedBranchCode,
                              onChanged: _selectedBankBic.isEmpty 
                                  ? null 
                                  : (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedBranchCode = newValue;
                                        });
                                      }
                                    },
                              decoration: buildInputDecoration(
                                '',
                                hasError: _hasError('branchCode'),
                              ).copyWith(
                                hintText: _selectedBankBic.isEmpty 
                                    ? 'Please select a bank first' 
                                    : 'Select branch',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  prefixIcon: Icon(
                                  Icons.location_on_outlined,
                                  color: _hasError('branchCode') ? Colors.red : const Color(0xFF6B737A),
                                ),
                              ),
                              isExpanded: true,
                              items: _allBranches.map((BranchInfo branch) {
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
                                          color: const Color(0xFF333333),
                                        ),
                                      ),
                                      SizedBox(width: 15,),
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
                          if (_hasError('branchCode'))
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 6),
                              child: Text(
                                "Please select a branch",
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

                    // Selected Branch Information Display
                    if (_selectedBranchCode.isNotEmpty && _selectedBankBic.isNotEmpty)
                      FadeInUp(
                        duration: const Duration(milliseconds: 1600),
                        child: Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4F287D).withOpacity(0.3),
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
                                    branchInfo.branchCode,
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
                              );
                            }
                            return const SizedBox.shrink();
                          }(),
                        ),
                      ),
                  ],

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
                        onPressed: () async {
                          setState(() {
                            _formSubmitted = true;
                          });

                          _validateForm();

                          if (_invalidFields.isEmpty) {
                            setState(() => formError = null);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                              'userType',
                              _selectedAccountType,
                            );

                            await _saveProfileAndAccountInfo();
                          } else {
                            setState(
                              () => formError =
                                  "Please fill all required fields correctly.",
                            );
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
            color: hasError
                ? Colors.red
                : isSelected
                ? const Color(0xFF4F287D)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? const Color(0xFF4F287D)
                  : const Color(0xFF6B737A),
            ),
            const SizedBox(height: 12),
            Text(
              type,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF4F287D)
                    : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}