import 'package:cloud_firestore/cloud_firestore.dart';

enum IdType {
  civilId,
  residenceId,
  passport,
  commercial;

  String get displayName {
    switch (this) {
      case IdType.civilId:
        return 'Civil ID';
      case IdType.residenceId:
        return 'Residence ID';
      case IdType.passport:
        return 'Passport';
      case IdType.commercial:
        return 'Commercial';
    }
  }

  String get value {
    switch (this) {
      case IdType.civilId:
        return 'CIVILID';
      case IdType.residenceId:
        return 'RESIDENCEID';
      case IdType.passport:
        return 'PASSPORT';
      case IdType.commercial:
        return 'COMMERCIAL';
    }
  }

  static IdType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CIVILID':
        return IdType.civilId;
      case 'RESIDENCEID':
        return IdType.residenceId;
      case 'PASSPORT':
        return IdType.passport;
      case 'COMMERCIAL':
        return IdType.commercial;
      default:
        throw ArgumentError('Invalid IdType value: $value');
    }
  }
}

class BranchInfo {
  final String bankBic;
  final String branchCode;
  final String branchName;
  final String branchDescription;

  BranchInfo({
    required this.bankBic,
    required this.branchCode,
    required this.branchName,
    required this.branchDescription,
  });

  factory BranchInfo.fromMap(Map<String, dynamic> map) {
    return BranchInfo(
      bankBic: map['bankBic'] ?? '',
      branchCode: map['branchCode'] ?? '',
      branchName: map['branchName'] ?? '',
      branchDescription: map['branchDescription'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankBic': bankBic,
      'branchCode': branchCode,
      'branchName': branchName,
      'branchDescription': branchDescription,
    };
  }
}

class AccountInformation {
  final String accountHolderName;
  final String accountNumber;
  final IdType idType;
  final String idNumber;
  final String bankBic;
  final String branchCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountInformation({
    required this.accountHolderName,
    required this.accountNumber,
    required this.idType,
    required this.idNumber,
    required this.bankBic,
    required this.branchCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountInformation.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return AccountInformation(
      accountHolderName: data['cr_account_holder_name'] ?? '',
      accountNumber: data['cr_account_number'] ?? '',
      idType: IdType.fromString(data['cr_id_type'] ?? 'CIVILID'),
      idNumber: data['cr_id_number'] ?? '',
      bankBic: data['cr_bank_bic'] ?? '',
      branchCode: data['cr_branch_code'] ?? '',
      createdAt: (data['cr_created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['cr_updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AccountInformation.fromMap(Map<String, dynamic> data) {
    return AccountInformation(
      accountHolderName: data['cr_account_holder_name'] ?? '',
      accountNumber: data['cr_account_number'] ?? '',
      idType: IdType.fromString(data['cr_id_type'] ?? 'CIVILID'),
      idNumber: data['cr_id_number'] ?? '',
      bankBic: data['cr_bank_bic'] ?? '',
      branchCode: data['cr_branch_code'] ?? '',
      createdAt: (data['cr_created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['cr_updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cr_account_holder_name': accountHolderName,
      'cr_account_number': accountNumber,
      'cr_id_type': idType.value,
      'cr_id_number': idNumber,
      'cr_bank_bic': bankBic,
      'cr_branch_code': branchCode,
      'cr_created_at': Timestamp.fromDate(createdAt),
      'cr_updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  AccountInformation copyWith({
    String? accountHolderName,
    String? accountNumber,
    IdType? idType,
    String? idNumber,
    String? bankBic,
    String? branchCode,
  }) {
    return AccountInformation(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      bankBic: bankBic ?? this.bankBic,
      branchCode: branchCode ?? this.branchCode,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isValid {
    return accountHolderName.isNotEmpty &&
        accountNumber.isNotEmpty &&
        idNumber.isNotEmpty &&
        bankBic.isNotEmpty &&
        branchCode.isNotEmpty;
  }
}