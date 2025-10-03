import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TenantAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if phone number exists as a tenant across all landlords
  /// Returns tenant info if found, null otherwise
  Future<Map<String, dynamic>?> checkTenantExists(String phoneNumber) async {
    try {
      // First, get all users (landlords)
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Check each landlord's tenants subcollection
      for (var userDoc in usersSnapshot.docs) {
        final tenantsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('tenants')
            .where('phone', isEqualTo: phoneNumber)
            .get();
        
        if (tenantsSnapshot.docs.isNotEmpty) {
          // Tenant found - return tenant info with landlord ID
          final tenantData = tenantsSnapshot.docs.first.data();
          return {
            'landlordId': userDoc.id,
            'tenantId': tenantsSnapshot.docs.first.id,
            'tenantData': tenantData,
            'landlordData': userDoc.data(),
          };
        }
      }
      
      return null; // No tenant found with this phone number
    } catch (e) {
      print('Error checking tenant existence: $e');
      return null;
    }
  }

  /// Get tenant data by phone number and landlord ID (for faster lookup if we know the landlord)
  Future<Map<String, dynamic>?> getTenantByPhoneAndLandlord(String phoneNumber, String landlordId) async {
    try {
      final tenantSnapshot = await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('tenants')
          .where('phone', isEqualTo: phoneNumber)
          .get();
      
      if (tenantSnapshot.docs.isNotEmpty) {
        return {
          'tenantId': tenantSnapshot.docs.first.id,
          'tenantData': tenantSnapshot.docs.first.data(),
        };
      }
      
      return null;
    } catch (e) {
      print('Error fetching tenant data: $e');
      return null;
    }
  }

  /// Get all tenant data including assigned properties
  Future<Map<String, dynamic>?> getTenantFullData(String landlordId, String tenantId) async {
    try {
      // Get tenant basic info
      final tenantDoc = await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('tenants')
          .doc(tenantId)
          .get();
      
      if (!tenantDoc.exists) {
        return null;
      }
      
      final tenantData = tenantDoc.data()!;
      
      // Get properties assigned to this tenant
      List<Map<String, dynamic>> assignedProperties = [];
      
      // Get all properties of the landlord
      final propertiesSnapshot = await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('properties')
          .get();
      
      // Filter properties where this tenant is assigned
      for (var propertyDoc in propertiesSnapshot.docs) {
        final propertyData = propertyDoc.data();
        
        // Check if tenant is directly assigned to single-unit property
        if (propertyData['tenantId'] == tenantId) {
          assignedProperties.add({
            'propertyId': propertyDoc.id,
            ...propertyData,
          });
        }
        
        // Check multi-unit properties
        if (propertyData['isMultiUnit'] == true && propertyData['units'] != null) {
          final units = propertyData['units'] as List<dynamic>;
          for (var unit in units) {
            if (unit['tenantId'] == tenantId) {
              assignedProperties.add({
                'propertyId': propertyDoc.id,
                'unitNumber': unit['unitNumber'],
                'propertyName': propertyData['name'],
                'address': propertyData['address'],
                'city': propertyData['city'],
                'state': propertyData['state'],
                'rentAmount': unit['rentAmount'],
                'bedrooms': unit['bedrooms'],
                'bathrooms': unit['bathrooms'],
                'isMultiUnit': true,
                ...unit,
              });
            }
          }
        }
      }
      
      return {
        'tenantId': tenantId,
        'landlordId': landlordId,
        ...tenantData,
        'assignedProperties': assignedProperties,
      };
    } catch (e) {
      print('Error fetching tenant full data: $e');
      return null;
    }
  }

  /// Get payment history for a tenant
  Future<List<Map<String, dynamic>>> getTenantPaymentHistory(String landlordId, String tenantId) async {
    try {
      final paymentsSnapshot = await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('payments')
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return paymentsSnapshot.docs.map((doc) => {
        'paymentId': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  /// Update tenant profile
  Future<bool> updateTenantProfile(String landlordId, String tenantId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('tenants')
          .doc(tenantId)
          .update(updates);
      
      return true;
    } catch (e) {
      print('Error updating tenant profile: $e');
      return false;
    }
  }

  /// Get dashboard statistics for tenant
  Future<Map<String, dynamic>> getTenantDashboardStats(String landlordId, String tenantId) async {
    try {
      // Get all payments for this tenant
      final paymentsSnapshot = await _firestore
          .collection('users')
          .doc(landlordId)
          .collection('payments')
          .where('tenantId', isEqualTo: tenantId)
          .get();
      
      double totalRentAmount = 0;
      double amountPaid = 0;
      double amountDue = 0;
      double overdueAmount = 0;
      
      final now = DateTime.now();
      
      for (var paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final amount = (paymentData['amount'] ?? 0).toDouble();
        final status = paymentData['status'] ?? 'pending';
        final dueDateTimestamp = paymentData['dueDate'] as Timestamp?;
        
        totalRentAmount += amount;
        
        if (status == 'paid') {
          amountPaid += amount;
        } else if (status == 'pending') {
          amountDue += amount;
          
          // Check if overdue
          if (dueDateTimestamp != null) {
            final dueDate = dueDateTimestamp.toDate();
            if (dueDate.isBefore(now)) {
              overdueAmount += amount;
            }
          }
        }
      }
      
      return {
        'totalRentAmount': totalRentAmount,
        'amountPaid': amountPaid,
        'amountDue': amountDue,
        'overdueAmount': overdueAmount,
        'totalPayments': paymentsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {
        'totalRentAmount': 0,
        'amountPaid': 0,
        'amountDue': 0,
        'overdueAmount': 0,
        'totalPayments': 0,
      };
    }
  }
}