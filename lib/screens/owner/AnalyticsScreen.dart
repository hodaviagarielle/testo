import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:collection/collection.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String _selectedPeriod = '6M'; // 1M, 3M, 6M, 1Y
  String _selectedProperty = 'Toutes'; // Toutes ou ID spécifique
  List<String> _properties = ['Toutes'];
  
  // Données pour les graphiques
  List<Map<String, dynamic>> _revenueData = [];
  List<Map<String, dynamic>> _occupancyData = [];
  Map<String, double> _expenseDistribution = {};
  List<Map<String, dynamic>> _maintenanceRequests = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }


  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
     try {
      // Simulation de chargement des données
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        // Données simulées pour les revenus
        _revenueData = List.generate(6, (index) {
          final date = DateTime.now().subtract(Duration(days: (5 - index) * 30));
          return {
            'date': date,
            'revenue': 5000.0 + (index * 200) + (Random().nextDouble() * 500),
            'expenses': 1500.0 + (Random().nextDouble() * 300),
          };
        });

       // Données simulées pour l'occupation
        _occupancyData = List.generate(6, (index) {
          final date = DateTime.now().subtract(Duration(days: (5 - index) * 30));
          return {
            'date': date,
            'rate': 85.0 + (Random().nextDouble() * 10),
          };
        });

        // Données simulées pour la distribution des dépenses
        _expenseDistribution = {
          'Maintenance': 35.0,
          'Assurances': 20.0,
          'Taxes': 30.0,
          'Utilities': 15.0,
        };

         // Données simulées pour les demandes de maintenance
        _maintenanceRequests = List.generate(6, (index) {
          final date = DateTime.now().subtract(Duration(days: (5 - index) * 30));
          return {
            'date': date,
            'count': 3 + Random().nextInt(5),
          };
        });

        // Liste simulée des propriétés
        _properties = [
          'Toutes',
          'Résidence Les Oliviers',
          'Villa Méditerranée',
          'Le Petit Marseillais'
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPeriodSelector() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<String>(
              value: _selectedProperty,
              items: _properties.map((String property) {
                return DropdownMenuItem<String>(
                  value: property,
                  child: Text(property),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedProperty = newValue);
                  _loadAnalyticsData();
                }
              },
            ),
            Row(
              children: [
                _buildPeriodButton('1M'),
                _buildPeriodButton('3M'),
                _buildPeriodButton('6M'),
                _buildPeriodButton('1Y'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(period),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            setState(() => _selectedPeriod = period);
            _loadAnalyticsData();
          }
        },
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Revenus et Dépenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('MMM'),
                intervalType: DateTimeIntervalType.months,
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.currency(locale: 'fr_FR', symbol: '€'),
              ),
              legend: Legend(isVisible: true),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<Map<String, dynamic>, DateTime>>[
                LineSeries<Map<String, dynamic>, DateTime>(
                  name: 'Revenus',
                  dataSource: _revenueData,
                  xValueMapper: (Map<String, dynamic> data, _) => data['date'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['revenue'],
                  color: Colors.green,
                ),
                LineSeries<Map<String, dynamic>, DateTime>(
                  name: 'Dépenses',
                  dataSource: _revenueData,
                  xValueMapper: (Map<String, dynamic> data, _) => data['date'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['expenses'],
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
 
 
  Widget _buildOccupancyChart() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Taux d\'occupation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('MMM'),
                intervalType: DateTimeIntervalType.months,
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: 100,
                numberFormat: NumberFormat.percentPattern(),
              ),
              series: <CartesianSeries<Map<String, dynamic>, DateTime>>[
                LineSeries<Map<String, dynamic>, DateTime>(
                  dataSource: _occupancyData,
                  xValueMapper: (Map<String, dynamic> data, _) => data['date'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['rate'],
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpenseDistributionChart() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Distribution des dépenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 250,
            child: SfCircularChart(
              legend: Legend(isVisible: true),
              series: <CircularSeries>[
                DoughnutSeries<MapEntry<String, double>, String>(
                  dataSource: _expenseDistribution.entries.toList(),
                  xValueMapper: (MapEntry<String, double> data, _) => data.key,
                  yValueMapper: (MapEntry<String, double> data, _) => data.value,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildMaintenanceRequestsChart() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Demandes de maintenance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('MMM'),
                intervalType: DateTimeIntervalType.months,
              ),
              series: <CartesianSeries<Map<String, dynamic>, DateTime>>[
                ColumnSeries<Map<String, dynamic>, DateTime>(
                  dataSource: _maintenanceRequests,
                  xValueMapper: (Map<String, dynamic> data, _) => data['date'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['count'],
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSummaryCards() {
    final currentPeriodRevenue = _revenueData.lastOrNull?['revenue'] ?? 0.0;
    final previousPeriodRevenue = _revenueData[_revenueData.length - 2]['revenue'];
    final revenueChange = ((currentPeriodRevenue - previousPeriodRevenue) / previousPeriodRevenue) * 100;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Revenus du mois',
              '${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(currentPeriodRevenue)}',
              revenueChange,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Taux d\'occupation',
              '${_occupancyData.lastOrNull?['rate'].toStringAsFixed(1)}%',
              2.5,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, double change, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: change >= 0 ? Colors.green : Colors.red,
                ),
                Text(
                  '${change.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: change >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalyticsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildPeriodSelector(),
                    _buildSummaryCards(),
                    _buildRevenueChart(),
                    _buildOccupancyChart(),
                    _buildExpenseDistributionChart(),
                    _buildMaintenanceRequestsChart(),
                  ],
                ),
              ),
            ),
    );
  }
}