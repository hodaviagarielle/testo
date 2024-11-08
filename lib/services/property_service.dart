
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/models/property.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'properties';

  // Créer une nouvelle propriété
  Future<String> createProperty(Property property) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add(property.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la propriété: $e');
    }
  }

  // Obtenir une propriété par ID
  Future<Property> getProperty(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        throw Exception('Propriété non trouvée');
      }
      return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la propriété: $e');
    }
  }

  // Obtenir toutes les propriétés d'un propriétaire
  Stream<List<Property>> getOwnerProperties(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Property.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Mettre à jour une propriété
  Future<void> updateProperty(String id, Map<String, dynamic> updates) async {
  try {
      await _firestore.collection(_collection).doc(id).update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la propriété: $e');
    }
  }

  // Supprimer une propriété
  Future<void> deleteProperty(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la propriété: $e');
    }
  }

 // Obtenir des propriétés avec des filtres de recherche
Future<List<Property>> getProperties({
  required String location,
  required double minPrice,
  required double maxPrice,
  required int minBedrooms,
  required int minBathrooms,
}) async {
  try {
    Query query = _firestore.collection(_collection);

    if (location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }
    if (minPrice > 0) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice > 0) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }
    if (minBedrooms > 0) {
      query = query.where('bedrooms', isGreaterThanOrEqualTo: minBedrooms);
    }
    if (minBathrooms > 0) {
      query = query.where('bathrooms', isGreaterThanOrEqualTo: minBathrooms);
    }

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs.map((doc) => Property.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  } catch (e) {
    throw Exception('Erreur lors de la récupération des propriétés: $e');
  }
}

}