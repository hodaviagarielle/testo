import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/models/payment.dart';
import 'package:localink/services/payment_service.dart';
import 'package:localink/services/tenant_service.dart';
import 'package:localink/services/lease_service.dart';
import 'package:localink/models/tenant.dart';
import 'package:localink/models/lease.dart';

// Constantes de style
class TenantManagementStyles {
  static const cardBorderRadius = 12.0;
  static const cardElevation = 2.0;
  static const cardPadding = EdgeInsets.all(16.0);
  static const spacingSmall = 8.0;
  static const spacingMedium = 16.0;
  static const spacingLarge = 24.0;
  
  static final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(cardBorderRadius),
  );
  
  static const statisticsIconSize = 32.0;
  static const statisticsValueSize = 24.0;
  
  static const tagPadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 6.0,
  );
  
  static final shimmerGradient = LinearGradient(
    colors: [
      Colors.grey[300]!,
      Colors.grey[100]!,
      Colors.grey[300]!,
    ],
    stops: const [0.1, 0.3, 0.4],
    begin: const Alignment(-1.0, -0.3),
    end: const Alignment(1.0, 0.3),
    tileMode: TileMode.clamp,
  );
}

class TenantManagementScreen extends StatefulWidget {
  const TenantManagementScreen({Key? key}) : super(key: key);

  @override
  _TenantManagementScreenState createState() => _TenantManagementScreenState();
}

class _TenantManagementScreenState extends State<TenantManagementScreen> {
  final TenantService _tenantService = TenantService();
  final LeaseService _leaseService = LeaseService();
  final PaymentService _paymentService = PaymentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, List<TenantWithLease>> _tenantsByProperty = {};
  Map<String, dynamic> _statistics = {
    'totalTenants': 0,
    'latePayments': 0,
    'expiringLeases': 0,
  };

 @override
  void initState() {
    super.initState();
    _loadData();
    
  }

  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Get all properties
      final propertiesSnapshot = await _firestore.collection('properties').get();
      Map<String, List<TenantWithLease>> tempTenantsByProperty = {};
      int totalTenants = 0;
      int latePayments = 0;
      int expiringLeases = 0;

      // Pour chaque propriété
      for (var property in propertiesSnapshot.docs) {
        final propertyData = property.data();
        // Utiliser 'title' au lieu de 'name'
        final propertyTitle = propertyData['title'] ?? 'Sans titre';
        
        // Get active leases for this property
        final leasesSnapshot = await _firestore
            .collection('leases')
            .where('propertyId', isEqualTo: property.id)
            .where('status', isEqualTo: 'active')
            .get();

        List<TenantWithLease> propertyTenants = [];

        // Pour chaque bail, obtenir les informations du locataire
        for (var leaseDoc in leasesSnapshot.docs) {
          final lease = Lease.fromMap(leaseDoc.id, leaseDoc.data());
          final tenant = await _tenantService.getAllTenant(lease.tenantId);

          // Vérifier le statut des paiements
          bool isLate = await _checkIfPaymentIsLate(lease);
          if (isLate) latePayments++;

          // Vérifier si le bail expire bientôt (dans les 30 jours)
          if (_isLeaseExpiringSoon(lease)) {
            expiringLeases++;
          }

          propertyTenants.add(
            TenantWithLease(
              tenant: tenant,
              lease: lease,
              isLate: isLate,
            ),
          );
          totalTenants++;
        }

        if (propertyTenants.isNotEmpty) {
          // Utiliser le titre de la propriété comme clé
          tempTenantsByProperty[propertyTitle] = propertyTenants;
        }
      }

