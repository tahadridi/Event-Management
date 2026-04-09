import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/seat_service.dart';
import '../../services/notification_service.dart';
import 'place_picker_page.dart';

class EditEventPage extends StatefulWidget {
  final EventModel event;

  const EditEventPage({Key? key, required this.event}) : super(key: key);

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;
  late TextEditingController _priceController;
  late TextEditingController _numberOfRowsController;
  late TextEditingController _seatsPerRowController;
  late TextEditingController _frontSeatPriceController;
  late TextEditingController _regularSeatPriceController;

  late String _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _isFree;
  late bool _hasSeats;
  bool _isLoading = false;
  late double? _latitude;
  late double? _longitude;

  File? _selectedImage;
  String? _imageUrl;
  bool _isUploadingImage = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final List<String> categories = [
    'Conférence',
    'Atelier',
    'Séminaire',
    'Concert',
    'Événement sportif',
    'Réunion',
    'Autre'
  ];

  final EventService _eventService = EventService();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();

  // Color palette
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF1A3A7C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color creamDark = Color(0xFFF5EDE2);
  static const Color accent = Color(0xFFE67E22);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _capacityController = TextEditingController(
      text: widget.event.totalPlaces.toString(),
    );
    _priceController = TextEditingController(
      text: widget.event.price.toStringAsFixed(2),
    );
    _numberOfRowsController = TextEditingController(
      text: widget.event.numberOfRows.toString(),
    );
    _seatsPerRowController = TextEditingController(
      text: widget.event.seatsPerRow.toString(),
    );
    _frontSeatPriceController = TextEditingController(
      text: widget.event.frontSeatPrice.toStringAsFixed(2),
    );
    _regularSeatPriceController = TextEditingController(
      text: widget.event.regularSeatPrice.toStringAsFixed(2),
    );

    _selectedCategory = widget.event.category;
    _selectedDate = widget.event.date;
    _selectedTime = TimeOfDay.fromDateTime(widget.event.date);
    _isFree = widget.event.price == 0;
    _hasSeats = widget.event.hasSeats;
    
    // Fix: If hasSeats is true, force isFree to false
    if (_hasSeats) {
      _isFree = false;
    }
    
