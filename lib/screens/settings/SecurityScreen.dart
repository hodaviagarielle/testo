import 'package:flutter/material.dart';
import 'package:localink/services/auth_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final AuthService _authService = AuthService();
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    setState(() => _isLoading = true);
    try {
      // Charger les paramètres de sécurité depuis le service d'authentification
      // À implémenter selon votre logique métier
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      setState(() {
        _twoFactorEnabled = false; // À remplacer par la vraie valeur
        _biometricEnabled = false; // À remplacer par la vraie valeur
      });
    } catch (e) {
      _showErrorDialog('Erreur lors du chargement des paramètres de sécurité');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  icon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  icon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  icon: Icon(Icons.lock_clock),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                _showErrorDialog('Les mots de passe ne correspondent pas');
                return;
              }
              try {
                // Implémenter la logique de changement de mot de passe
                await _authService.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe modifié avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                _showErrorDialog('Erreur lors du changement de mot de passe');
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTwoFactor(bool value) async {
    setState(() => _isLoading = true);
    try {
      // Implémenter la logique d'activation/désactivation de la 2FA
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      setState(() => _twoFactorEnabled = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Authentification à deux facteurs activée'
                : 'Authentification à deux facteurs désactivée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(
          'Erreur lors de la modification de l\'authentification à deux facteurs');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _isLoading = true);
    try {
      // Implémenter la logique d'activation/désactivation de la biométrie
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      setState(() => _biometricEnabled = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Authentification biométrique activée'
                : 'Authentification biométrique désactivée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(
          'Erreur lors de la modification de l\'authentification biométrique');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDevicesList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Appareils connectés',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: const Text('iPhone 13'),
            subtitle: const Text('Dernière connexion: Aujourd\'hui'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Implémenter la déconnexion de l'appareil
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.laptop),
            title: const Text('MacBook Pro'),
            subtitle: const Text('Dernière connexion: Hier'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Implémenter la déconnexion de l'appareil
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Section Mot de passe
                const Text(
                  'Mot de passe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Changer le mot de passe'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePassword,
                  ),
                ),
                const SizedBox(height: 24),

                // Section Authentification
                const Text(
                  'Authentification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.security),
                        title: const Text('Authentification à deux facteurs'),
                        subtitle: const Text(
                            'Ajouter une couche de sécurité supplémentaire'),
                        value: _twoFactorEnabled,
                        onChanged: _toggleTwoFactor,
                      ),
                      const Divider(),
                      SwitchListTile(
                        secondary: const Icon(Icons.fingerprint),
                        title: const Text('Authentification biométrique'),
                        subtitle:
                            const Text('Utiliser votre empreinte digitale ou Face ID'),
                        value: _biometricEnabled,
                        onChanged: _toggleBiometric,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section Appareils connectés
                const Text(
                  'Appareils',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.devices),
                    title: const Text('Appareils connectés'),
                    subtitle: const Text('Gérer les appareils connectés'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showDevicesList,
                  ),
                ),

                // Section Activité du compte
                const SizedBox(height: 24),
                const Text(
                  'Activité du compte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Historique des connexions'),
                    subtitle: const Text('Voir l\'activité récente du compte'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Implémenter la navigation vers l'historique des connexions
                      Navigator.pushNamed(context, '/security/login-history');
                    },
                  ),
                ),
              ],
            ),
    );
  }
}