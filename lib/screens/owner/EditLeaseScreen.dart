import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localink/models/lease.dart';
import 'package:localink/models/tenant.dart';
import 'package:localink/services/lease_service.dart';
import 'package:localink/services/tenant_service.dart';

class EditLeaseScreen extends StatefulWidget {
  final String leaseId;

  const EditLeaseScreen({Key? key, required this.leaseId}) : super(key: key);

  @override
  _EditLeaseScreenState createState() => _EditLeaseScreenState();
}

class _EditLeaseScreenState extends State<EditLeaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final LeaseService _leaseService = LeaseService();
  final TenantService _tenantService = TenantService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  late Lease _lease;
  late Tenant _tenant;

  // Form field controllers
  final TextEditingController _monthlyRentController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _loadLeaseData();
  }

  Future<void> _loadLeaseData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      _lease = await _leaseService.getLease(widget.leaseId);
      _tenant = await _tenantService.getTenant(_lease.tenantId);

      _monthlyRentController.text = _lease.monthlyRent.toString();
      _depositController.text = _lease.securityDeposit.toString();
      _startDate = _lease.startDate;
      _endDate = _lease.endDate;

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
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

      final updatedLease = Lease(
        id: _lease.id,
        tenantId: _lease.tenantId,
        propertyId: _lease.propertyId,
        ownerId: _lease.ownerId,
        startDate: _startDate,
        endDate: _endDate,
        monthlyRent: double.parse(_monthlyRentController.text),
        securityDeposit: double.parse(_depositController.text),
        status: _lease.status,
        paymentIds: _lease.paymentIds,
        createdAt: _lease.createdAt,
      );

      await _leaseService.updateLease(updatedLease);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bail mis à jour avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour du bail: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _showTerminateConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la résiliation'),
          content: const Text(
            'Êtes-vous sûr de vouloir résilier ce bail ? Cette action ne peut pas être annulée.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Résilier'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(context).pop();
                await _terminateLease();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _terminateLease() async {
    setState(() => _isLoading = true);
    try {
      final terminatedLease = Lease(
        id: _lease.id,
        tenantId: _lease.tenantId,
        propertyId: _lease.propertyId,
        ownerId: _lease.ownerId,
        startDate: _lease.startDate,
        endDate: DateTime.now(),
        monthlyRent: _lease.monthlyRent,
        securityDeposit: _lease.securityDeposit,
        status: 'terminated',
        paymentIds: _lease.paymentIds,
        createdAt: _lease.createdAt,
      );

      await _leaseService.updateLease(terminatedLease);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bail résilié avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la résiliation du bail: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                children: [
                  Text(
                    date.toString().split(' ')[0],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_tenant.firstName} ${_tenant.lastName}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_tenant.email),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Téléphone: ${_tenant.phone}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le bail'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            color: Colors.red,
            onPressed: _showTerminateConfirmation,
            tooltip: 'Résilier le bail',
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Informations du locataire'),
                _buildTenantCard(),
                
                _buildSectionTitle('Période du bail'),
                _buildDateSelector(
                  'Date de début',
                  _startDate,
                  () => _selectDate(context, true),
                ),
                const SizedBox(height: 12),
                _buildDateSelector(
                  'Date de fin',
                  _endDate,
                  () => _selectDate(context, false),
                ),
                
                _buildSectionTitle('Conditions financières'),
                _buildTextField(
                  label: 'Loyer mensuel (€)',
                  controller: _monthlyRentController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value?.isEmpty == true ? 'Ce champ est requis' : null,
                ),
                _buildTextField(
                  label: 'Caution (€)',
                  controller: _depositController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value?.isEmpty == true ? 'Ce champ est requis' : null,
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Mettre à jour le bail',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _monthlyRentController.dispose();
    _depositController.dispose();
    super.dispose();
  }
}