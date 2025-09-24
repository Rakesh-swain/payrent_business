﻿import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';
import '../models/property_model.dart';

class PropertyController extends GetxController {
  static PropertyController get to => Get.find();
  
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  
  // Observables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxList<DocumentSnapshot> properties = <DocumentSnapshot>[].obs;
  final RxList<DocumentSnapshot> filteredProperties = <DocumentSnapshot>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchProperties();
  }
  
  // Fetch properties for current landlord
  Future<void> fetchProperties() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }
      
      final uid = _authController.firebaseUser.value!.uid;
      
      // Query properties where landlordId equals current user's ID
      final querySnapshot = await _firestoreService.queryDocuments(
        collection: 'properties',
        filters: [
          ['landlordId', uid],
        ],
      );
      
      properties.value = querySnapshot.docs;
      filteredProperties.value = querySnapshot.docs;
    } catch (e) {
      errorMessage.value = 'Failed to fetch properties';
      print('Error fetching properties: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Add a new property with support for multi-unit properties
  Future<void> addProperty({
    required String name,
    required String address,
    required String city,
    required String state,
    required String zipCode,
    required String type,
    required bool isMultiUnit,
    required List<PropertyUnitModel> units,
    String? description,
    List<String>? images,
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
      
      // Create property model
      final PropertyModel property = PropertyModel(
        name: name,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        type: type,
        isMultiUnit: isMultiUnit,
        units: units,
        landlordId: uid,
        description: description,
        images: images,
        isActive: true,
      );
      
      // Create property document
      await _firestoreService.createDocument(
        collection: 'properties',
        data: property.toFirestore(),
      );
      
      successMessage.value = 'Property added successfully';
      fetchProperties(); // Refresh properties list
    } catch (e) {
      errorMessage.value = 'Failed to add property';
      print('Error adding property: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Update property with support for multi-unit properties
  Future<void> updateProperty({
    required String propertyId,
    String? name,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? type,
    bool? isMultiUnit,
    List<PropertyUnitModel>? units,
    String? description,
    List<String>? images,
    bool? isActive,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      // Get current property data
      final propertyDoc = await getPropertyById(propertyId);
      if (propertyDoc == null || !propertyDoc.exists) {
        errorMessage.value = 'Property not found';
        return;
      }
      
      // Create a property model from existing data
      final existingProperty = PropertyModel.fromFirestore(propertyDoc);
      
      // Create an updated property model
      final updatedProperty = existingProperty.copyWith(
        name: name,
        address: address,
        city: city,
        state: state,
        zipCode: zipCode,
        type: type,
        isMultiUnit: isMultiUnit,
        units: units,
        description: description,
        images: images,
        isActive: isActive,
      );
      
      // Create map of fields to update
      final Map<String, dynamic> updateData = updatedProperty.toFirestore();
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Update the document
      await _firestoreService.updateDocument(
        collection: 'properties',
        documentId: propertyId,
        data: updateData,
      );
      
      // If units were updated and property has tenants, update tenant property info
      if (units != null) {
        // Find all tenants for this property
        final tenantQuery = await _firestoreService.queryDocuments(
          collection: 'tenants',
          filters: [
            ['propertyId', propertyId],
          ],
        );
        
        if (tenantQuery.docs.isNotEmpty) {
          // Update each tenant with new property details
          for (var tenant in tenantQuery.docs) {
            final tenantData = tenant.data() as Map<String, dynamic>;
            final unitId = tenantData['unitId'];
            
            // Find the tenant's unit in the updated units list
            final matchingUnit = unitId != null 
              ? units.firstWhere((unit) => unit.unitId == unitId, orElse: () => units.first)
              : null;
            
            if (matchingUnit != null) {
              // Update tenant document with new property details
              await _firestoreService.updateDocument(
                collection: 'tenants',
                documentId: tenant.id,
                data: {
                  'propertyName': name ?? existingProperty.name,
                  'propertyAddress': address ?? existingProperty.address,
                  'updatedAt': FieldValue.serverTimestamp(),
                },
              );
            }
          }
        }
      }
      
      successMessage.value = 'Property updated successfully';
      fetchProperties(); // Refresh properties list
    } catch (e) {
      errorMessage.value = 'Failed to update property';
      print('Error updating property: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Delete property
  Future<void> deleteProperty(String propertyId) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      // Delete the property document
      await _firestoreService.deleteDocument(
        collection: 'properties',
        documentId: propertyId,
      );
      
      successMessage.value = 'Property deleted successfully';
      fetchProperties(); // Refresh properties list
    } catch (e) {
      errorMessage.value = 'Failed to delete property';
      print('Error deleting property: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Search and filter properties
  void filterProperties(String searchTerm) {
    if (searchTerm.isEmpty) {
      filteredProperties.value = properties;
      return;
    }
    
    final searchTermLower = searchTerm.toLowerCase();
    
    filteredProperties.value = properties.where((property) {
      final data = property.data() as Map<String, dynamic>;
      
      // Check if property name or address contains search term
      final name = data['name'].toString().toLowerCase();
      final address = data['address'].toString().toLowerCase();
      final city = data['city'].toString().toLowerCase();
      final state = data['state'].toString().toLowerCase();
      
      return name.contains(searchTermLower) || 
             address.contains(searchTermLower) ||
             city.contains(searchTermLower) ||
             state.contains(searchTermLower);
    }).toList();
  }
  
  // Get property by ID
  Future<DocumentSnapshot?> getPropertyById(String propertyId) async {
    try {
      final doc = await _firestoreService.getDocument(
        collection: 'properties',
        documentId: propertyId,
      );
      
      return doc;
    } catch (e) {
      errorMessage.value = 'Failed to get property';
      print('Error getting property: $e');
      return null;
    }
  }
  
  // Count properties
  int get propertyCount => properties.length;
  
  // Get property types count
  Map<String, int> getPropertyTypeCounts() {
    final Map<String, int> typeCounts = {};
    
    for (final property in properties) {
      final data = property.data() as Map<String, dynamic>;
      final type = data['type'] as String? ?? 'Unknown';
      
      if (typeCounts.containsKey(type)) {
        typeCounts[type] = typeCounts[type]! + 1;
      } else {
        typeCounts[type] = 1;
      }
    }
    
    return typeCounts;
  }
  
  // Get total units count
  int get totalUnits {
    int count = 0;
    
    for (final property in properties) {
      final data = property.data() as Map<String, dynamic>;
      
      // Check if property is multi-unit
      bool isMultiUnit = data['isMultiUnit'] ?? false;
      
      if (isMultiUnit && data['units'] != null) {
        // Count units in the units array
        count += (data['units'] as List).length;
      } else {
        // For single unit properties, count as 1
        count += 1;
      }
    }
    
    return count;
  }
  
  // Get units for a specific property
  List<PropertyUnitModel> getPropertyUnits(String propertyId) {
    try {
      final propertyIndex = properties.indexWhere((prop) => prop.id == propertyId);
      
      if (propertyIndex == -1) return [];
      
      final propertyData = properties[propertyIndex].data() as Map<String, dynamic>;
      
      // Check if it's a multi-unit property
      final isMultiUnit = propertyData['isMultiUnit'] ?? false;
      
      if (!isMultiUnit) {
        // For single unit properties, return a default unit
        return [
          PropertyUnitModel(
            unitNumber: "Main",
            unitType: propertyData['type'] ?? 'Single Family',
            bedrooms: propertyData['bedrooms'] ?? 0,
            bathrooms: propertyData['bathrooms'] ?? 0,
            monthlyRent: propertyData['monthlyRent'] != null 
                ? (propertyData['monthlyRent']).toDouble() 
                : 0.0,
          )
        ];
      }
      
      // For multi-unit properties
      if (propertyData['units'] != null && propertyData['units'] is List) {
        final unitsList = propertyData['units'] as List;
        return unitsList.map((unit) => PropertyUnitModel.fromMap(unit)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting property units: $e');
      return [];
    }
  }
  
  // Get vacant units (units without tenants)
  List<PropertyUnitModel> getVacantUnits(String propertyId) {
    final units = getPropertyUnits(propertyId);
    return units.where((unit) => unit.tenantId == null).toList();
  }
  
  // Get occupied units (units with tenants)
  List<PropertyUnitModel> getOccupiedUnits(String propertyId) {
    final units = getPropertyUnits(propertyId);
    return units.where((unit) => unit.tenantId != null).toList();
  }
  
  // Add a unit to a property
  Future<void> addUnitToProperty(String propertyId, PropertyUnitModel unit) async {
    try {
      // Get property data
      final propertyDoc = await getPropertyById(propertyId);
      if (propertyDoc == null || !propertyDoc.exists) {
        errorMessage.value = 'Property not found';
        return;
      }
      
      final propertyData = propertyDoc.data() as Map<String, dynamic>;
      List<PropertyUnitModel> currentUnits = [];
      
      // Get current units
      if (propertyData['units'] != null && propertyData['units'] is List) {
        currentUnits = (propertyData['units'] as List)
            .map((unit) => PropertyUnitModel.fromMap(unit))
            .toList();
      }
      
      // Add new unit
      currentUnits.add(unit);
      
      // Update property
      await updateProperty(
        propertyId: propertyId,
        isMultiUnit: true,
        units: currentUnits,
      );
      
      successMessage.value = 'Unit added successfully';
    } catch (e) {
      errorMessage.value = 'Failed to add unit';
      print('Error adding unit: $e');
    }
  }
}
