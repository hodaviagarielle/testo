
import 'package:cloud_firestore/cloud_firestore.dart';

class Lease {
  final String id;
  final String propertyId;
  final String tenantId;
  final String ownerId; 
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double securityDeposit;
  final String status;
  final List<String> paymentIds;
  final DateTime createdAt;

  Lease({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.status,
    required this.paymentIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'tenantId': tenantId,
      'ownerId': ownerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'status': status,
      'paymentIds': paymentIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Lease.fromMap(String id, Map<String, dynamic> map) {
    return Lease(
      id: id,
      propertyId: map['propertyId'],
      tenantId: map['tenantId'],
      ownerId: map['ownerId'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      monthlyRent: map['monthlyRent'].toDouble(),
      securityDeposit: map['securityDeposit'].toDouble(),
      status: map['status'],
      paymentIds: List<String>.from(map['paymentIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}