
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/models/tenant.dart';

class TenantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tenants';

  // Créer un nouveau locataire
  Future<String> createTenant(Tenant tenant) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add(tenant.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du locataire: $e');
    }
  }

  // Obtenir un locataire par ID
 Future<Tenant> getTenant(String email) async {
  try {
    print('Récupération du locataire avec l\'email: $email');

    // Récupération du document du locataire dans Firestore
    QuerySnapshot snapshot = await _firestore
        .collection(_collection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    // Vérification qu'un document a bien été trouvé
    assert(snapshot.docs.isNotEmpty, 'Aucun locataire trouvé avec l\'email $email');

    // Récupération des données du document
    DocumentSnapshot doc = snapshot.docs.first;
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Création de l'objet Tenant
    Tenant tenant = Tenant.fromMap(doc.id, data);

    print('Locataire trouvé: $tenant');
    return tenant;
  } catch (e) {
    print('Erreur lors de la récupération du locataire: $e');
    rethrow;
  }
}

  Future<Tenant> getAllTenant(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        throw Exception('Locataire non trouvé');
      }
      return Tenant.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du locataire: $e');
    }
  }

  // Mettre à jour un locataire
  Future<void> updateTenant(String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(id).update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du locataire: $e');
    }
  }
}