import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final EventService _eventService = EventService();
  final MapController _mapController = MapController();

  List<EventModel> _events = [];
  LatLng _currentPosition = const LatLng(36.8065, 10.1815);
  bool _locationLoaded = false;
  String _selectedCategory = 'Tous';
  EventModel? _selectedEvent;

  final List<String> _categories = [
    'Tous', 'Musique', 'Sport', 'Art',
    'Conférence', 'Atelier', 'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadEvents();
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

  List<EventModel> get _filtered {
    final list = _selectedCategory == 'Tous'
        ? _events
        : _events.where((e) => e.category == _selectedCategory).toList();
    // Garde seulement les events avec coordonnées réelles
    return list
        .where((e) => !(e.latitude == 0 && e.longitude == 0))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des événements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtre catégories
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat,
                        style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      _selectedCategory = cat;
                      _selectedEvent = null;
                    }),
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),

          // Compteur
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            color: Colors.deepPurple.shade50,
            child: Text(
              '${_filtered.length} événement(s) sur la carte',
              style: const TextStyle(
                  fontSize: 13, color: Colors.deepPurple),
            ),
          ),

          // Carte
          Expanded(
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
                    // Tuiles OSM — même config que ton PlacePickerPage
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.event_project',
                    ),

                    // Position utilisateur
                    if (_locationLoaded)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.blue, width: 2),
                              ),
                              child: const Icon(Icons.circle,
                                  color: Colors.blue, size: 14),
                            ),
                          ),
                        ],
                      ),

                    // Marqueurs événements
                    MarkerLayer(
                      markers: _filtered.map((event) {
                        final isSelected =
                            _selectedEvent?.id == event.id;
                        return Marker(
                          point:
                              LatLng(event.latitude, event.longitude),
                          width: isSelected ? 48 : 40,
                          height: isSelected ? 48 : 40,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedEvent = event);
                              // Centre la carte sur l'événement
                              _mapController.move(
                                LatLng(event.latitude, event.longitude),
                                14,
                              );
                            },
                            child: Icon(
                              Icons.location_pin,
                              color: event.availablePlaces == 0
                                  ? Colors.red
                                  : isSelected
                                      ? Colors.orange
                                      : Colors.deepPurple,
                              size: isSelected ? 48 : 38,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Boutons flottants
                Positioned(
                  right: 16,
                  bottom: _selectedEvent != null ? 210 : 24,
                  child: Column(
                    children: [
                      // Ma position
                      FloatingActionButton.small(
                        heroTag: 'loc',
                        backgroundColor: Colors.white,
                        onPressed: () =>
                            _mapController.move(_currentPosition, 13),
                        child: const Icon(Icons.my_location,
                            color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      // Zoom +
                      FloatingActionButton.small(
                        heroTag: 'zin',
                        backgroundColor: Colors.white,
                        onPressed: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      // Zoom -
                      FloatingActionButton.small(
                        heroTag: 'zout',
                        backgroundColor: Colors.white,
                        onPressed: () => _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        ),
                        child: const Icon(Icons.remove,
                            color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ),

                // Popup événement sélectionné
                if (_selectedEvent != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildPopup(_selectedEvent!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopup(EventModel event) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre + fermer
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedEvent = null),
                child: const Icon(Icons.close,
                    size: 20, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Lieu
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 14, color: Colors.deepPurple),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Places + Prix
          Row(
            children: [
              const Icon(Icons.people,
                  size: 14, color: Colors.deepPurple),
              const SizedBox(width: 4),
              Text(
                '${event.availablePlaces} places',
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey),
              ),
              const Spacer(),
              Text(
                event.price == 0
                    ? 'Gratuit'
                    : '${event.price.toStringAsFixed(0)} TND',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bouton détails
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _selectedEvent = null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EventDetailPage(event: event),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Voir les détails'),
            ),
          ),
        ],
      ),
    );
  }
}