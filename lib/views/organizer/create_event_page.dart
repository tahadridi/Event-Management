import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/event_service.dart';
import '../../services/seat_service.dart';
import 'place_picker_page.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({Key? key}) : super(key: key);

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsPerRowController = TextEditingController();
  final _numberOfRowsController = TextEditingController();
  final _frontSeatPriceController = TextEditingController();
  final _regularSeatPriceController = TextEditingController();

  String _selectedCategory = 'Conférence';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isFree = false;
  bool _hasSeats = false;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  
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
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _seatsPerRowController.dispose();
    _numberOfRowsController.dispose();
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
          _imageUrl = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    }
  }

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
    
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final String storagePath = 'event_images/$fileName.jpg';
    final Reference ref = _storage.ref().child(storagePath);
    
    print('Tentative d\'upload vers: $storagePath');
    
    final UploadTask uploadTask = ref.putFile(_selectedImage!);
    
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      print('Progression: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
    });
    
    final TaskSnapshot snapshot = await uploadTask;
    
    if (snapshot.state != TaskState.success) {
      throw Exception('Échec du téléchargement: ${snapshot.state}');
    }
    
    print('Upload terminé avec succès, récupération de l\'URL...');
    
    final String downloadUrl = await ref.getDownloadURL();
    print('URL obtenue: $downloadUrl');
    
    setState(() {
      _imageUrl = downloadUrl;
      _isUploadingImage = false;
    });
    
    return downloadUrl;
    
  } on FirebaseException catch (e) {
    print('FirebaseException - Code: ${e.code}, Message: ${e.message}');
    
    String errorMessage;
    switch (e.code) {
      case 'storage/object-not-found':
        errorMessage = 'Le bucket Firebase Storage n\'est pas configuré correctement. Vérifiez votre console Firebase.';
        break;
      case 'storage/unauthorized':
        errorMessage = 'Non autorisé à télécharger. Vérifiez les règles de sécurité.';
        break;
      case 'storage/canceled':
        errorMessage = 'Téléchargement annulé.';
        break;
      case 'storage/unknown':
        errorMessage = 'Erreur inconnue. Vérifiez votre connexion internet.';
        break;
      default:
        errorMessage = 'Erreur Firebase: ${e.message}';
    }
    
    setState(() {
      _isUploadingImage = false;
    });
    _showErrorSnackBar(errorMessage);
    return null;
    
  } catch (e) {
    print('Erreur générale: $e');
    setState(() {
      _isUploadingImage = false;
    });
    _showErrorSnackBar('Erreur: $e');
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
            if (_selectedImage != null)
              _buildModalOption(
                icon: Icons.delete_rounded,
                title: 'Supprimer l\'image',
                color: error,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _imageUrl = null;
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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2099),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: midnightBlue,
              onPrimary: Colors.white,
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
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: midnightBlue,
              onPrimary: Colors.white,
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

  void _submitForm() async {
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

      String? finalImageUrl = _imageUrl;
      if (_selectedImage != null && _imageUrl == null) {
        finalImageUrl = await _uploadImage();
        if (finalImageUrl == null) {
          _showErrorSnackBar('Erreur lors du téléchargement de l\'image');
          return;
        }
      }

      _createEvent(finalImageUrl);
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _createEvent(String? imageUrl) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventId = await _eventService.createEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        location: _locationController.text,
        date: _selectedDate!,
        time: _selectedTime!,
        totalPlaces: int.parse(_capacityController.text),
        price: _isFree ? 0.0 : double.parse(_priceController.text),
        latitude: _latitude,
        longitude: _longitude,
        imageUrl: imageUrl,
        hasSeats: _hasSeats,
        numberOfRows: _hasSeats ? int.parse(_numberOfRowsController.text) : 0,
        seatsPerRow: _hasSeats ? int.parse(_seatsPerRowController.text) : 0,
        frontSeatPrice: _hasSeats ? double.parse(_frontSeatPriceController.text) : 0.0,
        regularSeatPrice: _hasSeats ? double.parse(_regularSeatPriceController.text) : 0.0,
      );

      if (_hasSeats) {
        final seatService = SeatService();
        await seatService.createSeatsForEvent(
          eventId: eventId,
          numberOfRows: int.parse(_numberOfRowsController.text),
          seatsPerRow: int.parse(_seatsPerRowController.text),
          frontSeatPrice: double.parse(_frontSeatPriceController.text),
          regularSeatPrice: double.parse(_regularSeatPriceController.text),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Événement créé avec succès !'),
            backgroundColor: success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
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

  // Helper widget pour afficher l'astérisque obligatoire
  Widget _buildRequiredAsterisk() {
    return Text(
      ' *',
      style: TextStyle(
        color: error,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;
    final expandedHeight = isSmallScreen ? 120.0 : 140.0;
    final headerPadding = isSmallScreen ? 12.0 : 24.0;
    final headerPaddingTop = isSmallScreen ? 40.0 : 60.0;
    final titleFontSize = isSmallScreen ? 22.0 : 28.0;
    final subtitleFontSize = isSmallScreen ? 11.0 : 13.0;
    final iconSize = isSmallScreen ? 40.0 : 50.0;
    final contentPadding = isSmallScreen ? 16.0 : 24.0;
    final contentPaddingBottom = isSmallScreen ? 20.0 : 32.0;
    final spacingBetweenSections = isSmallScreen ? 16.0 : 20.0;
    final spacingBetweenFields = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            pinned: true,
            backgroundColor: cream,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cream,
                      creamDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(headerPadding, headerPaddingTop, headerPadding, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: iconSize,
                              height: iconSize,
                              decoration: BoxDecoration(
                                color: midnightBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: isSmallScreen ? 22 : 28,
                                color: midnightBlue,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Créer un événement',
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: midnightBlue,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(_fadeAnimation),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(contentPadding, 8, contentPadding, contentPaddingBottom),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImagePickerSection(isSmallScreen: isSmallScreen),
                        SizedBox(height: spacingBetweenSections),

                        _buildSectionCard(
                          title: 'Informations de base',
                          icon: Icons.info_outline_rounded,
                          isSmallScreen: isSmallScreen,
                          children: [
                            _buildModernInputField(
                              controller: _titleController,
                              label: 'Nom de l\'événement',
                              hint: 'Donnez un nom',
                              icon: Icons.title_rounded,
                              isRequired: true,
                              isSmallScreen: isSmallScreen,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Le nom de l\'événement est requis';
                                }
                                if (value.length < 3) {
                                  return 'Le nom doit comporter au moins 3 caractères';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: spacingBetweenFields),
                            _buildModernDropdownField(
                              value: _selectedCategory,
                              label: 'Catégorie',
                              icon: Icons.category_rounded,
                              isRequired: true,
                              items: categories,
                              isSmallScreen: isSmallScreen,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                            SizedBox(height: spacingBetweenFields),
                            _buildModernInputField(
                              controller: _descriptionController,
                              label: 'Description',
                              hint: 'Décrivez l\'événement',
                              icon: Icons.description_rounded,
                              isRequired: true,
                              maxLines: 4,
                              isSmallScreen: isSmallScreen,
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
                          ],
                        ),

                        SizedBox(height: spacingBetweenSections),

                        _buildSectionCard(
                          title: 'Lieu',
                          icon: Icons.location_on_rounded,
                          isRequired: true,
                          isSmallScreen: isSmallScreen,
                          children: [
                            _buildLocationField(),
                            if (_latitude != null && _longitude != null)
                              Padding(
                                padding: EdgeInsets.only(top: isSmallScreen ? 8 : 12),
                                child: Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                                  decoration: BoxDecoration(
                                    color: success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: isSmallScreen ? 14 : 16,
                                        color: success,
                                      ),
                                      SizedBox(width: isSmallScreen ? 6 : 8),
                                      Expanded(
                                        child: Text(
                                          'Lieu sélectionné avec succès',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: success,
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

                        const SizedBox(height: 20),

                        _buildSectionCard(
                          title: 'Date et heure',
                          icon: Icons.calendar_today_rounded,
                          isRequired: true,
                          isSmallScreen: isSmallScreen,
                          children: [
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
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildSectionCard(
                          title: 'Capacité et tarification',
                          icon: Icons.people_rounded,
                          isSmallScreen: isSmallScreen,
                          children: [
                            _buildModernInputField(
                              controller: _capacityController,
                              label: 'Capacité',
                              hint: 'Nombre de places disponibles',
                              icon: Icons.people_rounded,
                              isRequired: true,
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
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cream,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: midnightBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _isFree ? Icons.celebration_rounded : Icons.attach_money_rounded,
                                      color: midnightBlue,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Événement gratuit',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: midnightBlue,
                                          ),
                                        ),
                                        Text(
                                          'Cochez pour un événement gratuit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isFree,
                                    onChanged: (value) {
                                      setState(() {
                                        _isFree = value;
                                        if (_isFree || _hasSeats) {
                                          _priceController.clear();
                                        }
                                      });
                                    },
                                    activeColor: midnightBlue,
                                    inactiveThumbColor: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                            if (!_isFree && !_hasSeats)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: _buildModernInputField(
                                  controller: _priceController,
                                  label: 'Prix',
                                  hint: 'Prix par personne',
                                  icon: Icons.attach_money_rounded,
                                  isRequired: true,
                                  prefixText: 'TND ',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (!_isFree && !_hasSeats &&
                                        (value == null || value.isEmpty)) {
                                      return 'Le prix est requis pour les événements payants';
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
                            if (!_isFree && _hasSeats)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: accent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_rounded,
                                        color: accent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Les prix seront définis par type de place',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textPrimary,
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

                        const SizedBox(height: 32),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: midnightBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.event_seat_rounded,
                                      color: midnightBlue,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sélection de places',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: midnightBlue,
                                          ),
                                        ),
                                        Text(
                                          'Permettez la sélection de places',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _hasSeats,
                                    onChanged: (value) {
                                      setState(() {
                                        _hasSeats = value;
                                        if (_hasSeats && !_isFree) {
                                          _priceController.clear();
                                        }
                                      });
                                    },
                                    activeColor: midnightBlue,
                                    inactiveThumbColor: Colors.grey[400],
                                  ),
                                ],
                              ),
                              if (_hasSeats) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildModernInputField(
                                        controller: _numberOfRowsController,
                                        label: 'Rangées',
                                        hint: 'Ex: 8 (1-26)',
                                        icon: Icons.layers_rounded,
                                        isRequired: true,
                                        keyboardType: TextInputType.number,
                                        validator: _hasSeats ? (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Requis';
                                          }
                                          final n = int.tryParse(value);
                                          if (n == null || n <= 0 || n > 26) {
                                            return '1-26';
                                          }
                                          return null;
                                        } : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildModernInputField(
                                        controller: _seatsPerRowController,
                                        label: 'Places/rangée',
                                        hint: 'Ex: 12',
                                        icon: Icons.event_seat_rounded,
                                        isRequired: true,
                                        keyboardType: TextInputType.number,
                                        validator: _hasSeats ? (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Requis';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Nombre';
                                          }
                                          return null;
                                        } : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildModernInputField(
                                  controller: _frontSeatPriceController,
                                  label: 'Prix - Sièges avant',
                                  hint: 'Sièges premium',
                                  icon: Icons.attach_money_rounded,
                                  isRequired: true,
                                  prefixText: 'TND ',
                                  keyboardType: TextInputType.number,
                                  validator: _hasSeats ? (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requis';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Prix valide';
                                    }
                                    return null;
                                  } : null,
                                ),
                                const SizedBox(height: 12),
                                _buildModernInputField(
                                  controller: _regularSeatPriceController,
                                  label: 'Prix - Autres sièges',
                                  hint: 'Sièges réguliers',
                                  icon: Icons.attach_money_rounded,
                                  isRequired: true,
                                  prefixText: 'TND ',
                                  keyboardType: TextInputType.number,
                                  validator: _hasSeats ? (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Requis';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Prix valide';
                                    }
                                    return null;
                                  } : null,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                onPressed: (_isLoading || _isUploadingImage) ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: midnightBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading || _isUploadingImage
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Créer l\'événement',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isRequired = false,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 32 : 36,
                height: isSmallScreen ? 32 : 36,
                decoration: BoxDecoration(
                  color: midnightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: midnightBlue, size: isSmallScreen ? 18 : 20),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: midnightBlue,
                  letterSpacing: -0.3,
                ),
              ),
              if (isRequired)
                _buildRequiredAsterisk(),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    bool isRequired = false,
    String? Function(String?)? validator,
    bool isSmallScreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w500,
                color: midnightBlue.withOpacity(0.6),
              ),
            ),
            if (isRequired)
              _buildRequiredAsterisk(),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 15,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: textSecondary.withOpacity(0.6),
                fontSize: isSmallScreen ? 12 : 13,
              ),
              prefixIcon: Icon(icon, color: midnightBlue, size: isSmallScreen ? 18 : 20),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                color: midnightBlue,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: midnightBlue, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: error, width: 1),
              ),
              filled: true,
              fillColor: cream,
              contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: isSmallScreen ? 14 : 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String) onChanged,
    bool isRequired = false,
    bool isSmallScreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w500,
                color: midnightBlue.withOpacity(0.6),
              ),
            ),
            if (isRequired)
              _buildRequiredAsterisk(),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: midnightBlue, size: isSmallScreen ? 18 : 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: midnightBlue, width: 1.5),
              ),
              filled: true,
              fillColor: cream,
              contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: isSmallScreen ? 12 : 14),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(fontSize: isSmallScreen ? 13 : 15)),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
            icon: Icon(Icons.arrow_drop_down_rounded, color: midnightBlue),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lieu',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: midnightBlue.withOpacity(0.6),
              ),
            ),
            _buildRequiredAsterisk(),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
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

            if (result != null) {
              setState(() {
                _latitude = result['latitude'];
                _longitude = result['longitude'];
                _locationController.text = result['location_name'];
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextFormField(
              controller: _locationController,
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le lieu est requis';
                }
                return null;
              },
              style: TextStyle(
                fontSize: 15,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Cliquez pour choisir un lieu sur la carte',
                hintStyle: TextStyle(
                  color: textSecondary.withOpacity(0.6),
                ),
                prefixIcon: Icon(Icons.location_on_rounded, color: midnightBlue, size: 20),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: midnightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: midnightBlue, width: 1.5),
                ),
                filled: true,
                fillColor: cream,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerSection({bool isSmallScreen = false}) {
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
                        : Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
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
                    'Cliquez pour choisir une image',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: midnightBlue.withOpacity(0.6),
              ),
            ),
            _buildRequiredAsterisk(),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.calendar_today_rounded, color: midnightBlue, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cream,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              child: Text(
                _selectedDate != null
                    ? DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate!)
                    : 'Choisissez une date',
                style: TextStyle(
                  fontSize: 15,
                  color: _selectedDate != null ? textPrimary : textSecondary,
                  fontWeight: _selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Heure',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: midnightBlue.withOpacity(0.6),
              ),
            ),
            _buildRequiredAsterisk(),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.access_time_rounded, color: midnightBlue, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cream,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              child: Text(
                _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'Choisissez une heure',
                style: TextStyle(
                  fontSize: 15,
                  color: _selectedTime != null ? textPrimary : textSecondary,
                  fontWeight: _selectedTime != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}