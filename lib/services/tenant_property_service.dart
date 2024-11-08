
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/models/property.dart';
import 'package:localink/models/tenant_property.dart';

class TenantPropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Sauvegarder une recherche
  Future<void> saveSearch(TenantPropertySearch search) async {
    try {
      if (search.id == null) {
        throw Exception('User ID is required to save search');
      }
      
      await _firestore
          .collection('users')
          .doc(search.id)
          .collection('saved_searches')
          .add(search.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la recherche: $e');
    }
  }

// Nouvelle méthode pour supprimer une recherche sauvegardée
  Future<void> deleteSavedSearch(String userId, String searchId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_searches')
          .doc(searchId)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la recherche: $e');
    }
  }

  // Méthode pour supprimer toutes les recherches sauvegardées d'un utilisateur
  Future<void> deleteAllSavedSearches(String userId) async {
    try {
      final QuerySnapshot searches = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_searches')
          .get();

      final batch = _firestore.batch();
      for (final doc in searches.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la suppression des recherches: $e');
    }
  }

  // Récupérer les recherches sauvegardées
 Stream<List<TenantPropertySearch>> getSavedSearches(String userId) {
  return _firestore
      .collection('users')
      .doc(userId)
      .collection('saved_searches')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TenantPropertySearch.fromMap(doc.data(), id: doc.id))
          .toList());
}

  // Rechercher des propriétés
Future<List<Property>> searchProperties({
  required String location,
  double? minPrice,
  double? maxPrice,
  int? minBedrooms,
  int? minBathrooms,
  double? minSurface,
  List<String>? amenities,
}) async {
  try {
    Query query = _firestore.collection('properties').where('isAvailable', isEqualTo: true);

    // Appliquer les filtres
    if (location.isNotEmpty) {
      query = query.where('address', isEqualTo: location);
    }
    if (minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }
    if (minBedrooms != null) {
      query = query.where('bedrooms', isGreaterThanOrEqualTo: minBedrooms);
    }
    if (minBathrooms != null) {
      query = query.where('bathrooms', isGreaterThanOrEqualTo: minBathrooms);
    }
    if (minSurface != null) {
      query = query.where('surface', isGreaterThanOrEqualTo: minSurface);
    }
    if (amenities != null && amenities.isNotEmpty) {
      for (String amenity in amenities) {
        query = query.where('amenities.$amenity', isEqualTo: true);
      }
    }

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Property.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  } catch (e) {
    throw Exception('Erreur lors de la recherche de propriétés: $e');
  }
}
Query _applyLocationFilter(Query query, String location) {
  return query.where('address', isEqualTo: location);
}

Query _applyPriceFilter(Query query, double? minPrice, double? maxPrice) {
  if (minPrice != null) {
    query = query.where('price', isGreaterThanOrEqualTo: minPrice);
  }
  if (maxPrice != null) {
    query = query.where('price', isLessThanOrEqualTo: maxPrice);
  }
  return query;
}

// Implémenter de manière similaire les autres méthodes de filtrage
}