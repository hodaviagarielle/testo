import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/models/lease.dart';

class LeaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'leases';

  // Créer un nouveau bail
  Future<String> createLease(Lease lease) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add(lease.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du bail: $e');
    }
  }

  // Obtenir un bail par ID
  Future<Lease> getLease(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        throw Exception('Bail non trouvé');
      }
      return Lease.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du bail: $e');
    }
  }

  // Obtenir tous les baux pour une propriété
  Stream<List<Lease>> getPropertyLeases(String propertyId) {
    return _firestore
        .collection(_collection)
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Lease.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Obtenir tous les baux pour un locataire
  Future<List<Lease>> getTenantLeases(String tenantId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Lease.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des baux du locataire: $e');
    }
  }

  // Mettre à jour un bail
  Future<void> updateLease(Lease lease) async {
    try {
      await _firestore.collection(_collection).doc(lease.id).update(lease.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du bail: $e');
    }
  }
}