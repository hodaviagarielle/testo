import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentInfo {
  final String id;
  final String name;
  final String fileData; // Données du fichier en base64
  final String type;
  final DateTime uploadedAt;

  DocumentInfo({
    required this.id,
    required this.name,
    required this.fileData,
    required this.type,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fileData': fileData,
      'type': type,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory DocumentInfo.fromMap(Map<String, dynamic> map) {
    return DocumentInfo(
      id: map['id'],
      name: map['name'],
      fileData: map['fileData'],
      type: map['type'],
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }
}