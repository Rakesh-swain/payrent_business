import 'package:cloud_firestore/cloud_firestore.dart';

class MandateModel {
  final String? id;
  final String landlordId;
  final String tenantId;
  final String propertyId;
  final String unitId;
  
  // Landlord Account Information
  final String landlordAccountHolderName;
  final String landlordAccountNumber;
  final String landlordIdType;
  final String landlordIdNumber;
  final String landlordBankBic;
  final String landlordBranchCode;
  
  // Tenant Account Information
  final String tenantAccountHolderName;
  final String tenantAccountNumber;
  final String tenantIdType;
  final String tenantIdNumber;
  final String tenantBankBic;
  final String tenantBranchCode;
  
  // Mandate Details
  final int rentAmount;
  final String paymentFrequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'pending', 'active', 'cancelled', 'expired'
  final DateTime createdAt;
  final DateTime updatedAt;
  
  MandateModel({
    this.id,
    required this.landlordId,
    required this.tenantId,
    required this.propertyId,
    required this.unitId,
    required this.landlordAccountHolderName,
    required this.landlordAccountNumber,
    required this.landlordIdType,
    required this.landlordIdNumber,
    required this.landlordBankBic,
    required this.landlordBranchCode,
    required this.tenantAccountHolderName,
    required this.tenantAccountNumber,
    required this.tenantIdType,
    required this.tenantIdNumber,
    required this.tenantBankBic,
    required this.tenantBranchCode,
    required this.rentAmount,
    required this.paymentFrequency,
    required this.startDate,
    this.endDate,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory MandateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MandateModel(
      id: doc.id,
      landlordId: data['landlordId'] ?? '',
      tenantId: data['tenantId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      unitId: data['unitId'] ?? '',
      landlordAccountHolderName: data['landlordAccountHolderName'] ?? '',
      landlordAccountNumber: data['landlordAccountNumber'] ?? '',
      landlordIdType: data['landlordIdType'] ?? '',
      landlordIdNumber: data['landlordIdNumber'] ?? '',
      landlordBankBic: data['landlordBankBic'] ?? '',
      landlordBranchCode: data['landlordBranchCode'] ?? '',
      tenantAccountHolderName: data['tenantAccountHolderName'] ?? '',
      tenantAccountNumber: data['tenantAccountNumber'] ?? '',
      tenantIdType: data['tenantIdType'] ?? '',
      tenantIdNumber: data['tenantIdNumber'] ?? '',
      tenantBankBic: data['tenantBankBic'] ?? '',
      tenantBranchCode: data['tenantBranchCode'] ?? '',
      rentAmount: data['rentAmount'] ?? 0,
      paymentFrequency: data['paymentFrequency'] ?? 'monthly',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'landlordId': landlordId,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'unitId': unitId,
      'landlordAccountHolderName': landlordAccountHolderName,
      'landlordAccountNumber': landlordAccountNumber,
      'landlordIdType': landlordIdType,
      'landlordIdNumber': landlordIdNumber,
      'landlordBankBic': landlordBankBic,
      'landlordBranchCode': landlordBranchCode,
      'tenantAccountHolderName': tenantAccountHolderName,
      'tenantAccountNumber': tenantAccountNumber,
      'tenantIdType': tenantIdType,
      'tenantIdNumber': tenantIdNumber,
      'tenantBankBic': tenantBankBic,
      'tenantBranchCode': tenantBranchCode,
      'rentAmount': rentAmount,
      'paymentFrequency': paymentFrequency,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MandateModel copyWith({
    String? landlordId,
    String? tenantId,
    String? propertyId,
    String? unitId,
    String? landlordAccountHolderName,
    String? landlordAccountNumber,
    String? landlordIdType,
    String? landlordIdNumber,
    String? landlordBankBic,
    String? landlordBranchCode,
    String? tenantAccountHolderName,
    String? tenantAccountNumber,
    String? tenantIdType,
    String? tenantIdNumber,
    String? tenantBankBic,
    String? tenantBranchCode,
    int? rentAmount,
    String? paymentFrequency,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return MandateModel(
      id: this.id,
      landlordId: landlordId ?? this.landlordId,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      landlordAccountHolderName: landlordAccountHolderName ?? this.landlordAccountHolderName,
      landlordAccountNumber: landlordAccountNumber ?? this.landlordAccountNumber,
      landlordIdType: landlordIdType ?? this.landlordIdType,
      landlordIdNumber: landlordIdNumber ?? this.landlordIdNumber,
      landlordBankBic: landlordBankBic ?? this.landlordBankBic,
      landlordBranchCode: landlordBranchCode ?? this.landlordBranchCode,
      tenantAccountHolderName: tenantAccountHolderName ?? this.tenantAccountHolderName,
      tenantAccountNumber: tenantAccountNumber ?? this.tenantAccountNumber,
      tenantIdType: tenantIdType ?? this.tenantIdType,
      tenantIdNumber: tenantIdNumber ?? this.tenantIdNumber,
      tenantBankBic: tenantBankBic ?? this.tenantBankBic,
      tenantBranchCode: tenantBranchCode ?? this.tenantBranchCode,
      rentAmount: rentAmount ?? this.rentAmount,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}