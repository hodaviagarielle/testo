import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TenantDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _getTenantId(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      print(
          "Utilisateur connecté : ${currentUser.uid}"); // Ajoutez un log pour vérifier l'ID de l'utilisateur

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data()?['userType'] != 'tenant') {
        return null;
      }

      final tenantQuery = await _firestore
          .collection('tenants')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (tenantQuery.docs.isNotEmpty) {
        return tenantQuery.docs.first.id;
      }

      return null;
    } catch (e) {
      print('Erreur lors de la récupération de tenantId : $e');
      return null;
    }
  }

  Future<bool> checkActiveLease(String? userId) async {
    if (userId == null) return false;

    try {
      // Get the tenantId first
      final tenantId = await _getTenantId(userId);
      if (tenantId == null) return false;
      print('id trouve: $tenantId');
      // Check for active lease in the main leases collection
      final leaseQuery = await _firestore
          .collection('leases')
          .where('tenantId', isEqualTo: tenantId)
          .where('status', isEqualTo: 'active')
          .get();
     print('lease found: $leaseQuery');     
   print('lease trouve: $leaseQuery.docs.isNotEmpty');
      return leaseQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking active lease: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getRentalInfo(String userId) async {
    try {
        // Get the tenantId first
      final tenantId = await _getTenantId(userId);
      print('id trouve: $tenantId');
      // Récupérer d'abord l'ID du bail du locataire
      final leaseQuery = await _firestore
          .collection('leases')
          .where('tenantId', isEqualTo: tenantId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (leaseQuery.docs.isEmpty) {
        print('Aucun bail actif trouvé pour ce locataire.');
        return null;
      }

      final leaseData = leaseQuery.docs.first.data();
      final leaseId = leaseQuery.docs.first.id;

      // Récupérer les informations de la propriété liée au bail
      final propertyDoc = await _firestore
          .collection('properties')
          .doc(leaseData['propertyId'])
          .get();

      if (!propertyDoc.exists) return null;

      final propertyData = propertyDoc.data()!;

      return {
        'leaseId': leaseId,
        'address': propertyData['address'],
        'rent': leaseData['monthlyRent'],
        'deposit': leaseData['securityDeposit'],
        'leaseStart': (leaseData['startDate'] as Timestamp).toDate().toString(),
        'leaseEnd': (leaseData['endDate'] as Timestamp).toDate().toString(),
        'nextPaymentDate': _calculateNextPaymentDate(leaseData['startDate']),
        'propertyId': leaseData['propertyId'],
      };
    } catch (e) {
      print('Erreur lors de la récupération des informations de location : $e');
      rethrow;
    }
  }

  String _calculateNextPaymentDate(Timestamp startDate) {
    final now = DateTime.now();
    final start = startDate.toDate();
    final nextPayment = DateTime(now.year, now.month + 1, start.day);
    return nextPayment.toString().split(' ')[0]; // Retourne juste la date
  }

  // Récupère les demandes de maintenance
  Future<List<Map<String, dynamic>>> getMaintenanceRequests(
      String tenantId) async {
    try {
      final snapshot = await _firestore
          .collection('maintenance_requests')
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final formatter = DateFormat('dd/MM/yyyy');

        return {
          'id': doc.id,
          'title': data['title'],
          'description': data['description'],
          'status': data['status'],
          'priority': data['priority'],
          'category': data['category'],
          'date': formatter.format(createdAt),
          'createdAt': createdAt,
          'lastUpdate': data['lastUpdate'],
          'attachments': data['attachments'] ?? [],
          'comments': data['comments'] ?? [],
        };
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des demandes de maintenance: $e');
      rethrow;
    }
  }

  // Récupère l'historique des paiements
  Future<Map<String, dynamic>> getPaymentHistory(String tenantId) async {
    try {
      final currentYear = DateTime.now().year;
      final currentMonth = DateTime.now().month;

      // Récupère les paiements des 12 derniers mois
      final snapshot = await _firestore
          .collection('payments')
          .where('tenantId', isEqualTo: tenantId)
          .where('date',
              isGreaterThanOrEqualTo: DateTime(currentYear, currentMonth - 11))
          .orderBy('date', descending: true)
          .get();

      final payments = snapshot.docs.map((doc) {
        final data = doc.data();
        final paymentDate = (data['date'] as Timestamp).toDate();
        return {
          'id': doc.id,
          'amount': data['amount'],
          'status': data['status'],
          'date': DateFormat('dd/MM/yyyy').format(paymentDate),
          'method': data['method'],
          'reference': data['reference'],
        };
      }).toList();

      // Calcule les statistiques de paiement
      double totalPaid = 0;
      int onTimePayments = 0;
      int latePayments = 0;

      for (var payment in payments) {
        if (payment['status'] == 'completed') {
          totalPaid += payment['amount'];
          if (payment['status'] == 'on_time') {
            onTimePayments++;
          } else {
            latePayments++;
          }
        }
      }

      return {
        'payments': payments,
        'statistics': {
          'totalPaid': totalPaid,
          'onTimePyaments': onTimePayments,
          'latePyaments': latePayments,
          'paymentHistory': payments.length,
        }
      };
    } catch (e) {
      print(
          'Erreur lors de la récupération de l\'historique des paiements: $e');
      rethrow;
    }
  }

  // Récupère les annonces et notifications
  Future<List<Map<String, dynamic>>> getAnnouncements(String tenantId) async {
    try {
      // Récupère d'abord le propertyId du locataire
      final leaseQuery = await _firestore
          .collection('leases')
          .where('tenantId', isEqualTo: tenantId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (leaseQuery.docs.isEmpty) {
        return [];
      }

      final propertyId = leaseQuery.docs.first.data()['propertyId'];

      // Récupère les annonces pour la propriété et les annonces générales
      final snapshot = await _firestore
          .collection('announcements')
          .where('target', whereIn: ['all', 'tenants', propertyId])
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();

        return {
          'id': doc.id,
          'title': data['title'],
          'content': data['content'],
          'type': data['type'],
          'priority': data['priority'],
          'date': DateFormat('dd/MM/yyyy').format(createdAt),
          'createdAt': createdAt,
          'expiresAt': data['expiresAt'],
          'attachments': data['attachments'] ?? [],
        };
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des annonces: $e');
      rethrow;
    }
  }

  // Récupère les documents liés au bail
  Future<List<Map<String, dynamic>>> getLeaseDocuments(String tenantId) async {
    try {
      final leaseQuery = await _firestore
          .collection('leases')
          .where('tenantId', isEqualTo: tenantId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (leaseQuery.docs.isEmpty) {
        return [];
      }

      final leaseId = leaseQuery.docs.first.id;

      final snapshot = await _firestore
          .collection('documents')
          .where('leaseId', isEqualTo: leaseId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final uploadedAt = (data['uploadedAt'] as Timestamp).toDate();

        return {
          'id': doc.id,
          'name': data['name'],
          'type': data['type'],
          'category': data['category'],
          'url': data['url'],
          'size': data['size'],
          'uploadedAt': DateFormat('dd/MM/yyyy').format(uploadedAt),
          'expirationDate': data['expirationDate'],
        };
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des documents: $e');
      rethrow;
    }
  }

  // Crée une nouvelle demande de maintenance
  Future<String> createMaintenanceRequest({
    required String tenantId,
    required String title,
    required String description,
    required String category,
    required String priority,
    List<String>? attachments,
  }) async {
    try {
      // Récupère d'abord les informations du bail
      final leaseQuery = await _firestore
          .collection('leases')
          .where('tenantId', isEqualTo: tenantId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (leaseQuery.docs.isEmpty) {
        throw Exception('Aucun bail actif trouvé');
      }

      final leaseData = leaseQuery.docs.first.data();
      final propertyId = leaseData['propertyId'];
      final ownerId = leaseData['ownerId'];

      // Crée la demande de maintenance
      final docRef = await _firestore.collection('maintenance_requests').add({
        'tenantId': tenantId,
        'propertyId': propertyId,
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdate': FieldValue.serverTimestamp(),
        'attachments': attachments ?? [],
        'comments': [],
      });

      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la demande de maintenance: $e');
      rethrow;
    }
  }

  // Met à jour une demande de maintenance existante
  Future<void> updateMaintenanceRequest({
    required String requestId,
    String? description,
    String? status,
    List<String>? newAttachments,
    String? comment,
  }) async {
    try {
      final updates = <String, dynamic>{
        'lastUpdate': FieldValue.serverTimestamp(),
      };

      if (description != null) updates['description'] = description;
      if (status != null) updates['status'] = status;
      if (newAttachments != null) {
        updates['attachments'] = FieldValue.arrayUnion(newAttachments);
      }
      if (comment != null) {
        updates['comments'] = FieldValue.arrayUnion([
          {
            'text': comment,
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]);
      }

      await _firestore
          .collection('maintenance_requests')
          .doc(requestId)
          .update(updates);
    } catch (e) {
      print('Erreur lors de la mise à jour de la demande de maintenance: $e');
      rethrow;
    }
  }
}
