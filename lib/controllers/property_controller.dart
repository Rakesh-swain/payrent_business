import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  // Add a new property
  Future<void> addProperty({
    required String name,
    required String address,
    required String city,
    required String state,
    required String zipCode,
    required String type,
    required int units,
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
      
      // Create property document
      await _firestoreService.createDocument(
        collection: 'properties',
        data: {
          'name': name,
          'address': address,
          'city': city,
          'state': state,
          'zipCode': zipCode,
          'type': type,
          'units': units,
          'description': description,
          'images': images,
          'landlordId': uid,
          'isActive': true,
        },
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
  
  // Update property
  Future<void> updateProperty({
    required String propertyId,
    String? name,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? type,
    int? units,
    String? description,
    List<String>? images,
    bool? isActive,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      // Create map of non-null fields to update
      final Map<String, dynamic> updateData = {};
      
      if (name != null) updateData['name'] = name;
      if (address != null) updateData['address'] = address;
      if (city != null) updateData['city'] = city;
      if (state != null) updateData['state'] = state;
      if (zipCode != null) updateData['zipCode'] = zipCode;
      if (type != null) updateData['type'] = type;
      if (units != null) updateData['units'] = units;
      if (description != null) updateData['description'] = description;
      if (images != null) updateData['images'] = images;
      if (isActive != null) updateData['isActive'] = isActive;
      
      // Update the document
      await _firestoreService.updateDocument(
        collection: 'properties',
        documentId: propertyId,
        data: updateData,
      );
      
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
      count += (data['units'] as int? ?? 0);
    }
    
    return count;
  }
}
