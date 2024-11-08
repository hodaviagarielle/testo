import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localink/FirestoreUpdateService.dart';
import 'package:localink/screens/owner/AnalyticsScreen.dart';
import 'package:localink/screens/owner/PropertyListScreen.dart';
import 'package:localink/screens/owner/ReceivedApplicationsScreen.dart';
import 'package:localink/screens/settings/SettingsScreen.dart';
import 'package:localink/screens/owner/TenantManagementScreen.dart';
import 'package:localink/services/auth_service.dart';
import 'package:localink/services/owner_dashboard_service.dart';
import 'package:localink/models/user.dart';
import 'package:localink/shared/OwnerDashboardCard.dart';




// Constantes de style
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

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionButton({
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
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
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

class NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String time;

  const NotificationItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppStyles.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        time,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({Key? key}) : super(key: key);

  @override
  _OwnerHomeScreenState createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final DashboardDataService _dashboardService = DashboardDataService();
  
  UserProfile? _userProfile;
  bool _isLoading = true;
  
  // États pour les données du dashboard
  Map<String, dynamic>? _propertyStats;
  int? _totalTenants;
  Map<String, dynamic>? _currentMonthPayments;
  List<Map<String, dynamic>>? _recentNotifications;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Chargement de toutes les données
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadUserProfile(),
        _loadDashboardData(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getCurrentUserProfile();
    setState(() => _userProfile = profile);
  }

 Future<void> _loadDashboardData() async {
  if (!mounted) return;

  // S'assurer que nous avons un profil utilisateur valide
  final profile = await _authService.getCurrentUserProfile();
  
  if (profile == null) {
    print('En attente du profil utilisateur...');
    // Attendre un court instant pour laisser le temps à Firebase de se synchroniser
    await Future.delayed(const Duration(milliseconds: 500));
    // Réessayer de charger le profil
    return _loadDashboardData();
  }

  try {
    print('Chargement des statistiques pour l\'utilisateur : ${profile.id}');

    final propertyStats = await _dashboardService.getPropertyStats(profile.id);
    if (!mounted) return;
    
    print('Statistiques des propriétés récupérées : $propertyStats');

    final totalTenants = await _dashboardService.getTotalTenants(profile.id);
    final currentMonthPayments = await _dashboardService.getCurrentMonthPayments(profile.id);
    final recentNotifications = await _dashboardService.getRecentNotifications(profile.id);

    if (!mounted) return;

    setState(() {
      _userProfile = profile;
      _propertyStats = propertyStats;
      _totalTenants = totalTenants;
      _currentMonthPayments = currentMonthPayments;
      _recentNotifications = recentNotifications;
    });

  } catch (e) {
    print('Erreur de chargement des données : $e');
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors du chargement des données: $e')),
    );
  }
} 
 
Widget _buildDashboard() {
  return RefreshIndicator(
    onRefresh: _loadDashboardData,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.elementSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec salutation
          Container(
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
                  'Bonjour, ${_userProfile?.displayName ?? 'Propriétaire'}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Voici le résumé de vos activités',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cartes de statistiques
          Container(
            decoration: AppStyles.cardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OwnerDashboardCard(
                          title: 'Propriétés',
                          value: '${_propertyStats?['totalProperties'] ?? 0}',
                          icon: Icons.home,
                          color: const Color(0xFF4A90E2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OwnerDashboardCard(
                          title: 'Locataires',
                          value: '$_totalTenants',
                          icon: Icons.people,
                          color: const Color(0xFF2ECC71),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OwnerDashboardCard(
                          title: 'Revenus/mois',
                          value: '${_propertyStats?['monthlyRevenue']?.toStringAsFixed(0) ?? 0}€',
                          icon: Icons.euro,
                          color: const Color(0xFFF39C12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OwnerDashboardCard(
                          title: 'Taux occupation',
                          value: '${_propertyStats?['occupancyRate'] ?? 0}%',
                          icon: Icons.pie_chart,
                          color: const Color(0xFF9B59B6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Actions rapides
          Container(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      ActionButton(
                        icon: Icons.add_home,
                        label: 'Ajouter une propriété',
                        onTap: () {
                          Navigator.pushNamed(context, '/add-property');
                        },
                      ),
                      const SizedBox(width: 12),
                      ActionButton(
                        icon: Icons.person_add,
                        label: 'Nouveau locataire',
                        onTap: () {
                          Navigator.pushNamed(context, '/add-tenant');
                        },
                      ),
                         const SizedBox(width: 12),
                      ActionButton(
                        icon: Icons.apartment,
                        label: 'Demandes reçues',
                        onTap: () {
                          if (_userProfile?.id != null) {
                           Navigator.pushNamed(
                              context, 
                              '/received-applications',
                              arguments: _userProfile!.id
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erreur: Profil utilisateur non disponible'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                       const SizedBox(width: 12),
                      ActionButton(
                        icon: Icons.update,
                        label: 'Mise à jour base de données',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DatabaseUpdateScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      ActionButton(
                        icon: Icons.document_scanner,
                        label: 'Scanner un document',
                        onTap: () {
                          // Scanner
                        },
                      ),
                      const SizedBox(width: 12),
                      ActionButton(
                        icon: Icons.payments,
                        label: 'Enregistrer un paiement',
                        onTap: () {
                          // Navigation
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notifications récentes
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notifications récentes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Navigation
                      },
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      label: const Text('Voir tout'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._buildNotificationsList(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
 
  List<Widget> _buildNotificationsList() {
    if (_recentNotifications == null || _recentNotifications!.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text('Aucune notification récente'),
        ),
      ];
    }

    return _recentNotifications!.map((notification) {
      IconData icon;
      switch (notification['type']) {
        case 'payment':
          icon = Icons.payment;
          break;
        case 'maintenance':
          icon = Icons.engineering;
          break;
        case 'contract':
          icon = Icons.assignment_late;
          break;
        default:
          icon = Icons.notifications;
      }

      return NotificationItem(
        icon: icon,
        title: notification['title'],
        description: notification['description'],
        time: _formatNotificationTime(notification['createdAt']),
      );
    }).toList();
  }

  String _formatNotificationTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final DateTime notifTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(notifTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}j';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildDashboard(),
      const PropertyListScreen(),
      const TenantManagementScreen(),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Tableau de bord' : 
                    _selectedIndex == 1 ? 'Mes propriétés' :
                    _selectedIndex == 2 ? 'Locataires' : 'Analyses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigation
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
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Propriétés',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Locataires',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analyses',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}