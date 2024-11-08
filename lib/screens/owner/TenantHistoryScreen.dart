import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/models/tenant.dart';
import 'package:localink/models/lease.dart';
import 'package:localink/models/payment.dart';
import 'package:localink/services/tenant_service.dart';
import 'package:localink/services/lease_service.dart';
import 'package:localink/services/payment_service.dart';

// Styles réutilisables
class AppStyles {
  static const cardBorderRadius = 16.0;
  static const elementSpacing = 16.0;
  static const cardElevation = 2.0;
  
  static const gradientColors = [
    Color(0xFF4A90E2), // Bleu principal
    Color(0xFF357ABD), // Bleu secondaire
  ];
  
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(cardBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class TenantHistoryScreen extends StatefulWidget {
  const TenantHistoryScreen({Key? key}) : super(key: key);

  @override
  _TenantHistoryScreenState createState() => _TenantHistoryScreenState();
}

class _TenantHistoryScreenState extends State<TenantHistoryScreen> {
  final TenantService _tenantService = TenantService();
  final LeaseService _leaseService = LeaseService();
  final PaymentService _paymentService = PaymentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  late Tenant _tenant;
  List<Lease> _leases = [];
  List<Payment> _payments = [];
  List<Map<String, dynamic>> _maintenanceRequests = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null && arguments.containsKey('tenantId')) {
        _loadTenantHistory(arguments['tenantId']);
      }
    });
  }

  Future<void> _loadTenantHistory(String tenantId) async {
    setState(() => _isLoading = true);
    try {
      _tenant = await _tenantService.getTenant(tenantId);
      _leases = await _leaseService.getTenantLeases(tenantId);
      _payments = await _paymentService.getTenantPayments(tenantId);

      final maintenanceSnapshot = await _firestore
          .collection('maintenance_requests')
          .where('tenantId', isEqualTo: tenantId)
          .orderBy('createdAt', descending: true)
          .get();

      _maintenanceRequests = maintenanceSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
                'createdAt': (doc.data()['createdAt'] as Timestamp).toDate(),
              })
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement de l\'historique: $e')),
        );
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppStyles.elementSpacing),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppStyles.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppStyles.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historique Locataire',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Consultez l\'historique complet du locataire',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantInfoCard() {
    return Container(
      margin: const EdgeInsets.all(AppStyles.elementSpacing),
      decoration: AppStyles.cardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF4A90E2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tenant.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tenant.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoChip(Icons.phone, 'Téléphone', _tenant.phone),
            _buildInfoChip(Icons.euro, 'Revenus', '${_tenant.monthlyIncome}€/mois'),
            _buildInfoChip(Icons.badge, 'Statut', _tenant.status),
            _buildInfoChip(
              Icons.calendar_today,
              'Date d\'ajout',
              _tenant.createdAt.toString().split(' ')[0],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF4A90E2),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildLeaseHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppStyles.elementSpacing),
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Color(0xFF4A90E2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Historique des baux',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _leases.length,
            itemBuilder: (context, index) {
              final lease = _leases[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('properties').doc(lease.propertyId).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Text('Chargement...');
                          final propertyData = snapshot.data!.data() as Map<String, dynamic>?;
                          return Text(
                            propertyData?['title'] ?? 'Propriété inconnue',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildLeaseInfoRow(
                        'Période',
                        '${lease.startDate.toString().split(' ')[0]} - ${lease.endDate.toString().split(' ')[0]}',
                      ),
                      _buildLeaseInfoRow('Loyer', '${lease.monthlyRent}€/mois'),
                      _buildLeaseInfoRow('Caution', '${lease.securityDeposit}€'),
                      _buildStatusChip(lease.status),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaseInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'terminated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPaymentHistory() {
    return Container(
      margin: const EdgeInsets.all(AppStyles.elementSpacing),
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Color(0xFF4A90E2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Historique des paiements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _payments.length,
            itemBuilder: (context, index) {
              final payment = _payments[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: payment.status == 'received'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      payment.status == 'received' ? Icons.check_circle : Icons.pending,
                      color: payment.status == 'received' ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(
                    payment.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Montant: ${payment.amount}€'),
                      Text('Date: ${payment.date.toString().split(' ')[0]}'),
                      _buildStatusChip(payment.status),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceHistory() {
    return Container(
      margin: const EdgeInsets.all(AppStyles.elementSpacing),
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.build,
                    color: Color(0xFF4A90E2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Demandes de maintenance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _maintenanceRequests.length,
            itemBuilder: (context, index) {
              final request = _maintenanceRequests[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getMaintenanceColor(request['status']).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getMaintenanceIcon(request['status']),
                      color: _getMaintenanceColor(request['status']),
                    ),
                  ),
                  title: Text(
                    request['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(request['description'] ?? ''),
                      Text(
                        'Date: ${request['createdAt'].toString().split(' ')[0]}',
                      ),
                      _buildStatusChip(request['status']),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getMaintenanceIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.engineering;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.error;
    }
  }

  Color _getMaintenanceColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique du locataire'),
        elevation: 0,
        backgroundColor: const Color(0xFF4A90E2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTenantHistory(_tenant.id),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadTenantHistory(_tenant.id),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildTenantInfoCard(),
                    _buildLeaseHistory(),
                    _buildPaymentHistory(),
                    _buildMaintenanceHistory(),
                    const SizedBox(height: AppStyles.elementSpacing),
                  ],
                ),
              ),
            ),
    );
  }
}