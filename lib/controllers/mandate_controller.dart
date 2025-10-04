import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mandate_model.dart';
import '../services/firestore_service.dart';
import '../controllers/auth_controller.dart';

class MandateController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthController _authController = Get.find<AuthController>();

  // API endpoints
  static const String _baseUrl = 'https://sandbox-payrent.paycorp.io';
  static const String _mandateDetailsEndpoint = '/mandate/create';
  static const String _mandateEnquiryEndpoint = '/mandate/enquiry';

  // Observable lists
  final RxList<MandateModel> _mandates = <MandateModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<MandateModel> get mandates => _mandates;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  int get mandateCount => _mandates.length;

  @override
  void onInit() {
    super.onInit();
    fetchMandates();
  }

  /// Fetch all mandates for current user from Firestore
  Future<void> fetchMandates() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestoreService.querySubcollectionDocuments(
        parentCollection: 'users',
        parentDocumentId: currentUser.uid,
        subcollection: 'mandates',
        orderBy: 'createdAt',
        descending: true,
      );

      final mandateList = querySnapshot.docs
          .map((doc) => MandateModel.fromFirestore(doc))
          .toList();

      _mandates.assignAll(mandateList);
    } catch (e) {
      _errorMessage.value = 'Error fetching mandates: $e';
      print('Error fetching mandates: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Calculate end date based on start date, number of installments and frequency
  DateTime calculateEndDate(
    DateTime startDate,
    int noOfInstallments,
    String frequency,
  ) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return startDate.add(Duration(days: noOfInstallments - 1));
      case 'weekly':
        return startDate.add(Duration(days: (noOfInstallments - 1) * 7));
      case 'monthly':
        // Add months (approximate, actual month lengths may vary)
        return DateTime(
          startDate.year,
          startDate.month + (noOfInstallments - 1),
          startDate.day,
        );
      case 'yearly':
        return DateTime(
          startDate.year + (noOfInstallments - 1),
          startDate.month,
          startDate.day,
        );
      default:
        // Default to weekly
        return startDate.add(Duration(days: (noOfInstallments - 1) * 7));
    }
  }

  /// Generate a unique reference number (UUID v4, 32 characters)
  String generateReferenceNumber() {
    const uuid = Uuid();
    return uuid.v4().replaceAll('-', ''); // Remove dashes to get 32 characters
  }

  /// Create a new mandate (call API and save to Firestore)
  Future<MandateModel?> createMandate({
    required String landlordId,
    required String tenantId,
    required String propertyId,
    required String unitId,
    required String landlordAccountHolderName,
    required String landlordAccountNumber,
    required String landlordIdType,
    required String landlordIdNumber,
    required String landlordBankBic,
    required String landlordBranchCode,
    required String tenantAccountHolderName,
    required String tenantAccountNumber,
    required String tenantIdType,
    required String tenantIdNumber,
    required String tenantBankBic,
    required String tenantBranchCode,
    required int rentAmount,
    required DateTime startDate,
    required int noOfInstallments,
    required String paymentFrequency,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Generate reference number and calculate end date
      final referenceNumber = generateReferenceNumber();
      final endDate = calculateEndDate(
        startDate,
        noOfInstallments,
        paymentFrequency,
      );

      // Create mandate model
      final mandate = MandateModel(
        landlordId: landlordId,
        tenantId: tenantId,
        propertyId: propertyId,
        unitId: unitId,
        referenceNumber: referenceNumber,
        landlordAccountHolderName: landlordAccountHolderName,
        landlordAccountNumber: landlordAccountNumber,
        landlordIdType: landlordIdType,
        landlordIdNumber: landlordIdNumber,
        landlordBankBic: landlordBankBic,
        landlordBranchCode: landlordBranchCode,
        tenantAccountHolderName: tenantAccountHolderName,
        tenantAccountNumber: tenantAccountNumber,
        tenantIdType: tenantIdType,
        tenantIdNumber: tenantIdNumber,
        tenantBankBic: tenantBankBic,
        tenantBranchCode: tenantBranchCode,
        rentAmount: rentAmount,
        paymentFrequency: paymentFrequency,
        startDate: startDate,
        endDate: endDate,
        noOfInstallments: noOfInstallments,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Call API to create mandate
      final apiResponse = await _callMandateDetailsApi(mandate);

      if (apiResponse != null) {
        // Update mandate with API response data
        final updatedMandate = mandate.copyWith(
          mmsId: apiResponse["MMSId"],
          mmsStatus: apiResponse['status'],
        );

        // Save to Firestore
        final docRef = await _firestoreService.createSubcollectionDocument(
          parentCollection: 'users',
          parentDocumentId: currentUser.uid,
          subcollection: 'mandates',
          data: updatedMandate.toFirestore(),
        );

        // // Add to local list
        // final finalMandate = updatedMandate.copyWith();
        // _mandates.insert(0, finalMandate);
        await fetchMandates();

        Get.snackbar(
          'Success',
          'Mandate created successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
        );

        return updatedMandate;
      } else {
        throw Exception('Failed to create mandate via API');
      }
    } catch (e) {
      _errorMessage.value = 'Error creating mandate: $e';
      Get.snackbar(
        'Error',
        'Failed to create mandate: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );

      print('Error creating mandate: $e');
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Call the mandate details API
  Future<Map<String, dynamic>?> _callMandateDetailsApi(
    MandateModel mandate,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl$_mandateDetailsEndpoint');
      final payload = mandate.toApiPayload();

      print('Calling mandate details API: $url');
      print('Payload: $payload');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 202) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling mandate details API: $e');
      return null;
    }
  }

  /// Update mandate status by calling the enquiry API
  Future<bool> updateMandateStatus(String mandateId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find the mandate
      final mandate = _mandates.firstWhere(
        (m) => m.id == mandateId,
        orElse: () => throw Exception('Mandate not found'),
      );

      if (mandate.mmsId == null) {
        throw Exception('MMS ID not available');
      }

      // Call enquiry API
      final apiResponse = await _callMandateEnquiryApi(mandate.mmsId!);

      if (apiResponse != null) {
        final newStatus = apiResponse['mmsStatus'] ?? mandate.mmsStatus;

        // Update in Firestore
        await _firestoreService.updateSubcollectionDocument(
          parentCollection: 'users',
          parentDocumentId: currentUser.uid,
          subcollection: 'mandates',
          documentId: mandateId,
          data: {'mmsStatus': newStatus, 'updatedAt': DateTime.now()},
        );

        // Update local list
        final index = _mandates.indexWhere((m) => m.id == mandateId);
        if (index != -1) {
          _mandates[index] = mandate.copyWith(mmsStatus: newStatus);
        }

        Get.snackbar(
          'Success',
          'Mandate status updated to: $newStatus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
        );

        return true;
      } else {
        throw Exception('Failed to get mandate status from API');
      }
    } catch (e) {
      _errorMessage.value = 'Error updating mandate status: $e';
      Get.snackbar(
        'Error',
        'Failed to update mandate status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );
      print('Error updating mandate status: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Call the mandate enquiry API
  Future<Map<String, dynamic>?> _callMandateEnquiryApi(String mmsId) async {
    try {
      final url = Uri.parse('$_baseUrl$_mandateEnquiryEndpoint');
      final payload = {'mmsId': mmsId};

      print('Calling mandate enquiry API: $url');
      print('Payload: $payload');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 202) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling mandate enquiry API: $e');
      return null;
    }
  }

  /// Get mandate by ID
  MandateModel? getMandateById(String id) {
    try {
      return _mandates.firstWhere((mandate) => mandate.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get mandates by status
  List<MandateModel> getMandatesByStatus(String status) {
    return _mandates.where((mandate) => mandate.mmsStatus == status).toList();
  }

  /// Get active mandates
  List<MandateModel> getActiveMandates() {
    return _mandates
        .where((mandate) => mandate.mmsStatus == 'ACCEPTED')
        .toList();
  }

  /// Get pending mandates
  List<MandateModel> getPendingMandates() {
    return _mandates
        .where((mandate) => mandate.mmsStatus == 'PENDING')
        .toList();
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  /// Refresh mandates
  Future<void> refreshMandates() async {
    await fetchMandates();
  }
}
