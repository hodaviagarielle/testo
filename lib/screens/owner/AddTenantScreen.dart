import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localink/models/tenant.dart';
import 'package:localink/models/lease.dart';
import 'package:localink/services/tenant_service.dart';
import 'package:localink/services/lease_service.dart';

class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({Key? key}) : super(key: key);

  @override
  _AddTenantScreenState createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final TenantService _tenantService = TenantService();
  final LeaseService _leaseService = LeaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _selectedPropertyId;
  String? _existingTenantId;
  List<Map<String, dynamic>> _properties = [];

  // Form field controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _monthlyIncomeController = TextEditingController();
  final TextEditingController _monthlyRentController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));

  // Styles constants
  static const double _spacing = 20.0;
  static const double _borderRadius = 12.0;
  final _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(_borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        spreadRadius: 1,
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      // Récupération de l'ID de l'utilisateur connecté
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Modification de la requête pour filtrer par ownerId
      final snapshot = await _firestore
          .collection('properties')
          .where('ownerId', isEqualTo: currentUser.uid)
          .get();
      
      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _properties = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vous n\'avez aucune propriété. Veuillez d\'abord en ajouter une.')),
          );
        }
        return;
      }

      final loadedProperties = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Sans titre',
          'address': data['address'] ?? 'Adresse non spécifiée',
          'ownerId': data['ownerId'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _properties = loadedProperties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des propriétés: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: isStartDate ? DateTime.now() : _startDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 365));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

 Future<void> _findTenant() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un email')),
      );
      return;
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final tenant = await _tenantService.getTenant(_emailController.text);
      // Stocker l'ID du tenant trouvé
      _existingTenantId = tenant.id;
      
      setState(() {
        _firstNameController.text = tenant.firstName;
        _lastNameController.text = tenant.lastName;
        _phoneController.text = tenant.phone;
        _monthlyIncomeController.text = tenant.monthlyIncome.toStringAsFixed(2);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Locataire trouvé ! Les informations ont été pré-remplies.')),
      );
    } catch (e) {
      _existingTenantId = null; // Réinitialiser en cas d'erreur
      String errorMessage;
      if (e.toString().contains('Aucun locataire trouvé')) {
        errorMessage = 'Aucun locataire trouvé avec cet email. Un nouveau locataire sera créé.';
      } else {
        errorMessage = 'Erreur lors de la recherche du locataire: $e';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      String tenantId;

      // Si on n'a pas trouvé de tenant existant, on en crée un nouveau
      if (_existingTenantId == null) {
        final tenant = Tenant(
          id: '',
          userId: currentUser.uid,
          propertyId: _selectedPropertyId!,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          monthlyIncome: double.parse(_monthlyIncomeController.text),
          documents: [],
          status: 'active',
          createdAt: DateTime.now(),
        );

        tenantId = await _tenantService.createTenant(tenant);
      } else {
        // Utiliser l'ID du tenant existant
        tenantId = _existingTenantId!;
        
        // Mettre à jour les informations du tenant si nécessaire
        await _tenantService.updateTenant(tenantId, {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'phone': _phoneController.text,
          'monthlyIncome': double.parse(_monthlyIncomeController.text),
          'status': 'active',
        });
      }

      // Créer le nouveau bail avec l'ID du tenant (existant ou nouveau)
      final lease = Lease(
        id: '',
        tenantId: tenantId,
        propertyId: _selectedPropertyId!,
        ownerId: currentUser.uid,
        startDate: _startDate,
        endDate: _endDate,
        monthlyRent: double.parse(_monthlyRentController.text),
        securityDeposit: double.parse(_depositController.text),
        status: 'active',
        paymentIds: [],
        createdAt: DateTime.now(),
      );

      await _leaseService.createLease(lease);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_existingTenantId == null 
          ? 'Nouveau locataire ajouté avec succès' 
          : 'Nouveau bail créé pour le locataire existant')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'opération: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  InputDecoration _buildInputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }


   Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyDropdown() {
      if (_properties.isEmpty) {
        return Container(
          decoration: _cardDecoration,
          padding: const EdgeInsets.all(16.0),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aucune propriété disponible. Veuillez d\'abord ajouter une propriété.',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        );
      }
        return DropdownButtonFormField<String>(
      value: _selectedPropertyId,
      decoration: _buildInputDecoration('Propriété *', icon: Icons.home),
      items: _properties.map<DropdownMenuItem<String>>((property) {
        return DropdownMenuItem<String>(
          value: property['id'],
          child: Text(
            '${property['title']} - ${property['address']}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedPropertyId = newValue;
        });
      },
      validator: (value) => value == null ? 'Veuillez sélectionner une propriété' : null,
    );
  }


Widget _buildDateSelector() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Période du bail',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    'Début: ${_startDate.toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_borderRadius),
                    ),
                  ),
                  onPressed: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    'Fin: ${_endDate.toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_borderRadius),
                    ),
                  ),
                  onPressed: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajouter un locataire',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey[100],
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(_spacing),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle('Informations de la propriété'),
                      _buildPropertyDropdown(),
                      _buildSectionTitle('Informations du locataire'),
                      Container(
                        decoration: _cardDecoration,
                        padding: const EdgeInsets.all(_spacing),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: _buildInputDecoration('Email *', icon: Icons.email),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty == true) return 'Ce champ est requis';
                                if (!value!.contains('@')) return 'Email invalide';
                                return null;
                              },
                            ),
                            const SizedBox(height: _spacing),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.search),
                                    label: const Text('Rechercher le locataire'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(_borderRadius),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed: _findTenant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: _spacing),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: _buildInputDecoration('Prénom *', icon: Icons.person),
                              validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
                            ),
                            const SizedBox(height: _spacing),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: _buildInputDecoration('Nom *', icon: Icons.person_outline),
                              validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
                            ),
                            const SizedBox(height: _spacing),
                            TextFormField(
                              controller: _phoneController,
                              decoration: _buildInputDecoration('Téléphone *', icon: Icons.phone),
                              keyboardType: TextInputType.phone,
                              validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
                            ),
                            const SizedBox(height: _spacing),
                            TextFormField(
                              controller: _monthlyIncomeController,
                              decoration: _buildInputDecoration('Revenus mensuels (€) *', icon: Icons.euro),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
                            ),
                          ],
                        ),
                      ),
                      _buildSectionTitle('Informations du bail'),
                      Container(
                        decoration: _cardDecoration,
                        padding: const EdgeInsets.all(_spacing),
                        child: Column(
                          children: [
                            _buildDateSelector(),
                            const SizedBox(height: _spacing),
                            TextFormField(
                              controller: _monthlyRentController,
                              decoration: _buildInputDecoration('Loyer mensuel (€) *', icon: Icons.money),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
                            ),
                            const SizedBox(height: _spacing),
                            TextFormField(
                              controller: _depositController,
                              decoration: _buildInputDecoration('Caution (€) *', icon: Icons.account_balance_wallet),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Enregistrer le locataire',
                          style: TextStyle(fontSize: 16,color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_borderRadius),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _submitForm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _monthlyIncomeController.dispose();
    _monthlyRentController.dispose();
    _depositController.dispose();
    super.dispose();
  }
}