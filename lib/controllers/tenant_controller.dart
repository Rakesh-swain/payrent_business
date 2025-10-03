import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../repositories/tenant_repository.dart';
import '../models/tenant_model.dart';

class TenantController extends GetxController {
  static TenantController get to => Get.find();
  
  final TenantRepository _tenantRepository = TenantRepository();
  final AuthController _authController = Get.find<AuthController>();
  
  // Observables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxList<DocumentSnapshot> tenants = <DocumentSnapshot>[].obs;  
  final RxList<DocumentSnapshot> filteredTenants = <DocumentSnapshot>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchTenants();
  }
  
  // Fetch tenants for current landlord from users/{userId}/tenants subcollection
  Future<void> fetchTenants({bool forceRefresh = false}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }

      final uid = _authController.firebaseUser.value!.uid;

      final docs = await _tenantRepository.fetchTenants(
        landlordId: uid,
        forceRefresh: forceRefresh,
      );

      tenants.value = docs;
      filteredTenants.value = docs;
    } catch (e) {
      errorMessage.value = 'Failed to fetch tenants';
      print('Error fetching tenants: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Get tenant by ID from users/{userId}/tenants subcollection
  Future<DocumentSnapshot?> getTenantById(String tenantId) async {
    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return null;
      }
      
      final uid = _authController.firebaseUser.value!.uid;
      
      final doc = await _tenantRepository.getTenant(
        landlordId: uid,
        tenantId: tenantId,
        forceRefresh: false,
      );

      return doc;
    } catch (e) {
      errorMessage.value = 'Failed to get tenant';
      print('Error getting tenant: $e');
      return null;
    }
  }
  
  // Calculate payment data based on payment frequency, dates, and rent amount
  Map<String, dynamic> calculatePaymentData({
    required String paymentFrequency,
    required DateTime leaseStartDate,
    required DateTime leaseEndDate,
    required double rentAmount,
    DateTime? currentDate,
  }) {
    currentDate ??= DateTime.now();
    
    // Calculate the number of payments due based on frequency
    int paymentCount = 0;
    DateTime nextPaymentDate = leaseStartDate;
    
    // Determine payment period in days
    int periodDays;
    String periodDescription;
    
    switch (paymentFrequency.toLowerCase()) {
      case 'weekly':
        periodDays = 7;
        periodDescription = 'Week';
        break;
      case 'monthly':
        periodDays = 30; // Approximate
        periodDescription = 'Month';
        break;
      case 'quarterly':
        periodDays = 90; // Approximate
        periodDescription = 'Quarter';
        break;
      case 'yearly':
        periodDays = 365; // Approximate
        periodDescription = 'Year';
        break;
      default:
        periodDays = 30; // Default to monthly
        periodDescription = 'Month';
    }
    
    // Calculate next payment date
    while (nextPaymentDate.isBefore(currentDate) && nextPaymentDate.isBefore(leaseEndDate)) {
      if (paymentFrequency.toLowerCase() == 'monthly') {
        // For monthly, add months instead of days for accuracy
        nextPaymentDate = DateTime(
          nextPaymentDate.year,
          nextPaymentDate.month + 1,
          nextPaymentDate.day,
        );
      } else if (paymentFrequency.toLowerCase() == 'quarterly') {
        // For quarterly, add 3 months
        nextPaymentDate = DateTime(
          nextPaymentDate.year,
          nextPaymentDate.month + 3,
          nextPaymentDate.day,
        );
      } else if (paymentFrequency.toLowerCase() == 'yearly') {
        // For yearly, add 1 year
        nextPaymentDate = DateTime(
          nextPaymentDate.year + 1,
          nextPaymentDate.month,
          nextPaymentDate.day,
        );
      } else {
        // For weekly, add days
        nextPaymentDate = nextPaymentDate.add(Duration(days: periodDays));
      }
      paymentCount++;
    }
    
    // Determine payment status
    String paymentStatus = 'pending';
    if (nextPaymentDate.isBefore(currentDate)) {
      final daysDifference = currentDate.difference(nextPaymentDate).inDays;
      if (daysDifference > 5) {
        paymentStatus = 'overdue';
      } else if (daysDifference >= 0) {
        paymentStatus = 'due_today';
      }
    }
    
    // Calculate total amount due for the period
    double totalAmountDue = rentAmount;
    
    return {
      'paymentFrequency': paymentFrequency,
      'periodDescription': periodDescription,
      'periodDays': periodDays,
      'nextPaymentDate': nextPaymentDate,
      'paymentStatus': paymentStatus,
      'rentAmount': rentAmount,
      'totalAmountDue': totalAmountDue,
      'paymentCount': paymentCount,
      'daysUntilDue': nextPaymentDate.difference(currentDate).inDays,
      'formattedNextPaymentDate': DateFormat('MMM dd, yyyy').format(nextPaymentDate),
      'isOverdue': paymentStatus == 'overdue',
      'isDueToday': paymentStatus == 'due_today',
      'isPending': paymentStatus == 'pending',
    };
  }
  
  // Get tenants with payment data
  Future<List<Map<String, dynamic>>> getTenantsWithPaymentData() async {
    List<Map<String, dynamic>> tenantsWithPaymentData = [];
    
    try {
      for (DocumentSnapshot tenant in tenants) {
        final tenantData = tenant.data() as Map<String, dynamic>;
        
        // Extract tenant information
        final String tenantId = tenant.id;
        final String firstName = tenantData['firstName'] ?? '';
        final String lastName = tenantData['lastName'] ?? '';
        final String email = tenantData['email'] ?? '';
        final String phone = tenantData['phone'] ?? '';
        final String propertyId = tenantData['propertyId'] ?? '';
        final String propertyName = tenantData['propertyName'] ?? '';
        final String unitNumber = tenantData['unitNumber'] ?? '';
        final double rentAmount = (tenantData['rentAmount'] is int) 
            ? (tenantData['rentAmount'] as int).toDouble() 
            : (tenantData['rentAmount'] ?? 0.0);
        
        // Get payment frequency from tenant data or default to monthly
        final String paymentFrequency = tenantData['paymentFrequency'] ?? 'monthly';
        
        // Get lease dates
        DateTime? leaseStartDate;
        DateTime? leaseEndDate;
        
        if (tenantData['leaseStartDate'] != null) {
          leaseStartDate = (tenantData['leaseStartDate'] as Timestamp).toDate();
        }
        
        if (tenantData['leaseEndDate'] != null) {
          leaseEndDate = (tenantData['leaseEndDate'] as Timestamp).toDate();
        }
        
        // Calculate payment data if lease dates are available
        Map<String, dynamic>? paymentData;
        if (leaseStartDate != null && leaseEndDate != null) {
          paymentData = calculatePaymentData(
            paymentFrequency: paymentFrequency,
            leaseStartDate: leaseStartDate,
            leaseEndDate: leaseEndDate,
            rentAmount: rentAmount,
          );
        }
        
        // Combine tenant and payment data
        tenantsWithPaymentData.add({
          'tenantId': tenantId,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': '$firstName $lastName',
          'email': email,
          'phone': phone,
          'propertyId': propertyId,
          'propertyName': propertyName,
          'unitNumber': unitNumber,
          'rentAmount': rentAmount,
          'paymentFrequency': paymentFrequency,
          'leaseStartDate': leaseStartDate,
          'leaseEndDate': leaseEndDate,
          'paymentData': paymentData,
          'tenantData': tenantData,
        });
      }
    } catch (e) {
      print('Error getting tenants with payment data: $e');
    }
    
    return tenantsWithPaymentData;
  }
  
  // Add a new tenant
  Future<String?> addTenant({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    // String? propertyId, // Made optional to support minimal tenant creation
    // String? unitNumber,
    // String? unitId,
    // DateTime? leaseStartDate,
    // DateTime? leaseEndDate,
    // int? rentAmount, // Changed to double for consistency
    // String? paymentFrequency,
    // int? rentDueDay,
    // int? securityDeposit, // Changed to double for consistency
    String? notes,
    String? accountHolderName,
    String? accountNumber,
    String? idType,
    String? idNumber,
    String? bankBic,
    String? branchCode,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return null;
      }
      
      final uid = _authController.firebaseUser.value!.uid;
      
      // Create tenant model
      final tenant = TenantModel(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        landlordId: uid,
        // propertyId: propertyId ?? '', // Default to empty string if null
        // propertyName: '', // This will be updated when we get property details
        // propertyAddress: '', // This will be updated when we get property details
        // unitNumber: unitNumber ?? '', // Default to empty string if null
        // unitId: unitId ?? '',
        // leaseStartDate: leaseStartDate ?? DateTime.now(), // Default to current date
        // leaseEndDate: leaseEndDate ?? DateTime.now().add(const Duration(days: 365)), // Default to 1 year
        // rentAmount: rentAmount ?? 0, // Default to 0
        // paymentFrequency: paymentFrequency ?? 'monthly', // Default to monthly
        // rentDueDay: rentDueDay ?? 1, // Default to 1st of month
        // securityDeposit: securityDeposit ?? 0, // Default to 0
        notes: notes ?? '', // Default to empty string
        accountHolderName: accountHolderName,
        accountNumber: accountNumber,
        idType: idType,
        idNumber: idNumber,
        bankBic: bankBic,
        branchCode: branchCode,
      );
      
      // Create tenant document via repository
      final tenantIdCreated = await _tenantRepository.createTenant(
        landlordId: uid,
        tenant: tenant,
      );

      successMessage.value = 'Tenant added successfully';
      await fetchTenants(forceRefresh: true); // Refresh tenants list

      return tenantIdCreated;
    } catch (e) {
      print(e);
      errorMessage.value = 'Failed to add tenant';
      print('Error adding tenant: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Update tenant
  Future<bool> updateTenant({
    required String tenantId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? propertyId,
    String? unitNumber,
    String? unitId,
    DateTime? leaseStartDate,
    DateTime? leaseEndDate,
    int? rentAmount, // Changed to double for consistency
    String? paymentFrequency,
    int? rentDueDay,
    int? securityDeposit, // Changed to double for consistency
    String? notes,
    String? status,
    bool? isArchived,
    String? accountHolderName,
    String? accountNumber,
    String? idType,
    String? idNumber,
    String? bankBic,
    String? branchCode,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      // Get current tenant data
      final tenantDoc = await getTenantById(tenantId);
      if (tenantDoc == null || !tenantDoc.exists) {
        errorMessage.value = 'Tenant not found';
        return false;
      }
      
      final tenantData = tenantDoc.data() as Map<String, dynamic>;
      
      // Create tenant model from existing data
      final tenant = TenantModel.fromFirestore(tenantDoc);
      
      // Create updated tenant model
      final updatedTenant = tenant.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        propertyId: propertyId,
        unitNumber: unitNumber,
        unitId: unitId,
        leaseStartDate: leaseStartDate,
        leaseEndDate: leaseEndDate,
        rentAmount: rentAmount,
        paymentFrequency: paymentFrequency,
        rentDueDay: rentDueDay,
        securityDeposit: securityDeposit,
        notes: notes,
        status: status,
        isArchived: isArchived,
        accountHolderName: accountHolderName,
        accountNumber: accountNumber,
        idType: idType,
        idNumber: idNumber,
        bankBic: bankBic,
        branchCode: branchCode,
      );
      
      // Update the document in users/{userId}/tenants subcollection
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return false;
      }
      
      final uid = _authController.firebaseUser.value!.uid;
      
      await _tenantRepository.updateTenant(
        landlordId: uid,
        tenantId: tenantId,
        data: updatedTenant.toFirestore(),
      );

      successMessage.value = 'Tenant updated successfully';
      await fetchTenants(forceRefresh: true); // Refresh tenants list

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update tenant';
      print('Error updating tenant: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Delete tenant from users/{userId}/tenants subcollection
  Future<bool> deleteTenant(String tenantId) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return false;
      }
      
      final uid = _authController.firebaseUser.value!.uid;
      
      // Delete the tenant document via repository
      await _tenantRepository.deleteTenant(
        landlordId: uid,
        tenantId: tenantId,
      );

      successMessage.value = 'Tenant deleted successfully';
      await fetchTenants(forceRefresh: true); // Refresh tenants list

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to delete tenant';
      print('Error deleting tenant: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Search and filter tenants
  void filterTenants(String searchTerm) {
    if (searchTerm.isEmpty) {
      filteredTenants.value = tenants;
      return;
    }
    
    final searchTermLower = searchTerm.toLowerCase();
    
    filteredTenants.value = tenants.where((tenant) {
      final data = tenant.data() as Map<String, dynamic>;
      
      // Check if tenant name, email, phone, or property contains search term
      final firstName = (data['firstName'] as String? ?? '').toLowerCase();
      final lastName = (data['lastName'] as String? ?? '').toLowerCase();
      final fullName = '$firstName $lastName'.toLowerCase();
      final email = (data['email'] as String? ?? '').toLowerCase();
      final phone = (data['phone'] as String? ?? '').toLowerCase();
      final propertyName = (data['propertyName'] as String? ?? '').toLowerCase();
      final unitNumber = (data['unitNumber'] as String? ?? '').toLowerCase();
      
      return fullName.contains(searchTermLower) || 
             email.contains(searchTermLower) ||
             phone.contains(searchTermLower) ||
             propertyName.contains(searchTermLower) ||
             unitNumber.contains(searchTermLower);
    }).toList();
  }
  
  // Filter tenants by property
  void filterTenantsByProperty(String propertyId) {
    if (propertyId.isEmpty) {
      filteredTenants.value = tenants;
      return;
    }
    
    filteredTenants.value = tenants.where((tenant) {
      final data = tenant.data() as Map<String, dynamic>;
      return data['propertyId'] == propertyId;
    }).toList();
  }
  
  // Count tenants
  int get tenantCount => tenants.length;
  
  // Count active tenants
  int get activeTenantCount {
    return tenants.where((tenant) {
      final data = tenant.data() as Map<String, dynamic>;
      return (data['status'] as String? ?? '') == 'active' && 
             (data['isArchived'] as bool? ?? false) == false;
    }).length;
  }
  
  // Get tenants by property
  List<DocumentSnapshot> getTenantsByProperty(String propertyId) {
    return tenants.where((tenant) {
      final data = tenant.data() as Map<String, dynamic>;
      return data['propertyId'] == propertyId;
    }).toList();
  }
  
  // Calculate total monthly rent
  int get totalMonthlyRent {
    int total = 0;
    
    for (final tenant in tenants) {
      final data = tenant.data() as Map<String, dynamic>;
      if ((data['status'] as String? ?? '') == 'active') {
        final rentAmount = (data['rentAmount'] as int? ?? 0);
        final paymentFrequency = data['paymentFrequency'] as String? ?? 'monthly';
        
        // Convert to monthly equivalent
        switch (paymentFrequency.toLowerCase()) {
          case 'weekly':
            total += rentAmount * 4; // Approximate weeks per month
            break;
          case 'monthly':
            total += rentAmount;
            break;
          case 'quarterly':
            total += (rentAmount / 3).toInt(); // Quarterly to monthly
            break;
          case 'yearly':
            total += (rentAmount / 12).toInt(); // Yearly to monthly
            break;
          default:
            total += rentAmount; // Default to monthly
        }
      }
    }
    
    return total;
  }
  
  // Get tenants with leases expiring in the next 30 days
  List<DocumentSnapshot> getTenantsWithExpiringLeases() {
    final now = DateTime.now();
    final thirtyDaysLater = now.add(const Duration(days: 30));
    
    return tenants.where((tenant) {
      final data = tenant.data() as Map<String, dynamic>;
      
      if ((data['status'] as String? ?? '') != 'active') {
        return false;
      }
      
      if (data['leaseEndDate'] == null) {
        return false;
      }
      
      try {
        final leaseEndDate = (data['leaseEndDate'] as Timestamp).toDate();
        return leaseEndDate.isAfter(now) && leaseEndDate.isBefore(thirtyDaysLater);
      } catch (e) {
        print('Error parsing lease end date: $e');
        return false;
      }
    }).toList();
  }
}