    _latitude = widget.event.latitude;
    _longitude = widget.event.longitude;
    _imageUrl = widget.event.imageUrl;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _numberOfRowsController.dispose();
    _seatsPerRowController.dispose();
    _frontSeatPriceController.dispose();
    _regularSeatPriceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    }
  }

  // Cloudinary Configuration
  String get CLOUDINARY_CLOUD_NAME => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String get CLOUDINARY_UPLOAD_PRESET => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    
    setState(() {
      _isUploadingImage = true;
    });
    
    try {
      if (!await _selectedImage!.exists()) {
        throw Exception('Le fichier image n\'existe pas');
      }
      
      final fileSize = await _selectedImage!.length();
      print('Taille du fichier: ${fileSize / (1024 * 1024)} MB');
      
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('L\'image est trop volumineuse (max 10 MB)');
      }

      print('Tentative d\'upload vers Cloudinary...');
      print('Cloud Name: ${CLOUDINARY_CLOUD_NAME}');
      print('Upload Preset: ${CLOUDINARY_UPLOAD_PRESET}');

      // Create FormData for unsigned Cloudinary upload with preset
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_selectedImage!.path),
        'upload_preset': CLOUDINARY_UPLOAD_PRESET,
        'folder': 'event_project',
      });

      // Upload to Cloudinary (unsigned with preset)
      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload',
        data: formData,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final downloadUrl = response.data['secure_url'];
        print('Upload terminé avec succès');
        print('URL obtenue: $downloadUrl');
        
        setState(() {
          _imageUrl = downloadUrl;
          _isUploadingImage = false;
        });

        return downloadUrl;
      } else {
        print('Erreur Cloudinary: ${response.statusCode} - ${response.data}');
        throw Exception('Échec: ${response.statusCode}');
      }

    } catch (e) {
      print('Erreur d\'upload: $e');
      setState(() {
        _isUploadingImage = false;
      });
      _showErrorSnackBar('Erreur d\'upload: $e');
      return null;
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildModalOption(
              icon: Icons.photo_library_rounded,
              title: 'Choisir depuis la galerie',
              color: midnightBlue,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            _buildModalOption(
              icon: Icons.camera_alt_rounded,
              title: 'Prendre une photo',
              color: midnightBlue,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_selectedImage != null || _imageUrl != null)
              _buildModalOption(
                icon: Icons.delete_rounded,
                title: 'Supprimer l\'image',
                color: error,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildModalOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? error : textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2099),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF081F5C),
              onPrimary: Color(0xFFF8F3EA),
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF081F5C),
              onPrimary: Color(0xFFF8F3EA),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  bool _validateSeatsConfig() {
    if (!_hasSeats) return true;
    
    if (_numberOfRowsController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer le nombre de rangées');
      return false;
    }
    if (_seatsPerRowController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer le nombre de places par rangée');
      return false;
    }
    if (_frontSeatPriceController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer le prix des sièges avant');
      return false;
    }
    if (_regularSeatPriceController.text.isEmpty) {
      _showErrorSnackBar('Veuillez entrer le prix des sièges réguliers');
      return false;
    }

    final rows = int.tryParse(_numberOfRowsController.text) ?? 0;
    final seats = int.tryParse(_seatsPerRowController.text) ?? 0;
    
    if (rows <= 0 || rows > 26) {
      _showErrorSnackBar('Le nombre de rangées doit être entre 1 et 26');
      return false;
    }
    if (seats <= 0 || seats > 20) {
      _showErrorSnackBar('Le nombre de places par rangée doit être entre 1 et 20');
      return false;
    }
    if (double.tryParse(_frontSeatPriceController.text) == null) {
      _showErrorSnackBar('Prix siège avant invalide');
      return false;
    }
    if (double.tryParse(_regularSeatPriceController.text) == null) {
      _showErrorSnackBar('Prix siège régulier invalide');
      return false;
    }
    
    return true;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        _showErrorSnackBar('Veuillez sélectionner une date');
        return;
      }

      if (_selectedTime == null) {
        _showErrorSnackBar('Veuillez sélectionner une heure');
        return;
      }

      if (_latitude == null || _longitude == null) {
        _showErrorSnackBar('Veuillez sélectionner un lieu sur la carte');
        return;
      }

      if (!_validateSeatsConfig()) {
        return;
      }

      _updateEventWithImageUpload();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _updateEventWithImageUpload() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image if a new one was selected
      String? finalImageUrl = _imageUrl;
      if (_selectedImage != null) {
        finalImageUrl = await _uploadImage();
        if (finalImageUrl == null) {
          _showErrorSnackBar('Erreur lors du téléchargement de l\'image');
          return;
        }
      }

      // Create new event model with updated values
      final newDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final updatedEvent = EventModel(
        id: widget.event.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        location: _locationController.text,
        date: newDateTime,
        totalPlaces: int.parse(_capacityController.text),
        availablePlaces: widget.event.availablePlaces,
        price: (_hasSeats || _isFree) ? 0.0 : double.parse(_priceController.text),
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        imageUrl: finalImageUrl,
        organizerId: widget.event.organizerId,
        organizerName: widget.event.organizerName,
        hasSeats: _hasSeats,
        numberOfRows: _hasSeats ? int.parse(_numberOfRowsController.text) : 0,
        seatsPerRow: _hasSeats ? int.parse(_seatsPerRowController.text) : 0,
        frontSeatPrice: _hasSeats ? double.parse(_frontSeatPriceController.text) : 0.0,
        regularSeatPrice: _hasSeats ? double.parse(_regularSeatPriceController.text) : 0.0,
      );

      // Check if changes are major (date or location changed)
      final isMajor = _notificationService.isMajorChange(widget.event, updatedEvent);

      // Update event in database
      await _eventService.updateEvent(
        eventId: updatedEvent.id,
        title: updatedEvent.title,
        description: updatedEvent.description,
        category: updatedEvent.category,
        location: updatedEvent.location,
        date: updatedEvent.date,
        time: TimeOfDay.fromDateTime(updatedEvent.date),
        totalPlaces: updatedEvent.totalPlaces,
        price: updatedEvent.price,
        latitude: updatedEvent.latitude,
        longitude: updatedEvent.longitude,
        hasSeats: updatedEvent.hasSeats,
        numberOfRows: updatedEvent.numberOfRows,
        seatsPerRow: updatedEvent.seatsPerRow,
        frontSeatPrice: updatedEvent.frontSeatPrice,
        regularSeatPrice: updatedEvent.regularSeatPrice,
      );

      // Update image URL separately if a new image was uploaded
      if (_selectedImage != null && finalImageUrl != null) {
        await FirebaseFirestore.instance.collection('events').doc(updatedEvent.id).update({
          'imageUrl': finalImageUrl,
        });
      }

      // Note: notifyParticipantsOfChanges is now handled in EventService.updateEvent()
      // No need to call it here to avoid duplicates

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Événement mis à jour avec succès !'),
            backgroundColor: success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text(
          'Modifier l\'événement',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: midnightBlue,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: midnightBlue,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        toolbarHeight: 100,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cream,
                creamDark,
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(_fadeAnimation),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Picker Section
                  _buildImagePickerSection(),
                  const SizedBox(height: 24),

                  // Header Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modifier les détails',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF081F5C),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mettez à jour les informations de votre événement',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF081F5C).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title Field
                  _buildInputField(
                    controller: _titleController,
                    label: 'Nom de l\'événement',
                    icon: Icons.title,
                    hint: 'Titre de l\'événement',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le titre est requis';
                      }
                      if (value.length < 3) {
                        return 'Le titre doit comporter au moins 3 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Category Dropdown
                  _buildDropdownField(
                    value: _selectedCategory,
                    label: 'Catégorie',
                    icon: Icons.category,
                    items: categories,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Description Field
                  _buildInputField(
                    controller: _descriptionController,
                    label: 'Description',
                    icon: Icons.description,
                    hint: 'Description détaillée',
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La description est requise';
                      }
                      if (value.length < 10) {
                        return 'La description doit comporter au moins 10 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Location Field with Place Picker - FIXED (removed readOnly)
                  _buildLocationField(),
                  const SizedBox(height: 20),

                  // Date and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePickerField(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePickerField(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Capacity Field
                  _buildInputField(
                    controller: _capacityController,
                    label: 'Capacité',
                    icon: Icons.people,
                    hint: 'Nombre de places',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La capacité est requise';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Entrez un nombre valide supérieur à 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Price Section - Modified to work with seats
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF081F5C).withOpacity(0.1),
                                      const Color(0xFF1A3A7C).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _isFree ? Icons.celebration : Icons.attach_money,
                                  color: const Color(0xFF081F5C),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Événement gratuit',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _hasSeats ? Colors.grey : const Color(0xFF081F5C),
                                  ),
                                ),
                              ),
                              Switch(
                                value: _isFree,
                                onChanged: _hasSeats ? null : (value) {
                                  setState(() {
                                    _isFree = value;
                                    if (_isFree) {
                                      _priceController.text = '0';
                                    }
                                  });
                                },
                                activeColor: const Color(0xFF081F5C),
                              ),
                            ],
                          ),
                        ),
                        if (!_isFree && !_hasSeats)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildInputField(
                              controller: _priceController,
                              label: 'Prix',
                              icon: Icons.attach_money,
                              hint: 'Prix en TND',
                              prefixText: 'TND ',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (!_isFree && !_hasSeats && (value == null || value.isEmpty)) {
                                  return 'Le prix est requis';
                                }
                                if (value != null &&
                                    value.isNotEmpty &&
                                    double.tryParse(value) == null) {
                                  return 'Entrez un prix valide';
                                }
                                return null;
                              },
                            ),
                          ),
                        if (_hasSeats)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: midnightBlue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: midnightBlue, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Le prix est défini par la configuration des sièges ci-dessous',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: midnightBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Seating Configuration Section - Modified to disable when free event is selected
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF081F5C).withOpacity(_isFree ? 0.05 : 0.1),
                                      const Color(0xFF1A3A7C).withOpacity(_isFree ? 0.05 : 0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _hasSeats ? Icons.event_seat : Icons.chair_alt,
                                  color: _isFree ? Colors.grey : const Color(0xFF081F5C),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Sélection de places',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _isFree ? Colors.grey : const Color(0xFF081F5C),
                                  ),
                                ),
                              ),
                              Switch(
                                value: _hasSeats,
                                onChanged: _isFree ? null : (value) {
                                  setState(() {
                                    _hasSeats = value;
                                    // If enabling seats, disable free event
                                    if (_hasSeats) {
                                      _isFree = false;
                                    }
                                  });
                                },
                                activeColor: const Color(0xFF081F5C),
                              ),
                            ],
                          ),
                        ),
                        if (_hasSeats) ...[
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    controller: _numberOfRowsController,
                                    label: 'Rangées',
                                    icon: Icons.layers_rounded,
                                    hint: 'Ex: 8',
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Requis';
                                      }
                                      final n = int.tryParse(value);
                                      if (n == null || n <= 0 || n > 26) {
                                        return '1-26';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    controller: _seatsPerRowController,
                                    label: 'Places/rangée',
                                    icon: Icons.event_seat_rounded,
                                    hint: 'Ex: 12',
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Requis';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Nombre';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: _buildInputField(
                              controller: _frontSeatPriceController,
                              label: 'Prix - Sièges avant',
                              icon: Icons.wallet_rounded,
                              hint: 'Sièges premium',
                              prefixText: 'TND ',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Prix valide';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildInputField(
                              controller: _regularSeatPriceController,
                              label: 'Prix - Autres sièges',
                              icon: Icons.wallet_rounded
,
                              hint: 'Sièges réguliers',
                              prefixText: 'TND ',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requis';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Prix valide';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: midnightBlue.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: midnightBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: midnightBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(cream),
                                  ),
                                )
                              : const Text(
                                  'Enregistrer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: cream,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: const Color(0xFF081F5C).withOpacity(0.7)),
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF081F5C), size: 20),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            color: const Color(0xFF081F5C).withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF081F5C), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: const Color(0xFF081F5C).withOpacity(0.7)),
          prefixIcon: Icon(icon, color: const Color(0xFF081F5C), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF081F5C), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF081F5C)),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // FIXED: Removed readOnly and made it interactive
  Widget _buildLocationField() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlacePickerPage(
              initialLat: _latitude,
              initialLng: _longitude,
              initialLocationName: _locationController.text,
            ),
          ),
        );

        if (result != null && mounted) {
          setState(() {
            _latitude = result['latitude'];
            _longitude = result['longitude'];
            _locationController.text = result['location_name'];
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: _locationController,
          enabled: false, // Make it disabled for typing but still tappable via GestureDetector
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le lieu est requis';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Lieu',
            labelStyle: TextStyle(color: const Color(0xFF081F5C).withOpacity(0.7)),
            hintText: 'Cliquez pour choisir un lieu',
            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF081F5C), size: 20),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF081F5C),
                    const Color(0xFF1A3A7C),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Color(0xFFF8F3EA),
                size: 18,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF081F5C), width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date',
            labelStyle: TextStyle(color: const Color(0xFF081F5C).withOpacity(0.7)),
            prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF081F5C), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          child: Text(
            DateFormat('dd MMM yyyy').format(_selectedDate),
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF081F5C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerField() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Heure',
            labelStyle: TextStyle(color: const Color(0xFF081F5C).withOpacity(0.7)),
            prefixIcon: const Icon(Icons.access_time, color: Color(0xFF081F5C), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          child: Text(
            _selectedTime.format(context),
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF081F5C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return GestureDetector(
      onTap: _showImagePickerDialog,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _selectedImage != null || _imageUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          )
                        : _imageUrl != null
                            ? Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: midnightBlue.withOpacity(0.1),
                                    child: const Icon(Icons.image_not_supported),
                                  );
                                },
                              )
                            : Container(
                                color: midnightBlue.withOpacity(0.1),
                              ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: midnightBlue,
                        size: 20,
                      ),
                    ),
                  ),
                  if (_isUploadingImage)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: midnightBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 48,
                      color: midnightBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ajouter une photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: midnightBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(optionnel)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Appuyez pour changer',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}