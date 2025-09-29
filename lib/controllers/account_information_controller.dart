import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_information_model.dart';
import '../services/branch_service.dart';
import '../controllers/auth_controller.dart';
import '../screens/auth/signup_successful_page.dart';

class AccountInformationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  // Form controllers
  final accountHolderNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final idNumberController = TextEditingController();

  // Observables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<IdType> selectedIdType = IdType.civilId.obs;
  final RxString selectedBankBic = ''.obs;
  final RxString selectedBranchCode = ''.obs;
  final Rx<BranchInfo?> selectedBranchInfo = Rx<BranchInfo?>(null);

  // Form validation
  final RxBool isFormValid = false.obs;
  final Set<String> _invalidFields = <String>{}.obs;
  final RxBool formSubmitted = false.obs;

  // Available data
  final RxList<String> availableBankBics = <String>[].obs;
  final RxList<BranchInfo> availableBranches = <BranchInfo>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupFormValidation();
  }

  void _initializeData() {
    availableBankBics.value = BranchService.getAllBankBics();
  }

  void _setupFormValidation() {
    // Listen to form changes
    accountHolderNameController.addListener(_validateForm);
    accountNumberController.addListener(_validateForm);
    idNumberController.addListener(_validateForm);
    
    // Listen to dropdown changes
    ever(selectedBankBic, (_) => _validateForm());
    ever(selectedBranchCode, (_) => _validateForm());
    ever(selectedIdType, (_) => _validateForm());
  }

  void _validateForm() {
    _invalidFields.clear();

    if (accountHolderNameController.text.trim().isEmpty) {
      _invalidFields.add('accountHolderName');
    }

    if (accountNumberController.text.trim().isEmpty) {
      _invalidFields.add('accountNumber');
    }

    if (idNumberController.text.trim().isEmpty) {
      _invalidFields.add('idNumber');
    }

    if (selectedBankBic.value.isEmpty) {
      _invalidFields.add('bankBic');
    }

    if (selectedBranchCode.value.isEmpty) {
      _invalidFields.add('branchCode');
    }

    isFormValid.value = _invalidFields.isEmpty;
  }

  bool hasError(String field) {
    return _invalidFields.contains(field) && formSubmitted.value;
  }

  void onBankBicChanged(String? bankBic) {
    if (bankBic != null && bankBic.isNotEmpty) {
      selectedBankBic.value = bankBic;
      selectedBranchCode.value = '';
      selectedBranchInfo.value = null;
      availableBranches.value = BranchService.getBranchesForBank(bankBic);
    } else {
      selectedBankBic.value = '';
      selectedBranchCode.value = '';
      selectedBranchInfo.value = null;
      availableBranches.clear();
    }
  }

  void onBranchCodeChanged(String? branchCode) {
    if (branchCode != null && branchCode.isNotEmpty && selectedBankBic.value.isNotEmpty) {
      selectedBranchCode.value = branchCode;
      selectedBranchInfo.value = BranchService.getBranchInfo(selectedBankBic.value, branchCode);
    } else {
      selectedBranchCode.value = '';
      selectedBranchInfo.value = null;
    }
  }

  void onIdTypeChanged(IdType? idType) {
    if (idType != null) {
      selectedIdType.value = idType;
    }
  }

  Future<bool> saveAccountInformation() async {
    formSubmitted.value = true;
    _validateForm();

    if (!isFormValid.value) {
      errorMessage.value = 'Please fill all required fields correctly.';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = _authController.firebaseUser.value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final accountInfo = AccountInformation(
        accountHolderName: accountHolderNameController.text.trim(),
        accountNumber: accountNumberController.text.trim(),
        idType: selectedIdType.value,
        idNumber: idNumberController.text.trim(),
        bankBic: selectedBankBic.value,
        branchCode: selectedBranchCode.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore with the cr_ prefix
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(accountInfo.toFirestore());

      // Navigate to signup success page
      Get.off(() => SignupSuccessfulPage(accountType: true));
      Get.snackbar(
        'Success',
        'Account information saved successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to save account information: $e';
      Get.snackbar(
        'Error',
        'Failed to save account information',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<AccountInformation?> loadAccountInformation() async {
    try {
      final user = _authController.firebaseUser.value;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Check if account information exists
      if (data['cr_account_holder_name'] != null) {
        final accountInfo = AccountInformation.fromMap(data);
        
        // Populate form fields
        accountHolderNameController.text = accountInfo.accountHolderName;
        accountNumberController.text = accountInfo.accountNumber;
        idNumberController.text = accountInfo.idNumber;
        selectedIdType.value = accountInfo.idType;
        selectedBankBic.value = accountInfo.bankBic;
        selectedBranchCode.value = accountInfo.branchCode;
        
        // Load branches and set selected branch
        availableBranches.value = BranchService.getBranchesForBank(accountInfo.bankBic);
        selectedBranchInfo.value = BranchService.getBranchInfo(accountInfo.bankBic, accountInfo.branchCode);

        return accountInfo;
      }

      return null;
    } catch (e) {
      print('Error loading account information: $e');
      return null;
    }
  }

  void clearForm() {
    accountHolderNameController.clear();
    accountNumberController.clear();
    idNumberController.clear();
    selectedIdType.value = IdType.civilId;
    selectedBankBic.value = '';
    selectedBranchCode.value = '';
    selectedBranchInfo.value = null;
    availableBranches.clear();
    formSubmitted.value = false;
    errorMessage.value = '';
    _invalidFields.clear();
  }

  String getBankDisplayName(String bankBic) {
    return BranchService.getBankName(bankBic);
  }

  @override
  void onClose() {
    accountHolderNameController.dispose();
    accountNumberController.dispose();
    idNumberController.dispose();
    super.onClose();
  }
}