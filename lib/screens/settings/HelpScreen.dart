import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide et support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section FAQ
              const Text(
                'Questions fréquentes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildExpansionTile(
                'Comment créer une annonce ?',
                'Pour créer une annonce, rendez-vous dans la section "Mes biens" et '
                'appuyez sur le bouton "+". Suivez ensuite les étapes pour ajouter '
                'les informations de votre bien.',
              ),
              _buildExpansionTile(
                'Comment gérer mes documents ?',
                'Tous vos documents sont accessibles depuis la section "Documents". '
                'Vous pouvez y créer, signer et partager vos documents en quelques clics.',
              ),
              _buildExpansionTile(
                'Comment contacter un locataire ?',
                'Utilisez la messagerie intégrée accessible depuis le profil du '
                'locataire ou depuis la section "Messages".',
              ),

              const SizedBox(height: 32),

              // Section Guides
              const Text(
                'Guides d\'utilisation',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                context,
                icon: Icons.home,
                title: 'Guide du propriétaire',
                description: 'Tout savoir sur la gestion de vos biens',
                onTap: () => Navigator.pushNamed(context, '/guide/owner'),
              ),
              _buildGuideItem(
                context,
                icon: Icons.apartment,
                title: 'Guide du locataire',
                description: 'Comprendre toutes les fonctionnalités',
                onTap: () => Navigator.pushNamed(context, '/guide/tenant'),
              ),

              const SizedBox(height: 32),

              // Section Support
              const Text(
                'Besoin d\'aide supplémentaire ?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notre équipe support est là pour vous aider',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/contact'),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mail),
                            SizedBox(width: 8),
                            Text('Contactez-nous'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionTile(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(content),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}