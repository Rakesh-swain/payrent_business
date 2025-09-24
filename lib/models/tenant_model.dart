import 'package:cloud_firestore/cloud_firestore.dart';

class TenantModel {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String landlordId;
  final String propertyId;
  final String propertyName;
  final String propertyAddress;
  final String unitNumber;
  final String? unitId;
  final DateTime leaseStartDate;
  final DateTime leaseEndDate;
  final double rentAmount;
  final int rentDueDay;
  final double? securityDeposit;
  final String? notes;
  final String status;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  TenantModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.landlordId,
    required this.propertyId,
    required this.propertyName,
    required this.propertyAddress,
    required this.unitNumber,
    this.unitId,
    required this.leaseStartDate,
    required this.leaseEndDate,
    required this.rentAmount,
    required this.rentDueDay,
    this.securityDeposit,
    this.notes,
    this.status = 'active',
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create TenantModel from Firestore document
  factory TenantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TenantModel(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      landlordId: data['landlordId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      propertyName: data['propertyName'] ?? '',
      propertyAddress: data['propertyAddress'] ?? '',
      unitNumber: data['unitNumber'] ?? '',
      unitId: data['unitId'],
      leaseStartDate: data['leaseStartDate'] != null 
          ? (data['leaseStartDate'] as Timestamp).toDate() 
          : DateTime.now(),
      leaseEndDate: data['leaseEndDate'] != null 
          ? (data['leaseEndDate'] as Timestamp).toDate() 
          : DateTime.now().add(const Duration(days: 365)),
      rentAmount: (data['rentAmount'] ?? 0).toDouble(),
      rentDueDay: data['rentDueDay'] ?? 1,
      securityDeposit: data['securityDeposit'] != null 
          ? (data['securityDeposit']).toDouble() 
          : null,
      notes: data['notes'],
      status: data['status'] ?? 'active',
      isArchived: data['isArchived'] ?? false,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  // Convert TenantModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'landlordId': landlordId,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'propertyAddress': propertyAddress,
      'unitNumber': unitNumber,
      'unitId': unitId,
      'leaseStartDate': Timestamp.fromDate(leaseStartDate),
      'leaseEndDate': Timestamp.fromDate(leaseEndDate),
      'rentAmount': rentAmount,
      'rentDueDay': rentDueDay,
      'securityDeposit': securityDeposit,
      'notes': notes,
      'status': status,
      'isArchived': isArchived,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
  
  // Create a copy with modified fields
  TenantModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? landlordId,
    String? propertyId,
    String? propertyName,
    String? propertyAddress,
    String? unitNumber,
    String? unitId,
    DateTime? leaseStartDate,
    DateTime? leaseEndDate,
    double? rentAmount,
    int? rentDueDay,
    double? securityDeposit,
    String? notes,
    String? status,
    bool? isArchived,
  }) {
    return TenantModel(
      id: this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      landlordId: landlordId ?? this.landlordId,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      unitNumber: unitNumber ?? this.unitNumber,
      unitId: unitId ?? this.unitId,
      leaseStartDate: leaseStartDate ?? this.leaseStartDate,
      leaseEndDate: leaseEndDate ?? this.leaseEndDate,
      rentAmount: rentAmount ?? this.rentAmount,
      rentDueDay: rentDueDay ?? this.rentDueDay,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  // Get full name
  String get fullName => '$firstName $lastName';
}