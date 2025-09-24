﻿import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';

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
  
  // Get properties with payment data
  Future<List<Map<String, dynamic>>> getPropertiesWithPaymentData() async {
    List<Map<String, dynamic>> propertiesWithPaymentData = [];
    
    try {
      for (DocumentSnapshot property in properties) {
        final propertyData = property.data() as Map<String, dynamic>;
        
        // Extract property information
        final String propertyId = property.id;
        final String name = propertyData['name'] ?? 'Unnamed Property';
        final String address = propertyData['address'] ?? '';
        final String city = propertyData['city'] ?? '';
        final String state = propertyData['state'] ?? '';
        final String zipCode = propertyData['zipCode'] ?? '';
        final String type = propertyData['type'] ?? '';
        final bool isMultiUnit = propertyData['isMultiUnit'] ?? false;
        final String paymentFrequency = propertyData['paymentFrequency'] ?? 'monthly';
        
        // Calculate total rent and units
        double totalRent = 0.0;
        int totalUnits = 0;
        int occupiedUnits = 0;
        
        if (isMultiUnit && propertyData['units'] is List) {
          final units = propertyData['units'] as List;
          totalUnits = units.length;
          
          for (final unit in units) {
            final rentAmount = unit['rent'] != null 
                ? (unit['rent'] is int 
                    ? (unit['rent'] as int).toDouble() 
                    : unit['rent']) 
                : 0.0;
            totalRent += rentAmount;
            
            if (unit['tenantId'] != null && unit['tenantId'].toString().isNotEmpty) {
              occupiedUnits++;
            }
          }
        } else {
          // Single unit property
          totalUnits = 1;
          final rentAmount = propertyData['rent'] != null 
              ? (propertyData['rent'] is int 
                  ? (propertyData['rent'] as int).toDouble() 
                  : propertyData['rent']) 
              : 0.0;
          totalRent = rentAmount;
          
          // Check if there's a tenant assigned (you may need to check tenants collection)
          // For now, we'll assume single unit properties can have 0 or 1 tenant
          occupiedUnits = 0; // This can be updated based on tenant data
        }
        
        // Calculate occupancy rate
        double occupancyRate = totalUnits > 0 ? (occupiedUnits / totalUnits) * 100 : 0.0;
        
        // Convert rent to monthly equivalent based on payment frequency
        double monthlyEquivalentRent = totalRent;
        switch (paymentFrequency.toLowerCase()) {
          case 'weekly':
            monthlyEquivalentRent = totalRent * 4.33; // Approximate weeks per month
            break;
          case 'monthly':
            monthlyEquivalentRent = totalRent;
            break;
          case 'quarterly':
            monthlyEquivalentRent = totalRent / 3; // Quarterly to monthly
            break;
          case 'yearly':
            monthlyEquivalentRent = totalRent / 12; // Yearly to monthly
            break;
          default:
            monthlyEquivalentRent = totalRent; // Default to monthly
        }
        
        // Combine property and payment data
        propertiesWithPaymentData.add({
          'propertyId': propertyId,
          'name': name,
          'address': address,
          'city': city,
          'state': state,
          'zipCode': zipCode,
          'fullAddress': [address, city, state, zipCode].where((s) => s.isNotEmpty).join(', '),
          'type': type,
          'isMultiUnit': isMultiUnit,
          'paymentFrequency': paymentFrequency,
          'totalUnits': totalUnits,
          'occupiedUnits': occupiedUnits,
          'vacantUnits': totalUnits - occupiedUnits,
          'totalRent': totalRent,
          'monthlyEquivalentRent': monthlyEquivalentRent,
          'occupancyRate': occupancyRate,
          'propertyData': propertyData,
        });
      }
    } catch (e) {
      print('Error getting properties with payment data: $e');
    }
    
    return propertiesWithPaymentData;
  }
  
  // Calculate total expected monthly rent for all properties
  double get totalExpectedMonthlyRent {
    double total = 0.0;
    
    for (final property in properties) {
      final data = property.data() as Map<String, dynamic>;
      final bool isMultiUnit = data['isMultiUnit'] ?? false;
      final String paymentFrequency = data['paymentFrequency'] ?? 'monthly';
      
      if (isMultiUnit && data['units'] is List) {
        // Multi-unit property
        final units = data['units'] as List;
        for (final unit in units) {
          final rentAmount = unit['rent'] != null 
              ? (unit['rent'] is int 
                  ? (unit['rent'] as int).toDouble() 
                  : unit['rent']) 
              : 0.0;
          
          // Convert to monthly equivalent based on payment frequency
          switch (paymentFrequency.toLowerCase()) {
            case 'weekly':
              total += rentAmount * 4.33; // Approximate weeks per month
              break;
            case 'monthly':
              total += rentAmount;
              break;
            case 'quarterly':
              total += rentAmount / 3; // Quarterly to monthly
              break;
            case 'yearly':
              total += rentAmount / 12; // Yearly to monthly
              break;
            default:
              total += rentAmount; // Default to monthly
          }
        }
      } else {
        // Single unit property
        final rentAmount = data['rent'] != null 
            ? (data['rent'] is int 
                ? (data['rent'] as int).toDouble() 
                : data['rent']) 
            : 0.0;
        
        // Convert to monthly equivalent based on payment frequency
        switch (paymentFrequency.toLowerCase()) {
          case 'weekly':
            total += rentAmount * 4.33; // Approximate weeks per month
            break;
          case 'monthly':
            total += rentAmount;
            break;
          case 'quarterly':
            total += rentAmount / 3; // Quarterly to monthly
            break;
          case 'yearly':
            total += rentAmount / 12; // Yearly to monthly
            break;
          default:
            total += rentAmount; // Default to monthly
        }
      }
    }
    
    return total;
  }
}
