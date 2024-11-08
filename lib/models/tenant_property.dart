import 'package:cloud_firestore/cloud_firestore.dart';

class TenantPropertySearch {
  final String? id; // Add ID field
  final String location;
  final double minPrice;
  final double maxPrice;
  final int? minBedrooms;
  final int? minBathrooms;
  final double minSurface;
  final List<String> amenities;
  final DateTime createdAt;

  TenantPropertySearch({
    this.id, // Make id optional
    required this.location,
    required this.minPrice, // Remove nullable
    required this.maxPrice, // Remove nullable
    this.minBedrooms,
    this.minBathrooms,
    required this.minSurface, // Remove nullable
    required this.amenities,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location': location,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minBedrooms': minBedrooms,
      'minBathrooms': minBathrooms,
      'minSurface': minSurface,
      'amenities': amenities,
      'createdAt': createdAt,
    };
  }

  factory TenantPropertySearch.fromMap(Map<String, dynamic> map, {String? id}) {
    return TenantPropertySearch(
      id: id ?? map['id'],
      location: map['location'] ?? '',
      minPrice: (map['minPrice'] ?? 0).toDouble(),
      maxPrice: (map['maxPrice'] ?? 0).toDouble(),
      minBedrooms: map['minBedrooms'],
      minBathrooms: map['minBathrooms'],
      minSurface: (map['minSurface'] ?? 0).toDouble(),
      amenities: List<String>.from(map['amenities'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}