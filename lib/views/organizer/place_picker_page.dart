import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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

  // ── Auto reverse-geocode when user taps the map ──────────────────────────
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

  // ── Search with debounce (waits 500 ms after user stops typing) ──────────
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

  // ── Get current GPS position ─────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
        await _onMapTapped(LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // ── Confirm and return data ───────────────────────────────────────────────
  void _confirmLocation() {
    Navigator.pop(context, {
      'latitude': _latitude,
      'longitude': _longitude,
      'location_name': _address,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_latitude, _longitude),
              initialZoom: 13,
              onTap: (_, latLng) => _onMapTapped(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_latitude, _longitude),
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.deepPurple,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Top search bar ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(14),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un lieu...',
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.deepPurple),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                              )
                            : _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  // Search results dropdown
                  if (_searchResults.isNotEmpty)
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.32,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, i) {
                              final place = _searchResults[i];
                              return ListTile(
                                leading: const Icon(
                                  Icons.place_outlined,
                                  color: Colors.deepPurple,
                                ),
                                title: Text(
                                  place.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
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

          // ── Bottom card (address + buttons) ─────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Address row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.deepPurple, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _isLoadingAddress
                            ? const Text('Chargement...',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14))
                            : Text(
                                _address,
                                style: const TextStyle(
                                    fontSize: 14, height: 1.4),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Buttons row
                  Row(
                    children: [
                      // My location button
                      OutlinedButton.icon(
                        onPressed: _isLoadingLocation
                            ? null
                            : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location,
                                color: Colors.deepPurple),
                        label: const Text('Ma position',
                            style: TextStyle(color: Colors.deepPurple)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.deepPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Confirm button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _confirmLocation,
                          icon: const Icon(Icons.check),
                          label: const Text('Confirmer ce lieu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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

// ── Simple data class ────────────────────────────────────────────────────────
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