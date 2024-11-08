import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:localink/models/property.dart';
import 'package:localink/services/StorageService.dart';
import 'package:localink/services/property_service.dart';

class EditPropertyScreen extends StatefulWidget {
  final String propertyId;

  const EditPropertyScreen({
    Key? key, 
    required this.propertyId
  }) : super(key: key);

  @override
  _EditPropertyScreenState createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final PropertyService _propertyService = PropertyService();
final storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  Property? _property;

  // Form fields
  String _title = '';
  String _address = '';
  String _location = '';
  int _bedrooms = 1;
  int _bathrooms = 1;
  double _price = 0.0;
  double _surface = 0.0;
  String _description = '';
  bool _isAvailable = true;
  
  List<File> _newImages = [];
  List<Map<String, dynamic>> _existingImages = [];
  
  Map<String, bool> _amenities = {
    'wifi': false,
    'parking': false,
    'elevator': false,
    'furnished': false,
    'balcony': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPropertyDetails();
  }

  Future<void> _loadPropertyDetails() async {
    try {
      final property = await _propertyService.getProperty(widget.propertyId);
      final images = await storageService.getPropertyImages(widget.propertyId);
      
      setState(() {
        _property = property;
        _title = property.title;
        _address = property.address;
        _location = property.location;
        _bedrooms = property.bedrooms;
        _bathrooms = property.bathrooms;
        _price = property.price;
        _surface = property.surface;
        _description = property.description;
        _isAvailable = property.isAvailable;
        _existingImages = images;
        
        // Initialiser les équipements
        _amenities.forEach((key, value) {
          _amenities[key] = property.amenities.containsKey(key);
        });

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedImages = await _imagePicker.pickMultiImage();
    if (pickedImages.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedImages.map((xFile) => File(xFile.path)));
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  setState(() => _isLoading = true);

  try {
    // Créer une map de mises à jour
    final updates = {
      'title': _title,
      'address': _address,
      'location': _location,
      'bedrooms': _bedrooms,
      'bathrooms': _bathrooms,
      'price': _price,
      'surface': _surface,
      'description': _description,
      'isAvailable': _isAvailable,
      'amenities': Map.fromEntries(
        _amenities.entries.where((entry) => entry.value)
      ),
      'updatedAt': Timestamp.now(), // Optional: track when the property was last updated
    };

    // Mettre à jour les détails de la propriété
    await _propertyService.updateProperty(widget.propertyId, updates);

    // Upload des nouvelles images
    for (var imageFile in _newImages) {
      await storageService.uploadPropertyImage(widget.propertyId, imageFile);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propriété mise à jour avec succès')),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
      setState(() => _isLoading = false);
    }
  }
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Photos'),
        Container(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Bouton d'ajout
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: _pickImages,
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 36,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajouter',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Images existantes
              ..._existingImages.map((image) => _buildImageTile(
                isExisting: true,
                image: base64Decode(image['imageData']),
                onDelete: () => _removeExistingImage(_existingImages.indexOf(image)),
              )),
              
              // Nouvelles images
              ..._newImages.map((file) => _buildImageTile(
                isExisting: false,
                file: file,
                onDelete: () => _removeNewImage(_newImages.indexOf(file)),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile({
    required bool isExisting,
    Uint8List? image,
    File? file,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isExisting
              ? Image.memory(
                  image!,
                  width: 120,
                  height: 140,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  file!,
                  width: 120,
                  height: 140,
                  fit: BoxFit.cover,
                ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDelete,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
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
        onSaved: onSaved,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Équipements'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _amenities.entries.map((entry) {
            return FilterChip(
              label: Text(
                entry.key,
                style: TextStyle(
                  color: entry.value 
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              selected: entry.value,
              onSelected: (bool selected) {
                setState(() {
                  _amenities[entry.key] = selected;
                });
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: entry.value 
                    ? Theme.of(context).primaryColor 
                    : Theme.of(context).dividerColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
        title: const Text('Modifier la propriété'),
        elevation: 0,
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
                _buildImageSection(),
                
                _buildSectionTitle('Informations générales'),
                _buildTextField(
                  label: 'Titre',
                  initialValue: _title,
                  onSaved: (value) => _title = value!,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un titre';
                    }
                    return null;
                  },
                ),

                _buildTextField(
                  label: 'Adresse',
                  initialValue: _address,
                  onSaved: (value) => _address = value!,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une adresse';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Localisation',
                  initialValue: _location,
                  onSaved: (value) => _location = value!,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une localisation';
                    }
                    return null;
                  },
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Chambres',
                        initialValue: _bedrooms.toString(),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _bedrooms = int.parse(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTextField(
                        label: 'Salles de bain',
                        initialValue: _bathrooms.toString(),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _bathrooms = int.parse(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Prix mensuel (€)',
                        initialValue: _price.toString(),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _price = double.parse(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTextField(
                        label: 'Surface (m²)',
                        initialValue: _surface.toString(),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _surface = double.parse(value!),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                _buildTextField(
                  label: 'Description',
                  initialValue: _description,
                  maxLines: 4,
                  hintText: 'Décrivez votre propriété...',
                  onSaved: (value) => _description = value ?? '',
                ),

                _buildAmenitiesSection(),
                
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text('Disponible'),
                    value: _isAvailable,
                    onChanged: (bool value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                    secondary: Icon(
                      Icons.check_circle,
                      color: _isAvailable ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
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
                          'Mettre à jour la propriété',
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
}