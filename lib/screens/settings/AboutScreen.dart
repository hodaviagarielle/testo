import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version} (${packageInfo.buildNumber})';
      _isLoading = false;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Logo et nom de l'application
                  Center(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 120,
                            height: 120,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Localink',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Version $_version',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Description de l'application
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'À propos de Localink',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Localink est une application qui facilite la mise en relation entre propriétaires et locataires. Notre mission est de simplifier la gestion locative tout en créant une communauté de confiance.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Fonctionnalités principales
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Fonctionnalités principales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem(
                    icon: Icons.home,
                    title: 'Gestion des biens',
                    description: 'Gérez facilement vos propriétés et locations',
                  ),
                  _buildFeatureItem(
                    icon: Icons.description,
                    title: 'Documents digitaux',
                    description: 'Création et signature de documents en ligne',
                  ),
                  _buildFeatureItem(
                    icon: Icons.message,
                    title: 'Communication',
                    description: 'Messagerie intégrée entre propriétaires et locataires',
                  ),
                  const SizedBox(height: 32),

                  // Liens utiles
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Liens utiles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLinkButton(
                    icon: Icons.privacy_tip,
                    title: 'Politique de confidentialité',
                    onTap: () => Navigator.pushNamed(context, '/privacy'),
                  ),
                  _buildLinkButton(
                    icon: Icons.description,
                    title: 'Conditions d\'utilisation',
                    onTap: () => Navigator.pushNamed(context, '/terms'),
                  ),
                  _buildLinkButton(
                    icon: Icons.mail,
                    title: 'Contactez-nous',
                    onTap: () => Navigator.pushNamed(context, '/contact'),
                  ),
                  const SizedBox(height: 32),

                  // Copyright
                  Text(
                    '© ${DateTime.now().year} Localink. Tous droits réservés.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}