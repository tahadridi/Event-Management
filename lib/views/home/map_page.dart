import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as Math;

import 'package:flutter/services.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_detail_page.dart';


class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final MapController _mapController = MapController();

  List<EventModel> _events = [];
  LatLng _currentPosition = const LatLng(36.8065, 10.1815);
  bool _locationLoaded = false;
  String _selectedCategory = 'Tous';
  EventModel? _selectedEvent;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Distance filter
  double _maxDistance = 50; // in kilometers
  bool _locationPermissionGranted = false;

  final List<String> _categories = [
    'Tous', 'Concert', 'Sport', 'Art',
    'Conférence', 'Atelier', 'Autre'
  ];

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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _getUserLocation();
    _loadEvents();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) {
          setState(() {
            _currentPosition =
                LatLng(position.latitude, position.longitude);
            _locationLoaded = true;
          });
          _mapController.move(_currentPosition, 13);
        }
      }
    } catch (_) {}
  }

  void _loadEvents() {
    _eventService.getEvents().listen((events) {
      if (mounted) setState(() => _events = events);
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (mounted) {
          setState(() => _locationPermissionGranted =
              newPermission == LocationPermission.whileInUse ||
              newPermission == LocationPermission.always);
        }
      } else {
        if (mounted) {
          setState(() => _locationPermissionGranted =
              permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _locationPermissionGranted = false);
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        Math.cos((lat2 - lat1) * p) / 2 +
        Math.cos(lat1 * p) *
            Math.cos(lat2 * p) *
            (1 - Math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R = 6371 km
  }

  List<EventModel> get _filtered {
    var list = _selectedCategory == 'Tous'
        ? _events
        : _events.where((e) => e.category == _selectedCategory).toList();
    
    list = list
        .where((e) => !(e.latitude == 0 && e.longitude == 0))
        .toList();
    
    // Apply distance filter if location permission granted and distance < 50
    if (_locationPermissionGranted && _maxDistance < 50) {
      list = list.where((e) {
        final distance = _calculateDistance(
          _currentPosition.latitude,
          _currentPosition.longitude,
          e.latitude,
          e.longitude,
        );
        return distance <= _maxDistance;
      }).toList();
    }
    
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(  // Add SafeArea to handle status bar properly
        child: Column(
          children: [
            // Header - remove extra padding
            _buildHeader(isSmallScreen),
            
            // Content - Expanded will take remaining space
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,  // Change to min to prevent unnecessary expansion
                  children: [
                    // Category filter
                    _buildCategoryFilter(),
                    
                    // Distance filter
                    if (_locationPermissionGranted)
                      _buildDistanceFilter(),
                    
                    // Event counter
                    _buildEventCounter(),
                    
                    // Map - Expanded with flex to take remaining space
                    Expanded(
                      flex: 1,  // Give map more flexibility
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentPosition,
                              initialZoom: 11,
                              onTap: (_, __) =>
                                  setState(() => _selectedEvent = null),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'EventProject/1.0',
                              ),
                              // User location marker
                              if (_locationLoaded)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _currentPosition,
                                      width: 40,
                                      height: 40,
                                      child: _buildUserLocationMarker(),
                                    ),
                                  ],
                                ),
                              // Event markers
                              MarkerLayer(
                                markers: _filtered.map((event) {
                                  final isSelected =
                                      _selectedEvent?.id == event.id;
                                  return Marker(
                                    point: LatLng(event.latitude, event.longitude),
                                    width: isSelected ? 56 : 48,
                                    height: isSelected ? 56 : 48,
                                    child: _buildEventMarker(event, isSelected),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          
                          // Floating action buttons
                          _buildFloatingButtons(),
                          
                          // Selected event popup
                          if (_selectedEvent != null)
                            _buildEventPopup(_selectedEvent!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20, 
        vertical: 12  // Changed from top padding to vertical padding
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: midnightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: midnightBlue,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carte des événements',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: midnightBlue,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Explorez les événements autour de vous',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryFilter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _selectedEvent = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? midnightBlue : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? midnightBlue : midnightBlue.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: midnightBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDistanceFilter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: midnightBlue.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                _maxDistance == 50
                    ? 'Sans limite'
                    : 'Jusqu\'à ${_maxDistance.toInt()} km',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: midnightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: midnightBlue,
            inactiveColor: midnightBlue.withOpacity(0.2),
            label: _maxDistance == 50
                ? 'Sans limite'
                : '${_maxDistance.toInt()} km',
            onChanged: (v) => setState(() => _maxDistance = v),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCounter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Added vertical margin
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: midnightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.location_on_rounded,
              size: 16,
              color: midnightBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_filtered.length} événement${_filtered.length > 1 ? 's' : ''} sur la carte',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: midnightBlue.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: midnightBlue, width: 2),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: midnightBlue,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEventMarker(EventModel event, bool isSelected) {
    final isSoldOut = event.availablePlaces == 0;
    final markerColor = isSoldOut ? error : (isSelected ? accent : midnightBlue);
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedEvent = event);
        _mapController.move(
          LatLng(event.latitude, event.longitude),
          14,
        );
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: isSelected ? 56 : 48,
              height: isSelected ? 56 : 48,
              decoration: BoxDecoration(
                color: markerColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: isSelected ? 44 : 36,
              height: isSelected ? 44 : 36,
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: markerColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: isSelected ? 26 : 22,
              ),
            ),
            if (isSelected)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      right: 16,
      bottom: _selectedEvent != null ? 220 : 24,
      child: Column(
        children: [
          // My location button
          _buildFloatingButton(
            icon: Icons.my_location_rounded,
            onPressed: () {
              _mapController.move(_currentPosition, 13);
              HapticFeedback.lightImpact();
            },
          ),
          const SizedBox(height: 12),
          // Zoom in button
          _buildFloatingButton(
            icon: Icons.add_rounded,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
              HapticFeedback.lightImpact();
            },
          ),
          const SizedBox(height: 12),
          // Zoom out button
          _buildFloatingButton(
            icon: Icons.remove_rounded,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Icon(icon, color: midnightBlue, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildEventPopup(EventModel event) {
    final isSoldOut = event.availablePlaces == 0;
    
    return AnimatedPositioned(  // Changed to AnimatedPositioned for better animation
      duration: const Duration(milliseconds: 300),
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedEvent = null),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            _buildPopupInfoRow(
              icon: Icons.location_on_rounded,
              text: event.location,
            ),
            const SizedBox(height: 12),

            // Category
            _buildPopupInfoRow(
              icon: Icons.category_rounded,
              text: event.category,
              customColor: accent,
            ),
            const SizedBox(height: 12),

            // Price and availability row
            Row(
              children: [
                _buildPopupInfoChip(
                  icon: Icons.people_rounded,
                  text: '${event.availablePlaces} places',
                  color: isSoldOut ? error : midnightBlue,
                ),
                const SizedBox(width: 12),
                _buildPopupInfoChip(
                  icon: Icons.payments_rounded,
                  text: event.price == 0
                      ? 'Gratuit'
                      : '${event.price.toStringAsFixed(0)} TND',
                  color: midnightBlue,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Details button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _selectedEvent = null);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailPage(event: event),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: midnightBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Voir les détails',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupInfoRow({
    required IconData icon,
    required String text,
    Color? customColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: customColor ?? textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}