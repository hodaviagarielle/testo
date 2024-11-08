import 'package:flutter/material.dart';
import 'package:localink/services/tenant_property_service.dart';
import 'package:localink/services/auth_service.dart';
import 'package:localink/models/tenant_property.dart';
import 'package:intl/intl.dart';

class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({Key? key}) : super(key: key);

  @override
  _SavedSearchesScreenState createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  final TenantPropertyService _propertyService = TenantPropertyService();
  final AuthService _authService = AuthService();
  List<TenantPropertySearch>? _savedSearches;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile != null) {
        setState(() => _userId = userProfile.id);
        _loadSavedSearches();
      }
    } catch (e) {
      _showError('Erreur lors de l\'initialisation: $e');
    }
  }

  void _loadSavedSearches() {
    if (_userId == null) return;

    _propertyService.getSavedSearches(_userId!).listen(
      (searches) {
        setState(() {
          _savedSearches = searches;
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() => _isLoading = false);
        _showError('Erreur lors du chargement des recherches: $error');
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

 String _formatPrice(double price) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    return formatter.format(price);
  }

  String _formatAmenities(List<String> amenities) {
    if (amenities.isEmpty) return 'Aucun équipement spécifié';
    if (amenities.length <= 2) return amenities.join(', ');
    return '${amenities.take(2).join(', ')} +${amenities.length - 2}';
  }

 void _deleteSearch(String searchId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer la recherche'),
      content: const Text('Êtes-vous sûr de vouloir supprimer cette recherche sauvegardée ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              if (_userId != null && searchId.isNotEmpty) {
                await _propertyService.deleteSavedSearch(_userId!, searchId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recherche supprimée')),
                );
              }
            } catch (e) {
              _showError('Erreur lors de la suppression: $e');
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
  void _executeSearch(TenantPropertySearch search) {
    Navigator.pushNamed(
      context,
      '/property-search',
      arguments: search,
    );
  }

  Widget _buildSearchCard(TenantPropertySearch search) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    search.location,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete' && search.id != null) {
                      _deleteSearch(search.id!);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget: ${_formatPrice(search.minPrice)} - ${_formatPrice(search.maxPrice)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${search.minBedrooms ?? 0} ch. min',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Surface min: ${search.minSurface.round()}m²',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${search.minBathrooms ?? 0} sdb. min',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (search.amenities.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Équipements: ${_formatAmenities(search.amenities)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Créée le ${DateFormat('dd/MM/yyyy').format(search.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                ElevatedButton.icon(
                  onPressed: () => _executeSearch(search),
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('Rechercher'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherches sauvegardées'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedSearches == null || _savedSearches!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune recherche sauvegardée',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/property-search');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Nouvelle recherche'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadSavedSearches(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _savedSearches!.length,
                    itemBuilder: (context, index) {
                      return _buildSearchCard(_savedSearches![index]);
                    },
                  ),
                ),
      floatingActionButton: _savedSearches?.isNotEmpty == true
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/property-search');
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}