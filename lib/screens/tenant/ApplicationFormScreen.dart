import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:localink/models/property.dart';
import 'package:localink/services/application_service.dart';
import 'package:localink/services/auth_service.dart';
import 'package:localink/models/user.dart';  // Add this import at the top

class ApplicationFormPage extends StatefulWidget {
  final Property property;

  ApplicationFormPage({required this.property});

  @override
  _ApplicationFormPageState createState() => _ApplicationFormPageState();
}

class _ApplicationFormPageState extends State<ApplicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ApplicationService _applicationService = ApplicationService();
  final AuthService _authService = AuthService();

  final _monthlyIncomeController = TextEditingController();
  final _occupationController = TextEditingController();
  final _employerController = TextEditingController();
  final _employmentDurationController = TextEditingController();
  final _messageController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;
  UserProfile? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await _authService.getCurrentUserProfile();
    if (user != null) {
      setState(() {
        _currentUser = user;
        // Pré-remplir le nom si displayName existe
        if (user.displayName != null) {
          final nameParts = user.displayName!.split(' ');
          if (nameParts.length > 1) {
            _firstNameController.text = nameParts.first;
            _lastNameController.text = nameParts.sublist(1).join(' ');
          } else {
            _firstNameController.text = user.displayName!;
          }
        }
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez vous connecter pour soumettre une demande'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _applicationService.submitApplication(
        propertyId: widget.property.id,
        ownerId: widget.property.ownerId,
        tenantId: _currentUser!.id,
        monthlyIncome: double.parse(_monthlyIncomeController.text),
        occupation: _occupationController.text,
        employer: _employerController.text,
        employmentDuration: _employmentDurationController.text,
        message: _messageController.text,
        documents: _selectedFiles,
        tenantFirstName: _firstNameController.text,
        tenantLastName: _lastNameController.text,
        tenantEmail: _currentUser!.email,
        tenantPhone: _phoneController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande envoyée avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demande de location'),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Propriété: ${widget.property.title}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              
              // Informations personnelles
              Text(
                'Informations personnelles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'Prénom',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Veuillez entrer votre prénom'
                          : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Veuillez entrer votre nom'
                          : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                  prefixText: '+33 ',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Veuillez entrer votre numéro de téléphone'
                    : null,
              ),
              
              SizedBox(height: 24),
              // Informations professionnelles
              Text(
                'Informations professionnelles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _monthlyIncomeController,
                decoration: InputDecoration(
                  labelText: 'Revenu mensuel (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Veuillez entrer votre revenu mensuel'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _occupationController,
                decoration: InputDecoration(
                  labelText: 'Profession',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Veuillez entrer votre profession'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _employerController,
                decoration: InputDecoration(
                  labelText: 'Employeur',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Veuillez entrer le nom de votre employeur'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _employmentDurationController,
                decoration: InputDecoration(
                  labelText: 'Durée d\'emploi',
                  border: OutlineInputBorder(),
                  hintText: 'ex: 2 ans',
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Veuillez entrer votre durée d\'emploi'
                    : null,
              ),
              
              SizedBox(height: 24),
              // Message et documents
              Text(
                'Message et documents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Message au propriétaire',
                  border: OutlineInputBorder(),
                  hintText: 'Présentez-vous et expliquez pourquoi ce logement vous intéresse',
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Veuillez entrer un message'
                    : null,
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickFiles,
                icon: Icon(Icons.attach_file),
                label: Text('Ajouter des documents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
              ),
              if (_selectedFiles.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Documents sélectionnés:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._selectedFiles.map((file) => ListTile(
                  leading: Icon(Icons.insert_drive_file),
                  title: Text(file.name),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _selectedFiles.remove(file);
                      });
                    },
                  ),
                )).toList(),
              ],
              
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Envoyer la demande',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
      });
    }
  }

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    _occupationController.dispose();
    _employerController.dispose();
    _employmentDurationController.dispose();
    _messageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}