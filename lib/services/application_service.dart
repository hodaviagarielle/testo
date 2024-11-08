
// application_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:localink/models/rental_application.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionName = 'applications';

  // Soumettre une nouvelle demande
  Future<RentalApplication> submitApplication({
    required String propertyId,
    required String ownerId,
    required String tenantId,
    required double monthlyIncome,
    required String occupation,
    required String employer,
    required String employmentDuration,
    required String message,
    required List<PlatformFile> documents,
    required String tenantFirstName,
    required String tenantLastName,
    required String tenantEmail,
    required String tenantPhone,
  }) async {
    try {
      // Upload documents
      List<String> documentUrls = [];
      for (var document in documents) {
        if (document.bytes != null) {
          final path = 'applications/$tenantId/${DateTime.now().millisecondsSinceEpoch}_${document.name}';
          final ref = _storage.ref().child(path);
          await ref.putData(document.bytes!);
          final url = await ref.getDownloadURL();
          documentUrls.add(url);
        }
      }

      // Create application
      final application = RentalApplication(
        id: '',
        propertyId: propertyId,
        tenantId: tenantId,
        ownerId: ownerId,
        status: 'pending',
        submittedAt: DateTime.now(),
        monthlyIncome: monthlyIncome,
        occupation: occupation,
        employer: employer,
        employmentDuration: employmentDuration,
        message: message,
        documents: documentUrls,
        tenantFirstName: tenantFirstName,
        tenantLastName: tenantLastName,
        tenantEmail: tenantEmail,
        tenantPhone: tenantPhone,
      );

      // Save to Firestore
      final docRef = await _firestore.collection(_collectionName).add(application.toMap());
      return application.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erreur lors de la soumission de la demande: $e');
    }
  }

  // Obtenir les demandes pour une propriété
  Stream<List<RentalApplication>> getApplicationsForProperty(String propertyId) {
    return _firestore
        .collection(_collectionName)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalApplication.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Obtenir les demandes d'un locataire
  Stream<List<RentalApplication>> getApplicationsForTenant(String tenantId) {
    return _firestore
        .collection(_collectionName)
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalApplication.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Mettre à jour le statut d'une demande
  Future<void> updateApplicationStatus(String applicationId, String status) async {
    try {
      await _firestore.collection(_collectionName).doc(applicationId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  // Supprimer une demande et ses documents
  Future<void> deleteApplication(RentalApplication application) async {
    try {
      // Supprimer les documents du storage
      for (String documentUrl in application.documents) {
        try {
          final ref = _storage.refFromURL(documentUrl);
          await ref.delete();
        } catch (e) {
          print('Erreur lors de la suppression du document: $e');
        }
      }

      // Supprimer la demande de Firestore
      await _firestore.collection(_collectionName).doc(application.id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la demande: $e');
    }
  }

  // Obtenir une demande spécifique
  Stream<RentalApplication?> getApplication(String applicationId) {
    return _firestore
        .collection(_collectionName)
        .doc(applicationId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return RentalApplication.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }
}