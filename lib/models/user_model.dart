import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? phone;
  final String? countryCode;
  final String name;
  final String businessName;
  final String? profileImage;
  final String userType; // landlord or tenant
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final String? address;
  final Map<String, dynamic>? additionalInfo;

  UserModel({
    required this.uid,
    this.email,
    this.phone,
    this.countryCode,
    required this.name,
    required this.businessName,
    this.profileImage,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.additionalInfo,
    this.address,
  });

  // Create a user model from a Firebase user
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      name: data['name'] ?? '',
      businessName: data['businessName'] ?? '',
      profileImage: data['profileImage'],
      userType: data['userType'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      additionalInfo: data['additionalInfo'],
      address: data['address'],  
    );
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phone': phone,
      'name': name,
      'businessName': businessName,
      'profileImage': profileImage,
      'userType': userType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'additionalInfo': additionalInfo,
      'address': address,
    };
  }

  // Create a new instance with updated fields
  UserModel copyWith({
    String? email,
    String? phone,
    String? name,
    String? businessName,
    String? profileImage,
    String? userType,
    bool? isVerified,
    Map<String, dynamic>? additionalInfo,
    String? address,
  }) {
    return UserModel(
      uid: this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      isVerified: isVerified ?? this.isVerified,
      address: address ?? this.address,
    );
  }
  
  // Get full name
  String get fullName => '$name';
  
  // Check if user is a landlord
  bool get isLandlord => userType.toLowerCase() == 'landlord';
  
  // Check if user is a tenant
  bool get isTenant => userType.toLowerCase() == 'tenant';
}
