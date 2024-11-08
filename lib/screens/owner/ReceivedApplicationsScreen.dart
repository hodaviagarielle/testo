import 'package:flutter/material.dart';
import 'package:localink/models/rental_application.dart';
import 'package:localink/services/application_service.dart';
import 'package:localink/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ReceivedApplicationsScreen extends StatefulWidget {
  @override
  _ReceivedApplicationsScreenState createState() => _ReceivedApplicationsScreenState();
}

class _ReceivedApplicationsScreenState extends State<ReceivedApplicationsScreen> {
  final ApplicationService _applicationService = ApplicationService();
  final AuthService _authService = AuthService();

  late Stream<List<RentalApplication>> _applicationStream;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _applicationStream = _applicationService.getApplicationsForProperty(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demandes de location'),
      ),
      body: StreamBuilder<List<RentalApplication>>(
        stream: _applicationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur lors du chargement des demandes: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final applications = snapshot.data!;

          if (applications.isEmpty) {
            return Center(
              child: Text('Aucune demande de location reçue'),
            );
          }

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              return ListTile(
                title: Text(application.tenantFullName),
                subtitle: Text(application.occupation),
                trailing: Text(application.status.toUpperCase()),
                onTap: () {
                  // Navigate to the application details screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApplicationDetailsScreen(application: application),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ApplicationDetailsScreen extends StatefulWidget {
  final RentalApplication application;

  ApplicationDetailsScreen({required this.application});

  @override
  _ApplicationDetailsScreenState createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la demande'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nom: ${widget.application.tenantFullName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Email: ${widget.application.tenantEmail}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Téléphone: ${widget.application.tenantPhone}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Profession: ${widget.application.occupation}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Employeur: ${widget.application.employer}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Durée d\'emploi: ${widget.application.employmentDuration}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Revenu mensuel: ${widget.application.monthlyIncome.toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Message:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.application.message,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Documents:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (widget.application.documents.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: widget.application.documents.length,
                  itemBuilder: (context, index) {
                    final documentUrl = widget.application.documents[index];
                    return ListTile(
                      leading: Icon(Icons.insert_drive_file),
                      title: Text('Document ${index + 1}'),
                      onTap: () {
                        // Ouvrir le document dans une autre application
                        launchUrl(Uri.parse(documentUrl));
                      },
                    );
                  },
                ),
              )
            else
              Text('Aucun document soumis'),
          ],
        ),
      ),
    );
  }
}