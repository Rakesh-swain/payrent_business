import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String? id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String type;
  final bool isMultiUnit;
  final List<PropertyUnitModel> units;
  final String landlordId;
  final String? description;
  final List<String>? images;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyModel({
    this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.type,
    required this.isMultiUnit,
    required this.units,
    required this.landlordId,
    this.description,
    this.images,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor to create PropertyModel from Firestore document
  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse units data
    List<PropertyUnitModel> units = [];
    if (data['units'] != null && data['units'] is List) {
      units = (data['units'] as List).map((unit) => PropertyUnitModel.fromMap(unit)).toList();
    }
    
    return PropertyModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      type: data['type'] ?? '',
      isMultiUnit: data['isMultiUnit'] ?? false,
      units: units,
      landlordId: data['landlordId'] ?? '',
      description: data['description'],
      images: data['images'] != null ? List<String>.from(data['images']) : null,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  // Convert PropertyModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'type': type,
      'isMultiUnit': isMultiUnit,
      'units': units.map((unit) => unit.toMap()).toList(),
      'landlordId': landlordId,
      'description': description,
      'images': images,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
  
  // Create a copy with modified fields
  PropertyModel copyWith({
    String? name,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? type,
    bool? isMultiUnit,
    List<PropertyUnitModel>? units,
    String? landlordId,
    String? description,
    List<String>? images,
    bool? isActive,
  }) {
    return PropertyModel(
      id: this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      type: type ?? this.type,
      isMultiUnit: isMultiUnit ?? this.isMultiUnit,
      units: units ?? this.units,
      landlordId: landlordId ?? this.landlordId,
      description: description ?? this.description,
      images: images ?? this.images,
      isActive: isActive ?? this.isActive,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class PropertyUnitModel {
  final String unitId;
  final String unitNumber;
  final String unitType;
  final int bedrooms;
  final double bathrooms;
  final double monthlyRent;
  final double? securityDeposit;
  final String? tenantId;
  final String? notes;
  
  PropertyUnitModel({
    String? unitId,
    required this.unitNumber,
    required this.unitType,
    required this.bedrooms,
    required this.bathrooms,
    required this.monthlyRent,
    this.securityDeposit,
    this.tenantId,
    this.notes,
  }) : unitId = unitId ?? DateTime.now().millisecondsSinceEpoch.toString();
  
  // Factory constructor to create PropertyUnitModel from a Map
  factory PropertyUnitModel.fromMap(Map<String, dynamic> map) {
    return PropertyUnitModel(
      unitId: map['unitId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      unitNumber: map['unitNumber'] ?? '',
      unitType: map['unitType'] ?? '',
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      monthlyRent: (map['monthlyRent'] ?? 0).toDouble(),
      securityDeposit: map['securityDeposit'] != null ? map['securityDeposit'].toDouble() : null,
      tenantId: map['tenantId'],
      notes: map['notes'],
    );
  }
  
  // Convert PropertyUnitModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'unitId': unitId,
      'unitNumber': unitNumber,
      'unitType': unitType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'tenantId': tenantId,
      'notes': notes,
    };
  }
  
  // Create a copy with modified fields
  PropertyUnitModel copyWith({
    String? unitNumber,
    String? unitType,
    int? bedrooms,
    double? bathrooms,
    double? monthlyRent,
    double? securityDeposit,
    String? tenantId,
    String? notes,
  }) {
    return PropertyUnitModel(
      unitId: this.unitId,
      unitNumber: unitNumber ?? this.unitNumber,
      unitType: unitType ?? this.unitType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      tenantId: tenantId ?? this.tenantId,
      notes: notes ?? this.notes,
    );
  }
}