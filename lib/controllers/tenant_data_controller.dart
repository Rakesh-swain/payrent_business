import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/tenant_auth_service.dart';

class TenantDataController extends GetxController {
  static TenantDataController get to => Get.find();
  
  final TenantAuthService _tenantAuthService = TenantAuthService();
  
  // Observables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Tenant Information
  final RxString tenantId = ''.obs;
  final RxString landlordId = ''.obs;
  final Rx<Map<String, dynamic>?> tenantData = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> landlordData = Rx<Map<String, dynamic>?>(null);
  
  // Properties & Units
  final RxList<Map<String, dynamic>> tenantProperties = <Map<String, dynamic>>[].obs;
  
  // Payments
  final RxList<Map<String, dynamic>> paymentHistory = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> pendingPayments = <Map<String, dynamic>>[].obs;
  
  // Maintenance Requests
  final RxList<Map<String, dynamic>> maintenanceRequests = <Map<String, dynamic>>[].obs;
  
  // Dashboard Statistics
  final RxInt totalProperties = 0.obs;
  final RxDouble totalRentAmount = 0.0.obs;
  final RxInt pendingPaymentsCount = 0.obs;
  final RxDouble nextPaymentAmount = 0.0.obs;
  final RxString nextPaymentDate = ''.obs;
  
  /// Initialize tenant data after authentication
  Future<void> initializeTenantData(Map<String, dynamic> tenantInfo) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Set basic tenant info
      tenantId.value = tenantInfo['tenantId'];
      landlordId.value = tenantInfo['landlordId'];
      tenantData.value = tenantInfo['tenantData'];
      landlordData.value = tenantInfo['landlordData'];
      
      // Fetch all tenant-related data
      await Future.wait([
        fetchTenantProperties(),
        fetchPaymentHistory(),
        fetchMaintenanceRequests(),
      ]);
      
