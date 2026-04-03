import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
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
    _latitude = widget.event.latitude;
    _longitude = widget.event.longitude;

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _updateEvent();
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

  void _updateEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate seating configuration if hasSeats is enabled
      if (_hasSeats) {
        if (_numberOfRowsController.text.isEmpty || _seatsPerRowController.text.isEmpty ||
            _frontSeatPriceController.text.isEmpty || _regularSeatPriceController.text.isEmpty) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Veuillez remplir tous les champs de configuration des sièges');
          return;
        }
      }

      await _eventService.updateEvent(
        eventId: widget.event.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        location: _locationController.text,
        date: _selectedDate,
        time: _selectedTime,
        totalPlaces: int.parse(_capacityController.text),
        price: (_hasSeats || _isFree) ? 0.0 : double.parse(_priceController.text),
        latitude: _latitude,
        longitude: _longitude,
        hasSeats: _hasSeats,
        numberOfRows: _hasSeats ? int.parse(_numberOfRowsController.text) : 0,
        seatsPerRow: _hasSeats ? int.parse(_seatsPerRowController.text) : 0,
        frontSeatPrice: _hasSeats ? double.parse(_frontSeatPriceController.text) : 0.0,
        regularSeatPrice: _hasSeats ? double.parse(_regularSeatPriceController.text) : 0.0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Événement mis à jour avec succès !'),
            backgroundColor: const Color(0xFF10B981),
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
      backgroundColor: const Color(0xFFF8F3EA),
      appBar: AppBar(
        title: const Text(
          'Modifier l\'événement',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: Color(0xFF081F5C),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF081F5C),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        toolbarHeight: 100,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8F3EA),
                Color(0xFFF5EDE2),
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

                  // Location Field with Place Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationField(),
                      if (_latitude != null && _longitude != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF081F5C).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: const Color(0xFF081F5C),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Coordonnées: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFF081F5C).withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
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

                  // Price Section
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
                                    color: const Color(0xFF081F5C),
                                  ),
                                ),
                              ),
                              Switch(
                                value: _isFree,
                                onChanged: (value) {
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
                        if (!_isFree)
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
                                if (!_isFree &&
                                    (value == null || value.isEmpty)) {
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
                              color: const Color(0xFF081F5C).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF081F5C),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF081F5C),
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
                                    valueColor:
                                        AlwaysStoppedAnimation(Color(0xFFF8F3EA)),
                                  ),
                                )
                              : const Text(
                                  'Enregistrer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF8F3EA),
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
          readOnly: true,
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
}