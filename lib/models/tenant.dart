
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/models/document_info.dart';

class Tenant {
  final String id;
  final String userId;
  final String propertyId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final double monthlyIncome;
  final List<DocumentInfo> documents;
  final String status;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName';

  Tenant({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.monthlyIncome,
    required this.documents,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'propertyId': propertyId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'monthlyIncome': monthlyIncome,
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Tenant.fromMap(String id, Map<String, dynamic> map) {
    return Tenant(
      id: id,
      userId: map['userId'],
      propertyId: map['propertyId'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      phone: map['phone'],
      monthlyIncome: map['monthlyIncome'].toDouble(),
      documents: (map['documents'] as List)
          .map((doc) => DocumentInfo.fromMap(doc))
          .toList(),
      status: map['status'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