      setState(() {
        _tenantsByProperty = tempTenantsByProperty;
        _statistics = {
          'totalTenants': totalTenants,
          'latePayments': latePayments,
          'expiringLeases': expiringLeases,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
        );
      }
    }
  }
  
  Future<bool> _checkIfPaymentIsLate(Lease lease) async {
    try {
      // Obtenir tous les paiements pour ce bail
      final payments = await _paymentService.getTenantPayments(lease.tenantId);
      
      // Filtrer pour obtenir uniquement les paiements de type 'rent'
      final rentPayments = payments.where((p) => p.type == 'rent').toList();
      
      if (rentPayments.isEmpty) return true;
      
      // Trier les paiements par date (le plus récent en premier)
      rentPayments.sort((a, b) => b.date.compareTo(a.date));
      
      final lastPayment = rentPayments.first;
      final today = DateTime.now();
      
      // Vérifier si le dernier paiement correspond au mois en cours
      return today.day > 5 && 
             (lastPayment.date.month != today.month ||
              lastPayment.date.year != today.year);
    } catch (e) {
      print('Erreur lors de la vérification des paiements: $e');
      return true; // En cas d'erreur, considérer comme en retard par précaution
    }
  }

  bool _isLeaseExpiringSoon(Lease lease) {
    final today = DateTime.now();
    final daysUntilExpiration = lease.endDate.difference(today).inDays;
    return daysUntilExpiration <= 30 && daysUntilExpiration > 0;
  }


  Future<void> _deleteTenant(String tenantId, String propertyName) async {
    try {
      final leasesSnapshot = await _firestore
          .collection('leases')
          .where('tenantId', isEqualTo: tenantId)
          .get();

      final batch = _firestore.batch();

      for (var lease in leasesSnapshot.docs) {
        batch.update(lease.reference, {'status': 'terminated'});
      }

      batch.update(
        _firestore.collection('tenants').doc(tenantId),
        {'status': 'inactive'},
      );

      await batch.commit();
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Locataire supprimé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmation(String tenantId, String propertyName) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer ce locataire ? Cette action marquera le bail comme terminé.',
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Supprimer'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTenant(tenantId, propertyName);
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadPaymentStats(String ownerId, String tenantId) async {
    final currentMonth = DateTime.now();
    try {
      return await _paymentService.getPaymentStats(ownerId, currentMonth);
    } catch (e) {
      print('Erreur lors du chargement des statistiques de paiement: $e');
      return {
        'totalReceived': 0.0,
        'totalExpected': 0.0,
        'paymentRate': 0.0,
        'onTimePayments': 0,
        'latePayments': 0,
      };
    }
  }

 
void _showPaymentManagement(BuildContext context, Tenant tenant, Lease lease) {
  Navigator.pushNamed(
    context,
    '/payment-management',
    arguments: {
      'tenant': tenant,
      'lease': lease,
    },
  ).then((_) => _loadData()); 
}


Widget _buildTenantCard(TenantWithLease tenantData, String propertyName) {
  final tenant = tenantData.tenant;
  final lease = tenantData.lease;
  final statusColor = tenantData.isLate ? Colors.red : Colors.green;

  return Card(
    margin: const EdgeInsets.symmetric(
      horizontal: TenantManagementStyles.spacingMedium,
      vertical: TenantManagementStyles.spacingSmall,
    ),
    elevation: TenantManagementStyles.cardElevation,
    shape: TenantManagementStyles.cardShape,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(TenantManagementStyles.cardBorderRadius),
              topRight: Radius.circular(TenantManagementStyles.cardBorderRadius),
            ),
          ),
          child: Padding(
            padding: TenantManagementStyles.cardPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: TenantManagementStyles.spacingSmall),
                      Text(
                        'Appartement ${lease.propertyId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: TenantManagementStyles.tagPadding,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tenantData.isLate ? Icons.warning : Icons.check_circle,
                            color: statusColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tenantData.isLate ? 'Retard' : 'À jour',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (String value) {
                        switch (value) {
                          case 'edit_lease':
                            Navigator.pushNamed(
                              context,
                              '/edit-lease',
                              arguments: {'leaseId': lease.id, 'tenantId': tenant.id},
                            );
                            break;
                          case 'history':
                            Navigator.pushNamed(
                              context,
                              '/tenant-history',
                              arguments: {'tenantId': tenant.id},
                            );
                            break;
                          case 'delete':
                            _showDeleteConfirmation(tenant.id, propertyName);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'edit_lease',
                          child: Row(
                            children: [
                              Icon(Icons.edit_document),
                              SizedBox(width: 8),
                              Text('Modifier le bail'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'history',
                          child: Row(
                            children: [
                              Icon(Icons.history),
                              SizedBox(width: 8),
                              Text('Historique'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: TenantManagementStyles.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.email, tenant.email),
              _buildInfoRow(Icons.phone, tenant.phone),
              _buildInfoRow(
                Icons.calendar_today,
                'Du ${_formatDate(lease.startDate)} au ${_formatDate(lease.endDate)}',
              ),
              _buildInfoRow(
                Icons.euro,
                '${lease.monthlyRent}€/mois',
              ),
            ],
          ),
        ),
        _buildPaymentStats(lease.ownerId, tenant.id),
        Padding(
          padding: TenantManagementStyles.cardPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Gérer les paiements'),
                onPressed: () => _showPaymentManagement(context, tenant, lease),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantManagementStyles.spacingSmall),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: TenantManagementStyles.spacingSmall),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStats(String ownerId, String tenantId) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(TenantManagementStyles.cardBorderRadius),
          bottomRight: Radius.circular(TenantManagementStyles.cardBorderRadius),
        ),
      ),
      child: Padding(
        padding: TenantManagementStyles.cardPadding,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadPaymentStats(ownerId, tenantId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final stats = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques de paiement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TenantManagementStyles.spacingSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatistic(
                      'Taux',
                      '${stats['paymentRate'].toStringAsFixed(1)}%',
                      Icons.percent,
                      Colors.blue,
                    ),
                    _buildStatistic(
                      'À l\'heure',
                      stats['onTimePayments'].toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatistic(
                      'En retard',
                      stats['latePayments'].toString(),
                      Icons.warning,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatistic(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      margin: const EdgeInsets.all(TenantManagementStyles.spacingMedium),
      elevation: TenantManagementStyles.cardElevation,
      shape: TenantManagementStyles.cardShape,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: TenantManagementStyles.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vue d\'ensemble',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TenantManagementStyles.spacingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOverviewStat(
                    Icons.people,
                    _statistics['totalTenants'].toString(),
                    'Locataires',
                  ),
                  _buildOverviewStat(
                    Icons.warning,
                    _statistics['latePayments'].toString(),
                    'Retards',
                  ),
                  _buildOverviewStat(
                    Icons.event,
                    _statistics['expiringLeases'].toString(),
                    'Baux expirants',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: TenantManagementStyles.statisticsIconSize,
        ),
        const SizedBox(height: TenantManagementStyles.spacingSmall),
        Text(
          value,
          style: const TextStyle(
            fontSize: TenantManagementStyles.statisticsValueSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildStatisticsCard(),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = _tenantsByProperty.entries.elementAt(index);
                        return Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            title: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            children: entry.value
                                .map((tenantData) =>
                                    _buildTenantCard(tenantData, entry.key))
                                .toList(),
                          ),
                        );
                      },
                      childCount: _tenantsByProperty.length,
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/add-tenant').then((_) => _loadData());
        },
        icon: const Icon(Icons.person_add),
        label: const Text(' '),
        elevation: 4,
      ),
    );
  }
}

class TenantWithLease {
  final Tenant tenant;
  final Lease lease;
  final bool isLate;

  TenantWithLease({
    required this.tenant,
    required this.lease,
    required this.isLate,
  });
}