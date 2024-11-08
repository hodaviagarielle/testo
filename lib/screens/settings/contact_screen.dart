
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactez-nous'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nous contacter',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Par email'),
              subtitle: const Text('support@votreapp.com'),
              onTap: () => launchUrl(Uri.parse('mailto:support@votreapp.com')),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Par téléphone'),
              subtitle: const Text('01 23 45 67 89'),
              onTap: () => launchUrl(Uri.parse('tel:0123456789')),
            ),
            // Ajoutez d'autres moyens de contact si nécessaire
          ],
        ),
      ),
    );
  }
}