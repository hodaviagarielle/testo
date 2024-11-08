
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String userType; // 'owner' ou 'tenant'
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.userType,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'userType': userType,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      email: map['email'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      userType: map['userType'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: map['lastLogin'] != null ? (map['lastLogin'] as Timestamp).toDate() : null,
    );
  }
}