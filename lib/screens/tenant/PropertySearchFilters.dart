import 'package:flutter/material.dart';
import 'package:localink/screens/tenant/PropertySearchScreen.dart';

class PropertySearchFiltersScreen extends StatefulWidget {
  const PropertySearchFiltersScreen({Key? key}) : super(key: key);

  @override
  _PropertySearchFiltersScreenState createState() => _PropertySearchFiltersScreenState();
}

class _PropertySearchFiltersScreenState extends State<PropertySearchFiltersScreen> {
  String _location = '';
  double _minPrice = 0;
  double _maxPrice = 0;
  int _minBedrooms = 0;
  int _minBathrooms = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtres de recherche'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ajouter les champs de filtre ici
            ElevatedButton(
              onPressed: () {
                // Appliquer les filtres et retourner à la page de recherche
                Navigator.pop(context, {
                  'location': _location,
                  'minPrice': _minPrice,
                  'maxPrice': _maxPrice,
                  'minBedrooms': _minBedrooms,
                  'minBathrooms': _minBathrooms,
                });
              },
              child: const Text('Appliquer les filtres'),
            ),
          ],
        ),
      ),
    );
  }
}