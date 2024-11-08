// rental_application.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RentalApplication {
  final String id;
  final String propertyId;
  final String tenantId;
  final String ownerId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime submittedAt;
  final double monthlyIncome;
  final String occupation;
  final String employer;
  final String employmentDuration;
  final String message;
  final List<String> documents; // URLs des documents uploadés
  
  // Informations du tenant
  final String tenantFirstName;
  final String tenantLastName;
  final String tenantEmail;
  final String tenantPhone;

  RentalApplication({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.ownerId,
    required this.status,
    required this.submittedAt,
    required this.monthlyIncome,
    required this.occupation,
    required this.employer,
    required this.employmentDuration,
    required this.message,
    required this.documents,
    required this.tenantFirstName,
    required this.tenantLastName,
    required this.tenantEmail,
    required this.tenantPhone,
  });

  String get tenantFullName => '$tenantFirstName $tenantLastName';

  RentalApplication copyWith({
    String? id,
    String? propertyId,
    String? tenantId,
    String? ownerId,
    String? status,
    DateTime? submittedAt,
    double? monthlyIncome,
    String? occupation,
    String? employer,
    String? employmentDuration,
    String? message,
    List<String>? documents,
    String? tenantFirstName,
    String? tenantLastName,
    String? tenantEmail,
    String? tenantPhone,
  }) {
    return RentalApplication(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      tenantId: tenantId ?? this.tenantId,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      occupation: occupation ?? this.occupation,
      employer: employer ?? this.employer,
      employmentDuration: employmentDuration ?? this.employmentDuration,
      message: message ?? this.message,
      documents: documents ?? this.documents,
      tenantFirstName: tenantFirstName ?? this.tenantFirstName,
      tenantLastName: tenantLastName ?? this.tenantLastName,
      tenantEmail: tenantEmail ?? this.tenantEmail,
      tenantPhone: tenantPhone ?? this.tenantPhone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'tenantId': tenantId,
      'ownerId': ownerId,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'monthlyIncome': monthlyIncome,
      'occupation': occupation,
      'employer': employer,
      'employmentDuration': employmentDuration,
      'message': message,
      'documents': documents,
      'tenantFirstName': tenantFirstName,
      'tenantLastName': tenantLastName,
      'tenantEmail': tenantEmail,
      'tenantPhone': tenantPhone,
    };
  }

  factory RentalApplication.fromMap(String id, Map<String, dynamic> map) {
    return RentalApplication(
      id: id,
      propertyId: map['propertyId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      status: map['status'] ?? 'pending',
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      monthlyIncome: (map['monthlyIncome'] ?? 0.0).toDouble(),
      occupation: map['occupation'] ?? '',
      employer: map['employer'] ?? '',
      employmentDuration: map['employmentDuration'] ?? '',
      message: map['message'] ?? '',
      documents: List<String>.from(map['documents'] ?? []),
      tenantFirstName: map['tenantFirstName'] ?? '',
      tenantLastName: map['tenantLastName'] ?? '',
      tenantEmail: map['tenantEmail'] ?? '',
      tenantPhone: map['tenantPhone'] ?? '',
    );
  }
}