      // Calculate dashboard statistics
      _calculateDashboardStats();
      
    } catch (e) {
      errorMessage.value = 'Failed to load tenant data: $e';
      print('Error initializing tenant data: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Fetch tenant's properties and units
  Future<void> fetchTenantProperties() async {
    try {
      final properties = await _tenantAuthService.getTenantProperties(
        landlordId.value,
        tenantId.value,
      );
      
      tenantProperties.value = properties;
      totalProperties.value = properties.length;
      
    } catch (e) {
      print('Error fetching tenant properties: $e');
      throw Exception('Failed to fetch properties: $e');
    }
  }
  
  /// Fetch tenant's payment history
  Future<void> fetchPaymentHistory() async {
    try {
      final payments = await _tenantAuthService.getTenantPayments(
        landlordId.value,
        tenantId.value,
      );
      
      paymentHistory.value = payments;
      
      // Separate pending and completed payments
      final now = DateTime.now();
      final pending = <Map<String, dynamic>>[];
      
      for (final payment in payments) {
        final paymentData = payment['paymentData'] as Map<String, dynamic>;
        final status = paymentData['status']?.toString().toLowerCase() ?? '';
        final dueDate = paymentData['dueDate'];
        
        // Check if payment is pending
        if (status == 'pending' || status == 'overdue' || 
            (dueDate != null && (dueDate as Timestamp).toDate().isAfter(now) && status != 'paid')) {
          pending.add(payment);
        }
      }
      
      pendingPayments.value = pending;
      pendingPaymentsCount.value = pending.length;
      
    } catch (e) {
      print('Error fetching payment history: $e');
      throw Exception('Failed to fetch payments: $e');
    }
  }
  
  /// Fetch tenant's maintenance requests
  Future<void> fetchMaintenanceRequests() async {
    try {
      final requests = await _tenantAuthService.getTenantMaintenanceRequests(
        landlordId.value,
        tenantId.value,
      );
      
      maintenanceRequests.value = requests;
      
    } catch (e) {
      print('Error fetching maintenance requests: $e');
      // Don't throw error for maintenance requests as it's optional
    }
  }
  
  /// Get landlord contact information
  Future<Map<String, dynamic>?> getLandlordInfo() async {
    try {
      return await _tenantAuthService.getLandlordInfo(landlordId.value);
    } catch (e) {
      print('Error getting landlord info: $e');
      return null;
    }
  }
  
  /// Calculate dashboard statistics
  void _calculateDashboardStats() {
    double totalRent = 0.0;
    
    // Calculate total rent from all properties
    for (final property in tenantProperties) {
      final tenantData = property['tenantData'] as Map<String, dynamic>?;
      final unitDetails = property['unitDetails'] as Map<String, dynamic>?;
      
      // Get rent amount from tenant data or unit details
      double rentAmount = 0.0;
      if (tenantData?['rentAmount'] != null) {
        rentAmount = (tenantData!['rentAmount'] as num).toDouble();
      } else if (unitDetails?['rent'] != null) {
        rentAmount = (unitDetails!['rent'] as num).toDouble();
      }
      
      totalRent += rentAmount;
    }
    
    totalRentAmount.value = totalRent;
    
    // Find next payment due
    if (pendingPayments.isNotEmpty) {
      final nextPayment = pendingPayments.first;
      final paymentData = nextPayment['paymentData'] as Map<String, dynamic>;
      
      nextPaymentAmount.value = (paymentData['amount'] as num?)?.toDouble() ?? 0.0;
      
      if (paymentData['dueDate'] != null) {
        final dueDate = (paymentData['dueDate'] as Timestamp).toDate();
        nextPaymentDate.value = _formatDate(dueDate);
      }
    } else {
      nextPaymentAmount.value = 0.0;
      nextPaymentDate.value = '';
    }
  }
  
  /// Refresh all tenant data
  Future<void> refreshTenantData() async {
    await Future.wait([
      fetchTenantProperties(),
      fetchPaymentHistory(),
      fetchMaintenanceRequests(),
    ]);
    
    _calculateDashboardStats();
  }
  
  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${-difference} days overdue';
    }
  }
  
  /// Get tenant full name
  String get tenantFullName {
    final data = tenantData.value;
    if (data != null) {
      final firstName = data['firstName'] ?? '';
      final lastName = data['lastName'] ?? '';
      return '$firstName $lastName'.trim();
    }
    return 'Unknown Tenant';
  }
  
  /// Get tenant email
  String get tenantEmail {
    return tenantData.value?['email'] ?? '';
  }
  
  /// Get tenant phone
  String get tenantPhone {
    return tenantData.value?['phone'] ?? '';
  }
  
  /// Get primary property (first property if multiple)
  Map<String, dynamic>? get primaryProperty {
    if (tenantProperties.isNotEmpty) {
      return tenantProperties.first;
    }
    return null;
  }
  
  /// Check if tenant has multiple properties
  bool get hasMultipleProperties {
    return tenantProperties.length > 1;
  }
  
  /// Get lease information for primary property
  Map<String, dynamic>? get leaseInfo {
    final primary = primaryProperty;
    if (primary != null) {
      final tenantData = primary['tenantData'] as Map<String, dynamic>?;
      return {
        'leaseStartDate': tenantData?['leaseStartDate'],
        'leaseEndDate': tenantData?['leaseEndDate'],
        'rentAmount': tenantData?['rentAmount'],
        'paymentFrequency': tenantData?['paymentFrequency'],
        'rentDueDay': tenantData?['rentDueDay'],
      };
    }
    return null;
  }
  
  /// Clear all data (for logout)
  void clearData() {
    tenantId.value = '';
    landlordId.value = '';
    tenantData.value = null;
    landlordData.value = null;
    tenantProperties.clear();
    paymentHistory.clear();
    pendingPayments.clear();
    maintenanceRequests.clear();
    totalProperties.value = 0;
    totalRentAmount.value = 0.0;
    pendingPaymentsCount.value = 0;
    nextPaymentAmount.value = 0.0;
    nextPaymentDate.value = '';
    errorMessage.value = '';
  }
}