import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// ─────────────────────────────────────────────────────────────
// DESIGN SYSTEM - Midnight Blue & White Theme
// ─────────────────────────────────────────────────────────────

class PlacePickerTheme {
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF1A3A7C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color error = Color(0xFFEF4444);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnightBlue, midnightBlueLight],
  );
}

class PlacePickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialLocationName;

  const PlacePickerPage({
    Key? key,
    this.initialLat,
    this.initialLng,
    this.initialLocationName,
  }) : super(key: key);

  @override
  State<PlacePickerPage> createState() => _PlacePickerPageState();
}

class _PlacePickerPageState extends State<PlacePickerPage> {
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  late double _latitude;
  late double _longitude;
  String _address = 'Appuyez sur la carte pour choisir un lieu';
  bool _isLoadingLocation = false;
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  List<_PlaceResult> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _latitude = widget.initialLat ?? 36.8065;
    _longitude = widget.initialLng ?? 10.1815;

    if (widget.initialLocationName != null) {
      _address = widget.initialLocationName!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onMapTapped(LatLng latLng) async {
    setState(() {
      _latitude = latLng.latitude;
      _longitude = latLng.longitude;
      _isLoadingAddress = true;
      _address = 'Chargement de l\'adresse...';
      _searchResults = [];
      _searchController.clear();
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${latLng.latitude}&lon=${latLng.longitude}'
        '&format=json',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'EventProject/1.0'})
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _address = data['display_name'] ?? _coordinatesText();
        });
      } else {
        setState(() => _address = _coordinatesText());
      }
    } catch (_) {
      setState(() => _address = _coordinatesText());
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  String _coordinatesText() =>
      '${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}';

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query.trim());
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=6&countrycodes=tn',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'EventProject/1.0'})
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _searchResults = data
              .map((item) => _PlaceResult(
                    name: item['display_name'] ?? '',
                    latitude: double.tryParse(item['lat'].toString()) ?? 0,
                    longitude: double.tryParse(item['lon'].toString()) ?? 0,
                  ))
              .toList();
        });
      }
    } catch (_) {
      // silently fail — user still has the map
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectResult(_PlaceResult place) {
    setState(() {
      _latitude = place.latitude;
      _longitude = place.longitude;
      _address = place.name;
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(LatLng(_latitude, _longitude), 16);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('La permission de localisation est requise. Veuillez l\'activer dans les paramètres.'),
              backgroundColor: PlacePickerTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        await Geolocator.openAppSettings();
      } else if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
          await _onMapTapped(LatLng(pos.latitude, pos.longitude));
        }
      } else if (perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permission de localisation requise'),
              backgroundColor: PlacePickerTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: PlacePickerTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'latitude': _latitude,
      'longitude': _longitude,
      'location_name': _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_latitude, _longitude),
              initialZoom: 13,
              onTap: (_, latLng) => _onMapTapped(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'EventProject/1.0',
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: null,
                  ),
                ],
                alignment: AttributionAlignment.bottomRight,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_latitude, _longitude),
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      color: PlacePickerTheme.midnightBlue,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top search bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Choisir un lieu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: PlacePickerTheme.midnightBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(20),
                    shadowColor: PlacePickerTheme.midnightBlue.withOpacity(0.1),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un lieu...',
                        hintStyle: TextStyle(
                          color: PlacePickerTheme.textHint,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: PlacePickerTheme.midnightBlue,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: PlacePickerTheme.textHint,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                              )
                            : _isSearching
                                ? Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          PlacePickerTheme.midnightBlue,
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                        filled: true,
                        fillColor: PlacePickerTheme.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: PlacePickerTheme.midnightBlue,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),

                  // Search results dropdown
                  if (_searchResults.isNotEmpty)
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.35,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: PlacePickerTheme.textHint.withOpacity(0.2),
                            ),
                            itemBuilder: (context, i) {
                              final place = _searchResults[i];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: PlacePickerTheme.midnightBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.place_rounded,
                                    color: PlacePickerTheme.midnightBlue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  place.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: PlacePickerTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () => _selectResult(place),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom card (address + buttons)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: PlacePickerTheme.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: PlacePickerTheme.textHint.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Address row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PlacePickerTheme.midnightBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: PlacePickerTheme.midnightBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isLoadingAddress
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        PlacePickerTheme.midnightBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Chargement...',
                                    style: TextStyle(
                                      color: PlacePickerTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _address,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: PlacePickerTheme.textPrimary,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Buttons row
                  Row(
                    children: [
                      // My location button
                      OutlinedButton.icon(
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    PlacePickerTheme.midnightBlue,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.my_location_rounded,
                                color: PlacePickerTheme.midnightBlue,
                                size: 18,
                              ),
                        label: Text(
                          'Ma position',
                          style: TextStyle(
                            color: PlacePickerTheme.midnightBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: PlacePickerTheme.midnightBlue, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Confirm button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _confirmLocation,
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text(
                            'Confirmer ce lieu',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PlacePickerTheme.midnightBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple data class
class _PlaceResult {
  final String name;
  final double latitude;
  final double longitude;

  _PlaceResult({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}