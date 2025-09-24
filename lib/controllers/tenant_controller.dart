import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/property_controller.dart';
import '../services/firestore_service.dart';
import '../models/tenant_model.dart';
import '../models/property_model.dart';

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
  
  // Add a new tenant with support for unit assignment
  Future<void> addTenant({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String propertyId,
    required String unitNumber,
    String? unitId,
    required DateTime leaseStartDate,
    required DateTime leaseEndDate,
    required int rentAmount,
    required int rentDueDay,
    int? securityDeposit,
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
      
      // Find the correct unit if not provided
      String finalUnitId = unitId ?? '';
      if (unitId == null && propertyData['isMultiUnit'] == true && propertyData['units'] is List) {
        final units = (propertyData['units'] as List).map((unit) => PropertyUnitModel.fromMap(unit)).toList();
        final matchingUnit = units.firstWhere(
          (unit) => unit.unitNumber == unitNumber,
          orElse: () => units.isEmpty ? PropertyUnitModel(
            unitNumber: unitNumber,
            unitType: 'Unknown',
            bedrooms: 0,
            bathrooms: 0,
            rent: rentAmount,
            paymentFrequency: 'Monthly',
          ) : units.first
        );
        finalUnitId = matchingUnit.unitId;
      }
      
      // Create tenant model
      final tenant = TenantModel(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        landlordId: uid,
        propertyId: propertyId,
        propertyName: propertyName,
        propertyAddress: propertyAddress,
        unitNumber: unitNumber,
        unitId: finalUnitId,
        leaseStartDate: leaseStartDate,
        leaseEndDate: leaseEndDate,
        rentAmount: rentAmount,
        rentDueDay: rentDueDay,
        securityDeposit: securityDeposit,
        notes: notes,
      );
      
      // Create tenant document
      final tenantRef = await _firestoreService.createDocument(
        collection: 'tenants',
        data: tenant.toFirestore(),
      );
      
      // Update property unit with tenant ID if it's a multi-unit property
      if (propertyData['isMultiUnit'] == true && finalUnitId.isNotEmpty) {
        // Get current units
        List<PropertyUnitModel> units = [];
        if (propertyData['units'] != null && propertyData['units'] is List) {
          units = (propertyData['units'] as List).map((unit) => PropertyUnitModel.fromMap(unit)).toList();
          
          // Find and update the matching unit with tenant ID
          for (int i = 0; i < units.length; i++) {
            if (units[i].unitId == finalUnitId) {
              units[i] = PropertyUnitModel(
                unitId: units[i].unitId,
                unitNumber: units[i].unitNumber,
                unitType: units[i].unitType,
                bedrooms: units[i].bedrooms,
                bathrooms: units[i].bathrooms,
                rent: units[i].rent,
                securityDeposit: units[i].securityDeposit,
                tenantId: tenantRef.id, // Assign tenant ID to unit
                notes: units[i].notes,
              );
              break;
            }
          }
          
          // Update property with modified units
          await _propertyController.updateProperty(
            propertyId: propertyId,
            units: units,
          );
        }
      }
      
      successMessage.value = 'Tenant added successfully';
      fetchTenants(); // Refresh tenants list
    } catch (e) {
      errorMessage.value = 'Failed to add tenant';
      print('Error adding tenant: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Update tenant with support for unit assignment
  Future<void> updateTenant({
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
    int? rentAmount,
    int? rentDueDay,
    int? securityDeposit,
    String? notes,
    String? status,
    bool? isArchived,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      // Get current tenant data
      final tenantDoc = await getTenantById(tenantId);
      if (tenantDoc == null || !tenantDoc.exists) {
        errorMessage.value = 'Tenant not found';
        return;
      }
      
      final tenantData = tenantDoc.data() as Map<String, dynamic>;
      final currentPropertyId = tenantData['propertyId'] as String;
      final currentUnitId = tenantData['unitId'] as String?;
      
      // If changing property or unit, handle the relationship updates
      if ((propertyId != null && propertyId != currentPropertyId) || 
          (unitId != null && unitId != currentUnitId) ||
          (unitNumber != null && unitNumber != tenantData['unitNumber'])) {
        
        // If we have a current unit assignment, clear it
        if (currentUnitId != null && currentUnitId.isNotEmpty) {
          final currentProperty = await _propertyController.getPropertyById(currentPropertyId);
          if (currentProperty != null && currentProperty.exists) {
            final propertyData = currentProperty.data() as Map<String, dynamic>;
            if (propertyData['isMultiUnit'] == true && propertyData['units'] is List) {
              List<PropertyUnitModel> units = (propertyData['units'] as List)
                  .map((unit) => PropertyUnitModel.fromMap(unit))
                  .toList();
              
              // Find and clear tenant ID from the unit
              for (int i = 0; i < units.length; i++) {
                if (units[i].unitId == currentUnitId) {
                  units[i] = units[i].copyWith(tenantId: null);
                  break;
                }
              }
              
              // Update the property with modified units
              await _propertyController.updateProperty(
                propertyId: currentPropertyId,
                units: units,
              );
            }
          }
        }
        
        // If assigning to a new unit, update the property
        if (propertyId != null || unitId != null || unitNumber != null) {
          final targetPropertyId = propertyId ?? currentPropertyId;
          String targetUnitId = unitId ?? '';
          
          final targetProperty = await _propertyController.getPropertyById(targetPropertyId);
          if (targetProperty != null && targetProperty.exists) {
            final propertyData = targetProperty.data() as Map<String, dynamic>;
            
            // If we need to find the unit ID from the unit number
            if (unitId == null && unitNumber != null && propertyData['isMultiUnit'] == true && propertyData['units'] is List) {
              final units = (propertyData['units'] as List)
                  .map((unit) => PropertyUnitModel.fromMap(unit))
                  .toList();
              
              final matchingUnit = units.firstWhere(
                (unit) => unit.unitNumber == unitNumber,
                orElse: () => units.isEmpty ? PropertyUnitModel(
                  unitNumber: unitNumber,
                  unitType: 'Unknown',
                  bedrooms: 0,
                  bathrooms: 0,
                  rent: rentAmount ?? 0,
                  paymentFrequency: 'Monthly',
                ) : units.first
              );
              
              targetUnitId = matchingUnit.unitId;
            }
            
            // Update unit with tenant ID
            if (targetUnitId.isNotEmpty && propertyData['isMultiUnit'] == true && propertyData['units'] is List) {
              List<PropertyUnitModel> units = (propertyData['units'] as List)
                  .map((unit) => PropertyUnitModel.fromMap(unit))
                  .toList();
              
              // Find and update the matching unit with tenant ID
              for (int i = 0; i < units.length; i++) {
                if (units[i].unitId == targetUnitId) {
                  units[i] = units[i].copyWith(tenantId: tenantId);
                  break;
                }
              }
              
              // Update the property with modified units
              await _propertyController.updateProperty(
                propertyId: targetPropertyId,
                units: units,
              );
            }
            
            // If property changed, update property details in tenant record
            if (propertyId != null && propertyId != currentPropertyId) {
              firstName = firstName ?? tenantData['firstName'];
              lastName = lastName ?? tenantData['lastName'];
            }
          }
        }
      }
      
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
        rentDueDay: rentDueDay,
        securityDeposit: securityDeposit,
        notes: notes,
        status: status,
        isArchived: isArchived,
      );
      
      // Update the document
      await _firestoreService.updateDocument(
        collection: 'tenants',
        documentId: tenantId,
        data: updatedTenant.toFirestore(),
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
  
  // Delete tenant and clear unit relationship
  Future<void> deleteTenant(String tenantId) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      // Get tenant data first
      final tenantDoc = await getTenantById(tenantId);
      if (tenantDoc == null || !tenantDoc.exists) {
        errorMessage.value = 'Tenant not found';
        return;
      }
      
      final tenantData = tenantDoc.data() as Map<String, dynamic>;
      final propertyId = tenantData['propertyId'] as String;
      final unitId = tenantData['unitId'] as String?;
      
      // If tenant is assigned to a unit, clear the relationship
      if (unitId != null && unitId.isNotEmpty) {
        // Get the property
        final propertyDoc = await _propertyController.getPropertyById(propertyId);
        if (propertyDoc != null && propertyDoc.exists) {
          final propertyData = propertyDoc.data() as Map<String, dynamic>;
          
          if (propertyData['isMultiUnit'] == true && propertyData['units'] is List) {
            List<PropertyUnitModel> units = (propertyData['units'] as List)
                .map((unit) => PropertyUnitModel.fromMap(unit))
                .toList();
            
            // Find and clear tenant ID from the unit
            bool unitUpdated = false;
            for (int i = 0; i < units.length; i++) {
              if (units[i].unitId == unitId) {
                units[i] = units[i].copyWith(tenantId: null);
                unitUpdated = true;
                break;
              }
            }
            
            // Update the property if a unit was modified
            if (unitUpdated) {
              await _propertyController.updateProperty(
                propertyId: propertyId,
                units: units,
              );
            }
          }
        }
      }
      
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
