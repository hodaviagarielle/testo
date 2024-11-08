import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/models/payment.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'payments';

  // Créer un nouveau paiement
  Future<Payment> createPayment(Payment payment) async {
    try {
      final paymentData = payment.toFirestore();
      final docRef = await _firestore.collection(_collection).add(paymentData);
      return payment.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erreur lors de la création du paiement: $e');
    }
  }
  // Récupérer un paiement par son ID
  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(paymentId).get();
      if (doc.exists && doc.data() != null) {
        return Payment.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du paiement: $e');
    }
  }

  // Récupérer les paiements d'un propriétaire pour un mois spécifique
  Future<List<Payment>> getOwnerPaymentsForMonth(String ownerId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('ownerId', isEqualTo: ownerId)
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThanOrEqualTo: endOfMonth)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erreur détaillée getOwnerPaymentsForMonth: $e');
      return [];
    }
  }
  // Récupérer les paiements d'un locataire
   Future<List<Payment>> getTenantPayments(String tenantId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Payment.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erreur détaillée getTenantPayments: $e');
      return [];
    }
  }
  // Mettre à jour le statut d'un paiement
  Future<void> updatePaymentStatus(String paymentId, String newStatus) async {
    try {
      await _firestore.collection(_collection).doc(paymentId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut du paiement: $e');
    }
  }

  // Supprimer un paiement
  Future<void> deletePayment(String paymentId) async {
    try {
      await _firestore.collection(_collection).doc(paymentId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du paiement: $e');
    }
  }

  // Obtenir les statistiques de paiement pour un propriétaire
  Future<Map<String, dynamic>> getPaymentStats(String ownerId, DateTime month) async {
    try {
      final payments = await getOwnerPaymentsForMonth(ownerId, month);
      
      // Valeurs par défaut en cas d'erreur
      Map<String, dynamic> defaultStats = {
        'totalReceived': 0.0,
        'totalExpected': 0.0,
        'paymentRate': 0.0,
        'onTimePayments': 0,
        'latePayments': 0,
      };

      // Si pas de paiements, retourner les valeurs par défaut
      if (payments.isEmpty) {
        return defaultStats;
      }

      double totalReceived = 0;
      double totalExpected = 0;
      int onTimePayments = 0;
      int latePayments = 0;

      for (var payment in payments) {
        totalExpected += payment.amount;
        
        if (payment.status == 'received') {
          totalReceived += payment.amount;
          if (payment.date.isBefore(month)) {
            onTimePayments++;
          } else {
            latePayments++;
          }
        }
      }

      return {
        'totalReceived': totalReceived,
        'totalExpected': totalExpected,
        'paymentRate': totalExpected > 0 ? (totalReceived / totalExpected * 100) : 0,
        'onTimePayments': onTimePayments,
        'latePayments': latePayments,
      };
    } catch (e) {
      print('Erreur détaillée getPaymentStats: $e');
      // Retourner des valeurs par défaut en cas d'erreur
      return {
        'totalReceived': 0.0,
        'totalExpected': 0.0,
        'paymentRate': 0.0,
        'onTimePayments': 0,
        'latePayments': 0,
        'error': e.toString()
      };
    }
  }


}