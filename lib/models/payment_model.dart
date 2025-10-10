import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String tenantName;
  final String propertyName;
  final dynamic amount;
  final DateTime date;
  final String status;

  PaymentModel({
    required this.id,
    required this.tenantName,
    required this.propertyName,
    required this.amount,
    required this.date,
    required this.status,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      tenantName: map['tenantName'] ?? '',
      propertyName: map['propertyName'] ?? '',
      amount: map['amount'] ?? 0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantName': tenantName,
      'propertyName': propertyName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'status': status,
    };
  }
}