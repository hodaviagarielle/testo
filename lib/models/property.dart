import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String ownerId;
  final String title;
  final String address;
  final String location; // Added location field
  final int bedrooms;
  final int bathrooms;
  final double price;
  final List<String> images;
  final bool isAvailable;
  final Map<String, dynamic> amenities;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double surface;
  final String description;

  Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.address,
    required this.location, // Added to constructor
    required this.bedrooms,
    required this.bathrooms,
    required this.price,
    required this.images,
    required this.isAvailable,
    required this.amenities,
    required this.createdAt,
    this.updatedAt,
    this.surface = 0.0,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'address': address,
      'location': location, // Added to map
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'price': price,
      'images': images,
      'isAvailable': isAvailable,
      'amenities': amenities,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'surface': surface,
      'description': description,
    };
  }

  factory Property.fromMap(String id, Map<String, dynamic> map) {
    return Property(
      id: id,
      ownerId: map['ownerId'],
      title: map['title'],
      address: map['address'],
      location: map['location'] ?? '', // Added to fromMap with default value
      bedrooms: map['bedrooms'],
      bathrooms: map['bathrooms'],
      price: map['price'].toDouble(),
      images: List<String>.from(map['images']),
      isAvailable: map['isAvailable'],
      amenities: Map<String, dynamic>.from(map['amenities']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      surface: (map['surface'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
    );
  }
}