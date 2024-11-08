
import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Politique de confidentialité',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Dernière mise à jour : [Date]\n\n'
              '1. Collecte des données\n'
              'Nous collectons les informations suivantes :\n'
              '- Informations de profil\n'
              '- Données de connexion\n'
              '- Informations de contact\n\n'
              '2. Utilisation des données\n'
              'Vos données sont utilisées pour :\n'
              '- Fournir nos services\n'
              '- Améliorer votre expérience\n'
              '- Vous contacter si nécessaire\n\n'
              // Ajoutez le reste de votre politique
            ),
          ],
        ),
      ),
    );
  }
}