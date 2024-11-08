import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:localink/models/document_info.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Convertir un fichier en base64
  Future<String> _fileToBase64(File file) async {
    List<int> fileBytes = await file.readAsBytes();
    return base64Encode(fileBytes);
  }

  // Upload un document de locataire
  Future<DocumentInfo> uploadTenantDocument(File file, String userId) async {
    try {
      String fileExtension = path.extension(file.path);
      String fileName = path.basename(file.path);
      String docId = _uuid.v4();
      
      // Convertir le fichier en base64
      String base64File = await _fileToBase64(file);
      
      // Créer un document dans Firestore avec les données en base64
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .doc(docId);
      
      // Stocker le document et ses métadonnées
      await docRef.set({
        'name': fileName,
        'fileData': base64File,
        'type': fileExtension.toLowerCase().replaceAll('.', ''),
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      
      // Créer et retourner les informations du document
    return DocumentInfo(
        id: docId,
        name: fileName,
        fileData: base64File, // Au lieu de url: ''
        type: fileExtension.toLowerCase().replaceAll('.', ''),
        uploadedAt: DateTime.now(),
      );
    } catch (e) {
      print('Erreur détaillée lors du téléchargement: $e');
      throw Exception('Erreur lors du téléchargement du document: $e');
    }
  }

  // Supprimer un document de locataire
  Future<void> deleteTenantDocument(String userId, String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .doc(docId)
          .delete();
    } catch (e) {
      print('Erreur détaillée lors de la suppression: $e');
      throw Exception('Erreur lors de la suppression du document: $e');
    }
  }

  // Upload une image de propriété (déjà en place)
  Future<void> uploadPropertyImage(String propertyId, File imageFile) async {
    try {
      String base64Image = await _fileToBase64(imageFile);
      
      String imageId = _uuid.v4();
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('images')
          .doc(imageId)
          .set({
        'imageData': base64Image,
        'fileName': path.basename(imageFile.path),
        'uploadedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors du téléchargement de l\'image: $e');
    }
  }

  // Récupérer les images d'une propriété (déjà en place)
  Future<List<Map<String, dynamic>>> getPropertyImages(String propertyId) async {
    try {
      final QuerySnapshot imagesSnapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('images')
          .get();
      
      return imagesSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'imageData': doc.get('imageData'),
                'fileName': doc.get('fileName'),
                'uploadedAt': doc.get('uploadedAt'),
              })
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des images: $e');
    }
  }

  // Supprimer une image de propriété (déjà en place)
  Future<void> deletePropertyImage(String propertyId, String imageId) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('images')
          .doc(imageId)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'image: $e');
    }
  }
}