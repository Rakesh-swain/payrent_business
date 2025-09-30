import 'package:cloud_firestore/cloud_firestore.dart';

class TenantModel {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String landlordId;
  final String? propertyId;
  final String? propertyName;
  final String? propertyAddress;
  final String? unitNumber;
  final String? unitId;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final int? rentAmount;
  final int? rentDueDay;
  final int? securityDeposit;
  final String? notes;
  final String status;
  final String paymentFrequency;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Account Information fields
  final String? accountHolderName;
  final String? accountNumber;
  final String? idType;
  final String? idNumber;
  final String? bankBic;
  final String? branchCode;
  
  TenantModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.landlordId,
    this.propertyId,
    this.propertyName,
    this.propertyAddress,
    this.unitNumber,
    this.unitId,
    this.leaseStartDate,
    this.leaseEndDate,
    this.rentAmount,
    this.rentDueDay,
    this.securityDeposit,
    this.notes,
    this.status = 'active',
    this.paymentFrequency = 'monthly',
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
    this.accountHolderName,
    this.accountNumber,
    this.idType,
    this.idNumber,
    this.bankBic,
    this.branchCode,
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
      rentAmount: (data['rentAmount'] ?? 0),
      rentDueDay: data['rentDueDay'] ?? 1,
      securityDeposit: data['securityDeposit'] != null 
          ? (data['securityDeposit'])
          : null,
      notes: data['notes'],
      status: data['status'] ?? 'active',
      paymentFrequency: data['paymentFrequency'] ?? 'monthly',
      isArchived: data['isArchived'] ?? false,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      accountHolderName: data['db_account_holder_name'],
      accountNumber: data['db_account_number'],
      idType: data['db_id_type'],
      idNumber: data['db_id_number'],
      bankBic: data['db_bank_bic'],
      branchCode: data['db_branch_code'],
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
      'leaseStartDate': leaseStartDate != null?Timestamp.fromDate(leaseStartDate!):null,
      'leaseEndDate': leaseEndDate != null?Timestamp.fromDate(leaseEndDate!):null,
      'rentAmount': rentAmount,
      'rentDueDay': rentDueDay,
      'securityDeposit': securityDeposit,
      'paymentFrequency': paymentFrequency,
      'notes': notes,
      'status': status,
      'isArchived': isArchived,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'db_account_holder_name': accountHolderName,
      'db_account_number': accountNumber,
      'db_id_type': idType,
      'db_id_number': idNumber,
      'db_bank_bic': bankBic,
      'db_branch_code': branchCode,
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
    int? rentAmount,
    int? rentDueDay,
    int? securityDeposit,
    String? paymentFrequency,
    String? notes,
    String? status,
    bool? isArchived,
    String? accountHolderName,
    String? accountNumber,
    String? idType,
    String? idNumber,
    String? bankBic,
    String? branchCode,
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
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      bankBic: bankBic ?? this.bankBic,
      branchCode: branchCode ?? this.branchCode,
    );
  }
  
  // Get full name
  String get fullName => '$firstName $lastName';
}