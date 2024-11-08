import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String propertyId;
  final String tenantId;
  final String ownerId;
  final double amount;
  final DateTime date;
  final String status; // 'pending', 'received', 'late'
  final String type; // 'rent', 'deposit', 'fees'
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Payment({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.ownerId,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create a Payment from a Firebase document
  factory Payment.fromFirestore(Map<String, dynamic> data, String id) {
    return Payment(
      id: id,
      propertyId: data['propertyId'] ?? '',
      tenantId: data['tenantId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      type: data['type'] ?? 'rent',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
        ? (data['updatedAt'] as Timestamp).toDate() 
        : null,
    );
  }

  // Convert payment to a Map for Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'tenantId': tenantId,
      'ownerId': ownerId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'status': status,
      'type': type,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create a copy of the payment with some fields updated
  Payment copyWith({
    String? id,
    String? propertyId,
    String? tenantId,
    String? ownerId,
    double? amount,
    DateTime? date,
    String? status,
    String? type,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      tenantId: tenantId ?? this.tenantId,
      ownerId: ownerId ?? this.ownerId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}