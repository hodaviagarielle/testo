
import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conditions d\'utilisation',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Dernière mise à jour : [Date]\n\n'
              '1. Acceptation des conditions\n'
              'En utilisant notre application, vous acceptez les présentes conditions...\n\n'
              '2. Utilisation du service\n'
              'Vous vous engagez à utiliser le service de manière responsable...\n\n'
              // Ajoutez le reste de vos conditions
            ),
          ],
        ),
      ),
    );
  }
}
