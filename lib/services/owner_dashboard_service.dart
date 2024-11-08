import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/services/payment_service.dart';

class DashboardDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PaymentService _paymentService = PaymentService();
  // Récupérer les statistiques des propriétés
  Future<Map<String, dynamic>> getPropertyStats(String ownerId) async {
  try {
    // Récupérer toutes les propriétés de l'owner
    final propertiesSnapshot = await _firestore
        .collection('properties')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    
    print('Nombre de propriétés trouvées : ${propertiesSnapshot.docs.length}');

    int totalProperties = propertiesSnapshot.docs.length;
    double totalRevenue = 0;
    int occupiedProperties = 0;

    for (var doc in propertiesSnapshot.docs) {
      final data = doc.data();
      // Utilisez 'price' au lieu de 'monthlyRent'
      totalRevenue += (data['price'] ?? 0).toDouble();
      // Utilisez 'isAvailable' au lieu de 'isOccupied'
      if (data['isAvailable'] == true) occupiedProperties++;
    }

    // Calculer le taux d'occupation
    double occupancyRate = totalProperties > 0 
        ? (occupiedProperties / totalProperties) * 100 
        : 0;

    return {
      'totalProperties': totalProperties,
      'monthlyRevenue': totalRevenue,
      'occupancyRate': occupancyRate.round(),
    };
  } catch (e) {
     print('Erreur détaillée : $e');
    throw Exception('Erreur lors de la récupération des statistiques: $e');
  }
}
  // Récupérer le nombre total de locataires
  Future<int> getTotalTenants(String ownerId) async {
    try {
      final tenantsSnapshot = await _firestore
          .collection('tenants')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return tenantsSnapshot.docs.length;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des locataires: $e');
    }
  }

  // Récupérer les notifications récentes
  Future<List<Map<String, dynamic>>> getRecentNotifications(String ownerId) async {
    try {
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      return notificationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'],
          'title': data['title'],
          'description': data['description'],
          'createdAt': data['createdAt'],
          'read': data['read'] ?? false,
        };
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des notifications: $e');
    }
  }

  // Récupérer les paiements du mois en cours
 // Dans owner_dashboard_service.dart


// Modifier la méthode getCurrentMonthPayments pour utiliser le nouveau service
Future<Map<String, dynamic>> getCurrentMonthPayments(String ownerId) async {
  try {
    return await _paymentService.getPaymentStats(ownerId, DateTime.now());
  } catch (e) {
    throw Exception('Erreur lors de la récupération des paiements: $e');
  }
}
}