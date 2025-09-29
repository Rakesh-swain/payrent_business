import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:payrent_business/controllers/auth_controller.dart';
import 'package:payrent_business/models/property_model.dart';

class BulkUploadResult {
  final int successCount;
  final int errorCount;
  final List<String> errorMessages;
  const BulkUploadResult({required this.successCount, required this.errorCount, required this.errorMessages});
}

class BulkUploadController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

  final RxBool isUploading = false.obs;

  String _requireUserId() {
    final uid = _auth.firebaseUser.value?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('User not logged in');
    }
    return uid;
  }

  Future<BulkUploadResult> uploadProperties(List<Map<String, dynamic>> rows) async {
    isUploading.value = true;
    int success = 0;
    int errors = 0;
    final List<String> messages = [];

    try {
      final userId = _requireUserId();
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Group by property name for multi-unit handling
      final Map<String, List<Map<String, dynamic>>> propertyGroups = {};
      for (final propertyData in rows) {
        final propertyName = (propertyData['Property Name'] ?? '').toString();
        propertyGroups.putIfAbsent(propertyName, () => []).add(propertyData);
      }

      for (final entry in propertyGroups.entries) {
        try {
          final propertyName = entry.key;
          final propertyRows = entry.value;
          final firstRow = propertyRows.first;
          final isMultiUnitStr = (firstRow['Is Multi Unit']?.toString().toLowerCase() ?? 'false');
          final isMultiUnit = (isMultiUnitStr == 'true' || isMultiUnitStr == 'yes' || isMultiUnitStr == '1') || propertyRows.length > 1;

          final List<PropertyUnitModel> units = [];
          for (final unitRow in propertyRows) {
            units.add(PropertyUnitModel(
              unitNumber: (unitRow['Unit Number'] ?? (units.isEmpty ? 'Main' : 'Unit ${units.length + 1}')).toString(),
              unitType: (unitRow['Unit Type'] ?? 'Standard').toString(),
              bedrooms: int.tryParse(unitRow['Bedrooms']?.toString() ?? '1') ?? 1,
              bathrooms: int.tryParse(unitRow['Bathrooms']?.toString() ?? '1') ?? 1,
              rent: int.tryParse(unitRow['Rent']?.toString() ?? '0') ?? 0,
              paymentFrequency: (unitRow['Payment Frequency'] ?? 'Monthly').toString(),
              squareFeet: int.tryParse(unitRow['Square Feet']?.toString() ?? '0'),
              notes: unitRow['Notes'],
            ));
          }

          final property = PropertyModel(
            name: propertyName,
            address: (firstRow['Address'] ?? '').toString(),
            city: (firstRow['City'] ?? '').toString(),
            state: (firstRow['State'] ?? '').toString(),
            zipCode: (firstRow['Zip'] ?? '').toString(),
            type: (firstRow['Property Type'] ?? 'Single Family').toString(),
            isMultiUnit: isMultiUnit,
            units: units,
            landlordId: userId,
            description: firstRow['Description']?.toString(),
          );

          final propertyRef = firestore.collection('users').doc(userId).collection('properties').doc();
          batch.set(propertyRef, property.toFirestore());
          success++;
        } catch (e) {
          errors++;
          messages.add('Error adding property: $e');
        }
      }

      await batch.commit();
    } catch (e) {
      errors++;
      messages.add('Upload failed: $e');
    } finally {
      isUploading.value = false;
    }

    return BulkUploadResult(successCount: success, errorCount: errors, errorMessages: messages);
  }

  Future<BulkUploadResult> uploadBoth(List<Map<String, dynamic>> rows) async {
    isUploading.value = true;
    int success = 0;
    int errors = 0;
    final List<String> messages = [];

    try {
      final userId = _requireUserId();
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final Map<String, List<Map<String, dynamic>>> propertyGroups = {};
      for (final row in rows) {
        final propertyName = (row['Property Name'] ?? '').toString();
        propertyGroups.putIfAbsent(propertyName, () => []).add(row);
      }

      for (final entry in propertyGroups.entries) {
        try {
          final propertyName = entry.key;
          final propertyRows = entry.value;
          final firstRow = propertyRows.first;

          final isMultiUnitStr = (firstRow['Is Multi Unit']?.toString().toLowerCase() ?? 'false');
          final isMultiUnit = (isMultiUnitStr == 'true' || isMultiUnitStr == 'yes' || isMultiUnitStr == '1') || propertyRows.length > 1;

          final List<PropertyUnitModel> units = [];
          final List<Map<String, dynamic>> tenantAssignments = [];
          final Map<String, String> unitToTenantIds = {};

          final propertyRef = firestore.collection('users').doc(userId).collection('properties').doc();

          for (int i = 0; i < propertyRows.length; i++) {
            final row = propertyRows[i];
            final unit = PropertyUnitModel(
              unitNumber: (row['Unit Number'] ?? (i == 0 && !isMultiUnit ? 'Main' : 'Unit ${i + 1}')).toString(),
              unitType: (row['Unit Type'] ?? 'Standard').toString(),
              bedrooms: int.tryParse(row['Bedrooms']?.toString() ?? '1') ?? 1,
              bathrooms: int.tryParse(row['Bathrooms']?.toString() ?? '1') ?? 1,
              rent: int.tryParse(row['Rent']?.toString() ?? '0') ?? 0,
              paymentFrequency: (row['Payment Frequency'] ?? 'Monthly').toString(),
              squareFeet: int.tryParse(row['Square Feet']?.toString() ?? '0'),
            );
            units.add(unit);

            DateTime leaseStart = DateTime.now();
            DateTime leaseEnd = DateTime.now().add(const Duration(days: 365));
            try {
              if (row['Lease Start'] != null) leaseStart = DateTime.parse(row['Lease Start'].toString());
              if (row['Lease End'] != null) leaseEnd = DateTime.parse(row['Lease End'].toString());
            } catch (e) {
              messages.add('Error parsing dates: $e');
            }

            if ((row['Tenant First Name'] ?? '').toString().isNotEmpty) {
              final tenantRef = firestore.collection('users').doc(userId).collection('tenants').doc();
              final tenantData = {
                'firstName': (row['Tenant First Name'] ?? '').toString(),
                'lastName': (row['Tenant Last Name'] ?? '').toString(),
                'email': (row['Email'] ?? '').toString(),
                'phone': (row['Phone'] ?? '').toString(),
                'landlordId': userId,
                'propertyId': propertyRef.id,
                'propertyName': propertyName,
                'propertyAddress': (row['Address'] ?? '').toString(),
                'unitNumber': unit.unitNumber,
                'unitId': unit.unitId,
                'leaseStartDate': Timestamp.fromDate(leaseStart),
                'leaseEndDate': Timestamp.fromDate(leaseEnd),
                'rentAmount': unit.rent,
                'paymentFrequency': unit.paymentFrequency,
                'rentDueDay': 1,
                'securityDeposit': int.tryParse(row['Security Deposit']?.toString() ?? '0') ?? 0,
                'status': 'active',
                'isArchived': false,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
                // Account Information fields
                'db_account_holder_name': (row['Account Holder Name'] ?? '').toString().isEmpty ? null : (row['Account Holder Name'] ?? '').toString(),
                'db_account_number': (row['Account Number'] ?? '').toString().isEmpty ? null : (row['Account Number'] ?? '').toString(),
                'db_id_type': (row['ID Type'] ?? '').toString().isEmpty ? null : (row['ID Type'] ?? '').toString(),
                'db_id_number': (row['ID Number'] ?? '').toString().isEmpty ? null : (row['ID Number'] ?? '').toString(),
                'db_bank_bic': (row['Bank BIC'] ?? '').toString().isEmpty ? null : (row['Bank BIC'] ?? '').toString(),
                'db_branch_code': (row['Branch Code'] ?? '').toString().isEmpty ? null : (row['Branch Code'] ?? '').toString(),
              };
              batch.set(tenantRef, tenantData);
              unitToTenantIds[unit.unitId] = tenantRef.id;
              tenantAssignments.add({
                'tenantId': tenantRef.id,
                'unitId': unit.unitId,
                'unitNumber': unit.unitNumber,
                'startDate': Timestamp.fromDate(leaseStart),
                'endDate': Timestamp.fromDate(leaseEnd),
                'rentAmount': unit.rent,
                'paymentFrequency': unit.paymentFrequency,
              });
            }
          }

          for (int i = 0; i < units.length; i++) {
            if (unitToTenantIds.containsKey(units[i].unitId)) {
              units[i] = units[i].copyWith(tenantId: unitToTenantIds[units[i].unitId]);
            }
          }

          final property = PropertyModel(
            name: propertyName,
            address: (firstRow['Address'] ?? '').toString(),
            city: (firstRow['City'] ?? '').toString(),
            state: (firstRow['State'] ?? '').toString(),
            zipCode: (firstRow['Zip'] ?? '').toString(),
            type: (firstRow['Property Type'] ?? 'Single Family').toString(),
            isMultiUnit: isMultiUnit,
            units: units,
            landlordId: userId,
            description: firstRow['Description']?.toString(),
          );
          batch.set(propertyRef, property.toFirestore());

          for (final tenant in tenantAssignments) {
            final tenantId = tenant['tenantId'] as String;
            final unitId = tenant['unitId'] as String;
            batch.set(
              firestore.collection('users').doc(userId).collection('properties').doc(propertyRef.id).collection('units').doc(unitId).collection('tenants').doc(tenantId),
              {
                'tenantId': tenantId,
                'startDate': tenant['startDate'],
                'endDate': tenant['endDate'],
                'rentAmount': tenant['rentAmount'],
                'status': 'active',
                'createdAt': FieldValue.serverTimestamp(),
              },
            );
          }

          success++;
        } catch (e) {
          errors++;
          messages.add('Error adding property with tenants: $e');
        }
      }

      await batch.commit();
    } catch (e) {
      errors++;
      messages.add('Upload failed: $e');
    } finally {
      isUploading.value = false;
    }

    return BulkUploadResult(successCount: success, errorCount: errors, errorMessages: messages);
  }

  Future<BulkUploadResult> uploadTenants(List<Map<String, dynamic>> rows) async {
    isUploading.value = true;
    int success = 0;
    int errors = 0;
    final List<String> messages = [];

    try {
      final userId = _requireUserId();
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final tenantRow in rows) {
        try {
          DateTime leaseStart = DateTime.now();
          DateTime leaseEnd = DateTime.now().add(const Duration(days: 365));
          try {
            if (tenantRow['Lease Start'] != null) leaseStart = DateTime.parse(tenantRow['Lease Start'].toString());
            if (tenantRow['Lease End'] != null) leaseEnd = DateTime.parse(tenantRow['Lease End'].toString());
          } catch (e) {
            messages.add('Error parsing dates: $e');
          }

          String propertyId = '';
          String propertyName = (tenantRow['Property'] ?? '').toString();
          String propertyAddress = '';

          if (propertyName.isNotEmpty) {
            final propertyQuery = await firestore
                .collection('users')
                .doc(userId)
                .collection('properties')
                .where('name', isEqualTo: propertyName)
                .limit(1)
                .get();
            if (propertyQuery.docs.isNotEmpty) {
              propertyId = propertyQuery.docs.first.id;
              final propertyData = propertyQuery.docs.first.data();
              propertyAddress = (propertyData['address'] ?? '').toString();
            }
          }

          final tenantData = {
            'firstName': (tenantRow['First Name'] ?? '').toString(),
            'lastName': (tenantRow['Last Name'] ?? '').toString(),
            'email': (tenantRow['Email'] ?? '').toString(),
            'phone': (tenantRow['Phone'] ?? '').toString(),
            'landlordId': userId,
            'propertyId': propertyId,
            'propertyName': propertyName,
            'propertyAddress': propertyAddress,
            'unitNumber': (tenantRow['Unit'] ?? '').toString(),
            'leaseStartDate': Timestamp.fromDate(leaseStart),
            'leaseEndDate': Timestamp.fromDate(leaseEnd),
            'rentAmount': int.tryParse(tenantRow['Rent']?.toString() ?? '0') ?? 0,
            'paymentFrequency': (tenantRow['Payment Frequency'] ?? 'Monthly').toString(),
            'rentDueDay': int.tryParse(tenantRow['Rent Due Day']?.toString() ?? '1') ?? 1,
            'securityDeposit': int.tryParse(tenantRow['Security Deposit']?.toString() ?? '0') ?? 0,
            'status': 'active',
            'isArchived': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            // Account Information fields
            'db_account_holder_name': (tenantRow['Account Holder Name'] ?? '').toString().isEmpty ? null : (tenantRow['Account Holder Name'] ?? '').toString(),
            'db_account_number': (tenantRow['Account Number'] ?? '').toString().isEmpty ? null : (tenantRow['Account Number'] ?? '').toString(),
            'db_id_type': (tenantRow['ID Type'] ?? '').toString().isEmpty ? null : (tenantRow['ID Type'] ?? '').toString(),
            'db_id_number': (tenantRow['ID Number'] ?? '').toString().isEmpty ? null : (tenantRow['ID Number'] ?? '').toString(),
            'db_bank_bic': (tenantRow['Bank BIC'] ?? '').toString().isEmpty ? null : (tenantRow['Bank BIC'] ?? '').toString(),
            'db_branch_code': (tenantRow['Branch Code'] ?? '').toString().isEmpty ? null : (tenantRow['Branch Code'] ?? '').toString(),
          };

          final tenantRef = firestore.collection('users').doc(userId).collection('tenants').doc();
          batch.set(tenantRef, tenantData);
          success++;
        } catch (e) {
          errors++;
          messages.add('Error adding tenant: $e');
        }
      }

      await batch.commit();
    } catch (e) {
      errors++;
      messages.add('Upload failed: $e');
    } finally {
      isUploading.value = false;
    }

    return BulkUploadResult(successCount: success, errorCount: errors, errorMessages: messages);
  }
}
