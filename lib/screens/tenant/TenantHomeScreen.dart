import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localink/screens/tenant/PropertySearchFilters.dart';
import 'package:localink/services/TenantDashboardService.dart';
import 'package:localink/services/auth_service.dart';
import 'package:localink/models/user.dart';

class AppStyles {
  static const cardBorderRadius = 16.0;
  static const elementSpacing = 16.0;
  static const cardElevation = 2.0;
  
  static const gradientColors = [
    Color(0xFF4A90E2), // Primary blue
    Color(0xFF357ABD), // Secondary blue
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

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.cardBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppStyles.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppStyles.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: AppStyles.gradientColors[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({Key? key}) : super(key: key);

  @override
  _TenantHomeScreenState createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final TenantDashboardService _dashboardService = TenantDashboardService();
  
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _hasActiveLease = false;
  
  // États existants
  Map<String, dynamic>? _rentalInfo;
  List<Map<String, dynamic>>? _maintenanceRequests;
  Map<String, dynamic>? _paymentHistory;
  List<Map<String, dynamic>>? _announcements;
  
  // Nouveaux états pour la recherche
  List<Map<String, dynamic>>? _savedSearches;
  List<Map<String, dynamic>>? _propertyResults;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _checkActiveLease();
  }

Future<void> _checkActiveLease() async {
  final profile = await _authService.getCurrentUserProfile();
  if (profile != null) {
    print('Checking lease for profile: ${profile.id}');
    final hasLease = await _dashboardService.checkActiveLease(profile.id);
    print('Has active lease: $hasLease');
    if (mounted) {
      setState(() {
        _hasActiveLease = hasLease;
      });
      print('_hasActiveLease state updated to: $_hasActiveLease');
    }
  }
}

  
  Future<void> _loadAllData() async {
    
    setState(() => _isLoading = true);
    try {
      print('Loading user profile...');
      final profile = await _authService.getCurrentUserProfile();
      if (profile != null) {
        print('User profile loaded: $profile');

        print('Loading rental info...');
        final rentalInfo = await _dashboardService.getRentalInfo(profile.id);
        print('Rental info loaded: $rentalInfo');

        print('Loading maintenance requests...');
        final maintenanceRequests = await _dashboardService.getMaintenanceRequests(profile.id);
        print('Maintenance requests loaded: $maintenanceRequests');

        print('Loading payment history...');
        final paymentHistory = await _dashboardService.getPaymentHistory(profile.id);
        print('Payment history loaded: $paymentHistory');

        print('Loading announcements...');
        final announcements = await _dashboardService.getAnnouncements(profile.id);
        print('Announcements loaded: $announcements');

        setState(() {
          _userProfile = profile;
          _rentalInfo = rentalInfo;
          _maintenanceRequests = maintenanceRequests;
          _paymentHistory = paymentHistory;
          _announcements = announcements;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error loading data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
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
          Text(
            'Bonjour, ${_userProfile?.displayName ?? 'Locataire'}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bienvenue dans votre espace locataire',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildPropertySearch() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: AppStyles.cardDecoration(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rechercher une propriété',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Entrez une ville ou un quartier',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.cardBorderRadius),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Rechercher'),
                onPressed: () {
                  Navigator.pushNamed(context, '/property-search');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // Ouvrir les filtres de recherche
                Navigator.pushNamed(context, '/property-search-filters');
              },
              tooltip: 'Filtres',
            ),
          ],
        ),
      ],
    ),
  );
}
/*
  Widget _buildSavedSearches() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recherches sauvegardées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/saved-searches');
                },
                child: const Text('Voir tout'),
              ),
            ],
          ),
          if (_savedSearches?.isNotEmpty ?? false)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _savedSearches!.take(3).length,
              itemBuilder: (context, index) {
                final search = _savedSearches![index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(search['location']),
                  subtitle: Text('${search['priceRange']} - ${search['rooms']} pièces'),
                  trailing: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.9,
                        minChildSize: 0.5,
                        maxChildSize: 0.9,
                        expand: false,
                        builder: (context, scrollController) => PropertySearchFilters(
                          onApplyFilters: (filters) {
                            // Ici, vous pouvez gérer l'application des filtres
                            // Par exemple, mettre à jour l'état de votre recherche
                            setState(() {
                              // Mettre à jour les résultats de recherche en fonction des filtres
                              _propertyResults = []; // À implémenter selon vos besoins
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                );
              },
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Aucune recherche sauvegardée'),
              ),
            ),
        ],
      ),
    );
  }
*/
  Widget _buildCurrentRental() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre location actuelle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.home,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _rentalInfo?['address'] ?? 'Adresse non disponible',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                context,
                'Loyer',
                '${_rentalInfo?['rent'] ?? 0}€/mois',
                Icons.euro,
              ),
              _buildInfoItem(
                context,
                'Prochain paiement',
                _rentalInfo?['nextPaymentDate'] ?? '-',
                Icons.calendar_today,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaseDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Détails du bail',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/lease-details');
                },
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLeaseInfoItem(
            'Date de début',
            _rentalInfo?['leaseStart'] ?? '-',
            Icons.calendar_today,
          ),
          _buildLeaseInfoItem(
            'Date de fin',
            _rentalInfo?['leaseEnd'] ?? '-',
            Icons.event,
          ),
          _buildLeaseInfoItem(
            'Dépôt de garantie',
            '${_rentalInfo?['deposit'] ?? 0}€',
            Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaseInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceRequests() {
    if (_maintenanceRequests == null || _maintenanceRequests!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Demandes de maintenance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/maintenance-requests');
                },
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _maintenanceRequests!.take(3).length,
            itemBuilder: (context, index) {
              final request = _maintenanceRequests![index];
              return ListTile(
                leading: Icon(
                  Icons.build_circle,
                  color: _getStatusColor(request['status']),
                ),
                title: Text(request['title']),
                subtitle: Text(request['status']),
                trailing: Text(request['date']),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Actions rapides',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.flash_on,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                QuickActionButton(
                  icon: Icons.build,
                  label: 'Signaler un problème',
                  onTap: () {
                    Navigator.pushNamed(context, '/report-issue');
                  },
                ),
                const SizedBox(width: 12),
                QuickActionButton(
                  icon: Icons.receipt_long,
                  label: 'Mes documents',
                  onTap: () {
                    Navigator.pushNamed(context, '/documents');
                  },
                ),
                const SizedBox(width: 12),
                QuickActionButton(
                  icon: Icons.payment,
                  label: 'Payer mon loyer',
                  onTap: () {
                    Navigator.pushNamed(context, '/payment');
                  },
                ),
                const SizedBox(width: 12),
                QuickActionButton(
                  icon: Icons.message,
                  label: 'Contacter le propriétaire',
                  onTap: () {
                    Navigator.pushNamed(context, '/contact-owner');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en attente':
        return Colors.orange;
      case 'en cours':
        return Colors.blue;
      case 'terminé':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.elementSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue existant
            _buildWelcomeHeader(),
            
            const SizedBox(height: 24),

            // Nouvelle section : Recherche de propriétés ou Bail actif
            _hasActiveLease ? _buildCurrentRental() : _buildPropertySearch(),

            const SizedBox(height: 24),

            // Actions rapides existantes avec nouvelles options
            _buildQuickActions(),

            const SizedBox(height: 24),
/*
            // Nouvelle section : Recherches sauvegardées
            if (!_hasActiveLease) _buildSavedSearches(),
*/
            if (_hasActiveLease) ...[
              // Section de maintenance existante
              _buildMaintenanceRequests(),
              
              const SizedBox(height: 24),

              // Nouvelle section : Détails du bail
              _buildLeaseDetails(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon espace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          if (!_hasActiveLease)
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Recherche',
              
            )
          else ...[
            const BottomNavigationBarItem(
              icon: Icon(Icons.build),
              label: 'Maintenance',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'Documents',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.payment),
              label: 'Paiements',
            ),
          ],
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
            if (!_hasActiveLease && index == 1) {
              Navigator.pushNamed(context, '/property-search');
            }
        },
      ),
    );
  }
}