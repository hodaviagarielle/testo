import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:localink/models/property.dart';
import 'package:localink/services/StorageService.dart';
import 'package:localink/services/property_service.dart';
import 'package:localink/services/auth_service.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({Key? key}) : super(key: key);

  @override
  _AddPropertyScreenState createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final PropertyService _propertyService = PropertyService();
  final AuthService _authService = AuthService();
final storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  double _surface = 0.0;
  String _description = '';
  String _location = '';
  bool _isLoading = false;
  String _title = '';
  String _address = '';
  int _bedrooms = 1;
  int _bathrooms = 1;
  double _price = 0.0;
  bool _isAvailable = true;
  List<File> _selectedImages = [];
  Map<String, bool> _amenities = {
    'wifi': false,
    'parking': false,
    'elevator': false,
    'furnished': false,
    'balcony': false,
  };

  Future<void> _pickImages() async {
    final List<XFile> pickedImages = await _imagePicker.pickMultiImage();
    if (pickedImages.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedImages.map((xFile) => File(xFile.path)));
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) throw Exception('Utilisateur non connecté');

      final property = Property(
        id: '',
        ownerId: userProfile.id,
        title: _title,
        address: _address,
        location: _location, // Ajout de la localisation
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        price: _price,
        images: [],
        isAvailable: _isAvailable,
        amenities: Map.fromEntries(
          _amenities.entries.where((entry) => entry.value)
        ),
        createdAt: DateTime.now(),
        surface: _surface,   
        description: _description,
      );

      final propertyId = await _propertyService.createProperty(property);

      for (var imageFile in _selectedImages) {
        await storageService.uploadPropertyImage(propertyId, imageFile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Propriété ajoutée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePicker() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, 
                     color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Photos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  InkWell(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).primaryColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajouter',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ..._selectedImages.map((file) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            file,
                            width: 100,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedImages.remove(file);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String? Function(String?) validator,
    required Function(String?) onSaved,
    TextInputType? keyboardType,
    int? maxLines,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
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
          fillColor: Colors.grey.shade50,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une propriété'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Informations sur votre propriété',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImagePicker(),
                          
                          _buildSectionTitle('Informations principales', Icons.home),
                          
                          _buildTextField(
                            label: 'Titre',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un titre';
                              }
                              return null;
                            },
                            onSaved: (value) => _title = value!,
                          ),
                          
                          _buildTextField(
                            label: 'Localisation',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer une localisation';
                              }
                              return null;
                            },
                            onSaved: (value) => _location = value!,
                            hintText: 'Ex: Paris, Lyon, Marseille...',
                          ),

                          _buildTextField(
                            label: 'Adresse',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer une adresse';
                              }
                              return null;
                            },
                            onSaved: (value) => _address = value!,
                          ),

                          _buildTextField(
                            label: 'Prix mensuel (€)',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un prix';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Veuillez entrer un nombre valide';
                              }
                              return null;
                            },
                            onSaved: (value) => _price = double.parse(value!),
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Chambres',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requis';
                                    }
                                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                      return 'Min. 1';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => _bedrooms = int.parse(value!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: 'Salles de bain',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requis';
                                    }
                                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                      return 'Min. 1';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => _bathrooms = int.parse(value!),
                                ),
                              ),
                            ],
                          ),

                          _buildTextField(
                            label: 'Surface (m²)',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Surface requise';
                              }
                              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                return 'Surface invalide';
                              }
                              return null;
                            },
                            onSaved: (value) => _surface = double.parse(value!),
                          ),

                          _buildTextField(
                            label: 'Description',
                            maxLines: 4,
                            hintText: 'Décrivez votre propriété...',
                            validator: (value) => null,
                            onSaved: (value) => _description = value ?? '',
                          ),

                          _buildSectionTitle('Équipements', Icons.checklist),
                          
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _amenities.entries.map((entry) {
                                  return FilterChip(
                                    label: Text(entry.key),
                                    selected: entry.value,
                                    onSelected: (bool selected) {
                                      setState(() {
                                        _amenities[entry.key] = selected;
                                      });
                                    },
                                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                    checkmarkColor: Theme.of(context).primaryColor,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          
                          Card(
                            elevation: 2,
                            child: SwitchListTile(
                              title: const Text('Disponible'),
                              subtitle: Text(
                                'La propriété est-elle disponible immédiatement ?',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              value: _isAvailable,
                              onChanged: (bool value) {
                                setState(() {
                                  _isAvailable = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 32),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_home),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ajouter la propriété',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}