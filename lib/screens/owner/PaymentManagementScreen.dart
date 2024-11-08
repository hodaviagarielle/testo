import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localink/models/payment.dart';
import 'package:localink/services/payment_service.dart';
import 'package:localink/models/tenant.dart';
import 'package:localink/models/lease.dart';

class PaymentManagementScreen extends StatefulWidget {
  final Tenant tenant;
  final Lease lease;

  const PaymentManagementScreen({
    Key? key,
    required this.tenant,
    required this.lease,
  }) : super(key: key);

  @override
  _PaymentManagementScreenState createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  late TabController _tabController;
  bool _isLoading = false;
  List<Payment> _payments = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final payments = await _paymentService.getTenantPayments(widget.tenant.id);
      final stats = await _paymentService.getPaymentStats(
        widget.lease.ownerId,
        DateTime.now(),
      );
      
      setState(() {
        _payments = payments;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement des paiements: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _showAddPaymentDialog() async {
    final formKey = GlobalKey<FormState>();
    double? amount;
    String type = 'rent';
    String? description;
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un paiement'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Montant (€)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un montant';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Veuillez entrer un nombre valide';
                    }
                    return null;
                  },
                  onSaved: (value) => amount = double.parse(value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['rent', 'deposit', 'fees'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text({
                        'rent': 'Loyer',
                        'deposit': 'Dépôt',
                        'fees': 'Frais',
                      }[value]!),
                    );
                  }).toList(),
                  onChanged: (value) => type = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                  onSaved: (value) => description = value,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2025),
                    );
                    if (pickedDate != null) {
                      selectedDate = pickedDate;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Ajouter'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.of(context).pop();

                setState(() => _isLoading = true);
                try {
                  final newPayment = Payment(
                    id: '', // Will be set by Firestore
                    propertyId: widget.lease.propertyId,
                    tenantId: widget.tenant.id,
                    ownerId: widget.lease.ownerId,
                    amount: amount!,
                    date: selectedDate,
                    status: 'pending',
                    type: type,
                    description: description,
                    createdAt: DateTime.now(),
                  );

                  await _paymentService.createPayment(newPayment);
                  await _loadPayments();
                } catch (e) {
                  _showError('Erreur lors de la création du paiement: $e');
                }
                setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final paymentRate = _stats['paymentRate'] ?? 0.0;
    final onTimePayments = _stats['onTimePayments'] ?? 0;
    final latePayments = _stats['latePayments'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques des paiements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.payment,
                        value: '${paymentRate.toStringAsFixed(1)}%',
                        label: 'Taux de paiement',
                        color: Colors.blue,
                      ),
                      _buildStatItem(
                        icon: Icons.check_circle,
                        value: onTimePayments.toString(),
                        label: 'À l\'heure',
                        color: Colors.green,
                      ),
                      _buildStatItem(
                        icon: Icons.warning,
                        value: latePayments.toString(),
                        label: 'En retard',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations sur le bail',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLeaseInfo('Loyer mensuel', '${widget.lease.monthlyRent}€'),
                  _buildLeaseInfo('Dépôt de garantie', '${widget.lease.securityDeposit}€'),
                  _buildLeaseInfo(
                    'Début du bail',
                    '${widget.lease.startDate.day}/${widget.lease.startDate.month}/${widget.lease.startDate.year}',
                  ),
                  _buildLeaseInfo(
                    'Fin du bail',
                    '${widget.lease.endDate.day}/${widget.lease.endDate.month}/${widget.lease.endDate.year}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLeaseInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final isLate = payment.status == 'late';
        final isPending = payment.status == 'pending';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              payment.type == 'rent'
                  ? Icons.home
                  : payment.type == 'deposit'
                      ? Icons.account_balance_wallet
                      : Icons.receipt,
              color: isLate
                  ? Colors.red
                  : isPending
                      ? Colors.orange
                      : Colors.green,
            ),
            title: Text(
              '${payment.amount}€ - ${payment.type == 'rent' ? 'Loyer' : payment.type == 'deposit' ? 'Dépôt' : 'Frais'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${payment.date.day}/${payment.date.month}/${payment.date.year}',
                ),
                if (payment.description != null)
                  Text('Note: ${payment.description}'),
              ],
            ),
            trailing: isPending
                ? TextButton(
                    child: const Text('Marquer reçu'),
                    onPressed: () async {
                      try {
                        await _paymentService.updatePaymentStatus(
                          payment.id,
                          'received',
                        );
                        await _loadPayments();
                      } catch (e) {
                        _showError('Erreur lors de la mise à jour du paiement: $e');
                      }
                    },
                  )
                : Text(
                    payment.status.toUpperCase(),
                    style: TextStyle(
                      color: isLate ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paiements - ${widget.tenant.fullName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Historique'),
            Tab(text: 'Statistiques'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentsTab(),
                _buildStatisticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPaymentDialog,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un paiement',
      ),
    );
  }
}