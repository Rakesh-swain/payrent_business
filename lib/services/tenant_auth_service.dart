import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class TenantAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Check if phone number exists in any user's tenant subcollection
  /// Returns a Map with tenant data if found, null if not found
  Future<Map<String, dynamic>?> checkTenantByPhoneNumber(String phoneNumber) async {
    try {
      // Remove any non-numeric characters from phone number
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      
      print('Checking phone number: $cleanPhone');
      
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Search through each user's tenant subcollection
      for (final userDoc in usersSnapshot.docs) {
        try {
          // Get tenant subcollection for this user
          final tenantSnapshot = await _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('tenants')
              .get();
          
          // Check each tenant document
          for (final tenantDoc in tenantSnapshot.docs) {
            final tenantData = tenantDoc.data();
            final tenantPhone = tenantData['phone']?.toString() ?? '';
            
            print('Checking tenant ${tenantDoc.id}: $tenantPhone');
            
            // If phone numbers match, return tenant data with additional info
            if (tenantPhone == cleanPhone) {
              print('Phone number found in tenant: ${tenantDoc.id}');
              
              return {
                'tenantId': tenantDoc.id,
                'landlordId': userDoc.id,
                'tenantData': tenantData,
                'landlordData': userDoc.data(),
              };
            }
          }
        } catch (e) {
          print('Error checking tenants for user ${userDoc.id}: $e');
          continue; // Skip this user if there's an error
        }
      }
      
      print('Phone number not found in any tenant records');
      return null;
    } catch (e) {
      print('Error checking tenant by phone number: $e');
      throw Exception('Failed to verify phone number: $e');
    }
  }
  
  /// Get tenant data by landlord ID and tenant ID
  Future<Map<String, dynamic>?> getTenantData(String landlordId, String tenantId) async {
    try {
      final tenantDoc = await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('tenants')
          .doc(tenantId)
          .get();
      
      if (tenantDoc.exists) {
        return {
          'tenantId': tenantDoc.id,
          'landlordId': landlordId,
          'tenantData': tenantDoc.data(),
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting tenant data: $e');
      throw Exception('Failed to get tenant data: $e');
    }
  }
  
  /// Get tenant's property details
  Future<List<Map<String, dynamic>>> getTenantProperties(String landlordId, String tenantId) async {
    try {
      // Get tenant data
      final tenantDoc = await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('tenants')
          .doc(tenantId)
          .get();
      
      if (!tenantDoc.exists) {
        return [];
      }
      
      final tenantData = tenantDoc.data()!;
      final propertyId = tenantData['propertyId'];
      
      if (propertyId == null) {
        return [];
      }
      
      // Get property details
      final propertyDoc = await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('properties')
          .doc(propertyId)
          .get();
      
      if (propertyDoc.exists) {
        final propertyData = propertyDoc.data()!;
        final unitId = tenantData['unitId'];
        final unitNumber = tenantData['unitNumber'];
        
        // Find the specific unit if it's a multi-unit property
        Map<String, dynamic>? unitDetails;
        if (propertyData['isMultiUnit'] == true && propertyData['units'] != null) {
          final units = propertyData['units'] as List;
          for (final unit in units) {
            final unitData = unit as Map<String, dynamic>;
            if ((unitId != null && unitData['id'] == unitId) ||
                (unitNumber != null && unitData['unitNumber'] == unitNumber)) {
              unitDetails = unitData;
              break;
            }
          }
        }
        
        return [{
          'propertyId': propertyDoc.id,
          'propertyData': propertyData,
          'unitDetails': unitDetails,
          'tenantData': tenantData,
        }];
      }
      
      return [];
    } catch (e) {
      print('Error getting tenant properties: $e');
      throw Exception('Failed to get tenant properties: $e');
    }
  }
  
  /// Get tenant's payment history
  Future<List<Map<String, dynamic>>> getTenantPayments(String landlordId, String tenantId) async {
    try {
      final paymentsSnapshot = await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('payments')
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('dueDate', descending: true)
          .get();
      
      return paymentsSnapshot.docs.map((doc) => {
        'paymentId': doc.id,
        'paymentData': doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting tenant payments: $e');
      throw Exception('Failed to get tenant payments: $e');
    }
  }
  
  /// Get tenant's maintenance requests
  Future<List<Map<String, dynamic>>> getTenantMaintenanceRequests(String landlordId, String tenantId) async {
    try {
      // Check if maintenance collection exists
      final maintenanceSnapshot = await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('maintenance')
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return maintenanceSnapshot.docs.map((doc) => {
        'maintenanceId': doc.id,
        'maintenanceData': doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting tenant maintenance requests: $e');
      // Return empty list if maintenance collection doesn't exist
      return [];
    }
  }
  
  /// Get landlord contact information
  Future<Map<String, dynamic>?> getLandlordInfo(String landlordId) async {
    try {
      final landlordDoc = await _firestore
          .collection('users')
          .doc(landlordId)
          .get();
      
      if (landlordDoc.exists) {
        final data = landlordDoc.data()!;
        return {
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
          'email': data['email'],
          'phone': data['phone'],
          'profileImage': data['profileImage'],
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting landlord info: $e');
      throw Exception('Failed to get landlord info: $e');
    }
  }
}