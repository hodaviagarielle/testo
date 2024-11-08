import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreUpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int batchSize = 50; // Taille de la pagination
  
  // Clés pour SharedPreferences
  static const String lastProcessedDocKey = 'last_processed_doc';
  static const String totalPropertiesKey = 'total_properties_count';
  static const String processedCountKey = 'processed_count';
  static const String errorCountKey = 'error_count';

  Future<void> updateExistingProperties({
    Function(int total, int processed, int errors)? onProgress,
    bool resumeFromLastError = false,
  }) async {
    try {
      // Récupérer l'état précédent si on reprend après une erreur
      String? lastProcessedDoc;
      int processedCount = 0;
      int errorCount = 0;
      
      if (resumeFromLastError) {
        final prefs = await SharedPreferences.getInstance();
        lastProcessedDoc = prefs.getString(lastProcessedDocKey);
        processedCount = prefs.getInt(processedCountKey) ?? 0;
        errorCount = prefs.getInt(errorCountKey) ?? 0;
      } else {
        // Réinitialiser les compteurs si on commence une nouvelle mise à jour
        await _resetUpdateState();
      }

      // Compter le nombre total de propriétés
      int totalProperties = await _getTotalPropertiesCount();
      
      // Configurer la requête initiale
      Query query = _firestore.collection('properties')
          .orderBy(FieldPath.documentId)
          .limit(batchSize);
      
      // Si on reprend après une erreur, commencer après le dernier document traité
      if (lastProcessedDoc != null) {
        DocumentSnapshot lastDoc = await _firestore
            .collection('properties')
            .doc(lastProcessedDoc)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      bool hasMoreDocs = true;
      while (hasMoreDocs) {
        // Récupérer le batch suivant
        QuerySnapshot batch = await query.get();
        
        if (batch.docs.isEmpty) {
          hasMoreDocs = false;
          continue;
        }

        // Traiter chaque document du batch
        for (var doc in batch.docs) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            
            if (!data.containsKey('location')) {
              String location = extractLocationFromAddress(data['address'] ?? '');
              
              await _firestore.collection('properties')
                  .doc(doc.id)
                  .update({'location': location});
              
              processedCount++;
            }
            
            // Sauvegarder l'état après chaque document
            await _saveUpdateState(doc.id, processedCount, errorCount);
            
          } catch (e) {
            errorCount++;
            print('✗ Erreur lors de la mise à jour de la propriété ${doc.id}: $e');
            
            // Sauvegarder l'état même en cas d'erreur
            await _saveUpdateState(doc.id, processedCount, errorCount);
          }
          
          // Notifier le progrès
          onProgress?.call(totalProperties, processedCount, errorCount);
        }

        // Configurer la requête pour le prochain batch
        query = _firestore.collection('properties')
            .orderBy(FieldPath.documentId)
            .startAfterDocument(batch.docs.last)
            .limit(batchSize);
      }

      // Nettoyage final
      await _resetUpdateState();
      
    } catch (e) {
      print('Erreur générale: $e');
      rethrow;
    }
  }

Future<void> _saveUpdateState(
    String lastDocId, 
    int processedCount, 
    int errorCount
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastProcessedDocKey, lastDocId);
    await prefs.setInt(processedCountKey, processedCount);
    await prefs.setInt(errorCountKey, errorCount);
  }

  Future<void> _resetUpdateState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastProcessedDocKey);
    await prefs.remove(processedCountKey);
    await prefs.remove(errorCountKey);
    await prefs.remove(totalPropertiesKey);
  }

  Future<int> _getTotalPropertiesCount() async {
    final prefs = await SharedPreferences.getInstance();
    int? cachedCount = prefs.getInt(totalPropertiesKey);
    
    if (cachedCount != null) {
      return cachedCount;
    }

    final snapshot = await _firestore.collection('properties').count().get();
    final count = snapshot.count ?? 0; // Gérer le cas où count est null
    await prefs.setInt(totalPropertiesKey, count);
    return count;
  }

  String extractLocationFromAddress(String address) {
    try {
      List<String> parts = address.split(',');
      
      if (parts.length > 1) {
        String city = parts[parts.length - 2].trim();
        return city;
      }
      
      parts = address.split(' ');
      if (parts.length > 1) {
        for (int i = parts.length - 1; i >= 0; i--) {
          if (!RegExp(r'^\d{5}$').hasMatch(parts[i])) {
            return parts[i].trim();
          }
        }
      }
      
      return "Location non spécifiée";
    } catch (e) {
      return "Location non spécifiée";
    }
  }
}
// Widget amélioré pour la mise à jour
class DatabaseUpdateScreen extends StatefulWidget {
  @override
  _DatabaseUpdateScreenState createState() => _DatabaseUpdateScreenState();
}

class _DatabaseUpdateScreenState extends State<DatabaseUpdateScreen> {
  final FirestoreUpdateService _updateService = FirestoreUpdateService();
  bool _isUpdating = false;
  String _status = '';
  double _progress = 0.0;
  bool _canResume = false;

  @override
  void initState() {
    super.initState();
    _checkForPreviousUpdate();
  }

  Future<void> _checkForPreviousUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLastDoc = prefs.containsKey(FirestoreUpdateService.lastProcessedDocKey);
    setState(() {
      _canResume = hasLastDoc;
    });
  }

  Future<void> _startUpdate({bool resume = false}) async {
    setState(() {
      _isUpdating = true;
      _status = 'Mise à jour en cours...';
      _progress = 0.0;
    });

    try {
      await _updateService.updateExistingProperties(
        resumeFromLastError: resume,
        onProgress: (total, processed, errors) {
          setState(() {
            _progress = processed / total;
            _status = 'Progression: $processed/$total (Erreurs: $errors)';
          });
        },
      );
      
      setState(() {
        _status = 'Mise à jour terminée avec succès!';
        _progress = 1.0;
        _canResume = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Erreur lors de la mise à jour: $e';
        _canResume = true;
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mise à jour de la base de données'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Cet outil va mettre à jour toutes les propriétés existantes\n'
                'pour ajouter le champ de localisation.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 24),
              if (_isUpdating) ...[
                CircularProgressIndicator(
                  value: _progress,
                ),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _progress,
                ),
              ] else ...[
                if (_canResume)
                  ElevatedButton(
                    onPressed: () => _startUpdate(resume: true),
                    child: Text('Reprendre la mise à jour'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _startUpdate(resume: false),
                  child: Text('Démarrer une nouvelle mise à jour'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
              SizedBox(height: 24),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _status.contains('Erreur') 
                    ? Colors.red 
                    : Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}