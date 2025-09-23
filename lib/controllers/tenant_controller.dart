import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/property_controller.dart';
import '../services/firestore_service.dart';

class TenantController extends GetxController {
  static TenantController get to => Get.find();
  
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final PropertyController _propertyController = Get.find<PropertyController>();
  
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
  
  // Fetch tenants for current landlord
  Future<void> fetchTenants() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }
      
      final uid = _authController.firebaseUser.value!.uid;
      
      // Query tenants where landlordId equals current user's ID
      final querySnapshot = await _firestoreService.queryDocuments(
        collection: 'tenants',
        filters: [
          ['landlordId', uid],
        ],
      );
      
      tenants.value = querySnapshot.docs;
      filteredTenants.value = querySnapshot.docs;
    } catch (e) {
      errorMessage.value = 'Failed to fetch tenants';
      print('Error fetching tenants: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Add a new tenant
  Future<void> addTenant({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String propertyId,
    required String unitNumber,
    required DateTime leaseStartDate,
    required DateTime leaseEndDate,
    required double rentAmount,
    required int rentDueDay,
    String? notes,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }
      
      final uid = _authController.firebaseUser.value!.uid;
      
      // Get property details
      final property = await _propertyController.getPropertyById(propertyId);
      
      if (property == null || !property.exists) {
        errorMessage.value = 'Invalid property selected';
        return;
      }
      
      final propertyData = property.data() as Map<String, dynamic>;
      final propertyName = propertyData['name'] as String? ?? '';
      final propertyAddress = propertyData['address'] as String? ?? '';
      
      // Create tenant document
      await _firestoreService.createDocument(
        collection: 'tenants',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'landlordId': uid,
          'propertyId': propertyId,
          'propertyName': propertyName,
          'propertyAddress': propertyAddress,
          'unitNumber': unitNumber,
          'leaseStartDate': Timestamp.fromDate(leaseStartDate),
          'leaseEndDate': Timestamp.fromDate(leaseEndDate),
          'rentAmount': rentAmount,
          'rentDueDay': rentDueDay,
          'notes': notes,
          'status': 'active',
          'isArchived': false,
        },
      );
      
      successMessage.value = 'Tenant added successfully';
      fetchTenants(); // Refresh tenants list
    } catch (e) {
      errorMessage.value = 'Failed to add tenant';
      print('Error adding tenant: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Update tenant
  Future<void> updateTenant({
    required String tenantId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? unitNumber,
    DateTime? leaseStartDate,
    DateTime? leaseEndDate,
    double? rentAmount,
    int? rentDueDay,
    String? notes,
    String? status,
    bool? isArchived,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      // Create map of non-null fields to update
      final Map<String, dynamic> updateData = {};
      
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (unitNumber != null) updateData['unitNumber'] = unitNumber;
      if (leaseStartDate != null) updateData['leaseStartDate'] = Timestamp.fromDate(leaseStartDate);
      if (leaseEndDate != null) updateData['leaseEndDate'] = Timestamp.fromDate(leaseEndDate);
      if (rentAmount != null) updateData['rentAmount'] = rentAmount;
      if (rentDueDay != null) updateData['rentDueDay'] = rentDueDay;
      if (notes != null) updateData['notes'] = notes;
      if (status != null) updateData['status'] = status;
      if (isArchived != null) updateData['isArchived'] = isArchived;
      
      // Update the document
      await _firestoreService.updateDocument(
        collection: 'tenants',
        documentId: tenantId,
        data: updateData,
      );
      
      successMessage.value = 'Tenant updated successfully';
      fetchTenants(); // Refresh tenants list
    } catch (e) {
      errorMessage.value = 'Failed to update tenant';
      print('Error updating tenant: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Delete tenant
  Future<void> deleteTenant(String tenantId) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      // Delete the tenant document
      await _firestoreService.deleteDocument(
        collection: 'tenants',
        documentId: tenantId,
      );
      
      successMessage.value = 'Tenant deleted successfully';
      fetchTenants(); // Refresh tenants list
    } catch (e) {
      errorMessage.value = 'Failed to delete tenant';
      print('Error deleting tenant: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Archive tenant
  Future<void> archiveTenant(String tenantId) async {
    await updateTenant(
      tenantId: tenantId,
      isArchived: true,
      status: 'archived',
    );
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
  
  // Get tenant by ID
  Future<DocumentSnapshot?> getTenantById(String tenantId) async {
    try {
      final doc = await _firestoreService.getDocument(
        collection: 'tenants',
        documentId: tenantId,
      );
      
      return doc;
    } catch (e) {
      errorMessage.value = 'Failed to get tenant';
      print('Error getting tenant: $e');
      return null;
    }
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
  double get totalMonthlyRent {
    double total = 0.0;
    
    for (final tenant in tenants) {
      final data = tenant.data() as Map<String, dynamic>;
      if ((data['status'] as String? ?? '') == 'active') {
        total += (data['rentAmount'] as double? ?? 0.0);
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
