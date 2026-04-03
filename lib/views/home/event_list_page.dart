import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/user_service.dart';
import '../../widgets/event_card.dart';
import 'event_detail_page.dart';

class _EventListTheme {
  // Midnight Blue & Cream Theme
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF0F2A6B);
  static const Color midnightBlueCard = Color(0xFF0C2466);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color creamDark = Color(0xFFE8E0D4);
  static const Color accent = Color(0xFFE67E22); // Warm orange accent
  static const Color accentLight = Color(0xFFF39C12);
  
  // Background & Surfaces
  static const Color background = cream;

  static const Color border = Color(0xFFE0D9CE);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  
  // Status colors

}

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  Set<String> _userFavorites = {};
  Set<String> _userReservations = {}; // Track user's event reservations
  String _selectedCategory = 'Tous';
  double _minPrice = 0;
  double _maxPrice = 200;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showOnlyFavorites = false;
  bool _showFilters = false;
  
  // Place filter
  String _selectedPlace = 'Toutes les villes';
  List<String> _availablePlaces = [];

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Tous', 'icon': Icons.apps_rounded},
    {'label': 'Concert', 'icon': Icons.music_note_rounded},
    {'label': 'Sport', 'icon': Icons.sports_soccer_rounded},
    {'label': 'Art', 'icon': Icons.palette_rounded},
    {'label': 'Conférence', 'icon': Icons.mic_rounded},
    {'label': 'Atelier', 'icon': Icons.build_rounded},
    {'label': 'Séminaire', 'icon': Icons.school_rounded},
    {'label': 'Autre', 'icon': Icons.category_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadUserReservations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await _userService.getUserFavoritesStream().first;
      if (mounted) setState(() => _userFavorites = Set.from(favs));
    } catch (_) {}
  }

  Future<void> _loadUserReservations() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final querySnapshot = await _db
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .get();

      final reservedEventIds = <String>{};
      for (final doc in querySnapshot.docs) {
        reservedEventIds.add(doc['eventId'] as String);
      }

      if (mounted) {
        setState(() => _userReservations = reservedEventIds);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String eventId) async {
    try {
      await _userService.toggleFavorite(eventId);
      
      setState(() {
        if (_userFavorites.contains(eventId)) {
          _userFavorites.remove(eventId);
        } else {
          _userFavorites.add(eventId);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _userFavorites.contains(eventId) 
              ? 'Ajouté aux favoris' 
              : 'Retiré des favoris',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          backgroundColor: _EventListTheme.midnightBlue,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur: ${e.toString()}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          backgroundColor: _EventListTheme.accent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _EventListTheme.midnightBlue,
              secondary: _EventListTheme.accent,
              surface: Colors.white,
              onSurface: _EventListTheme.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'Tous';
      _minPrice = 0;
      _maxPrice = 200;
      _startDate = null;
      _endDate = null;
      _showOnlyFavorites = false;
      _selectedPlace = 'Toutes les villes';
    });
  }

  bool get _hasActiveFilters =>
      _selectedCategory != 'Tous' ||
      _minPrice > 0 ||
      _maxPrice < 200 ||
      _startDate != null ||
      _endDate != null ||
      _showOnlyFavorites ||
      _selectedPlace != 'Toutes les villes';

  List<EventModel> _applyFilters(List<EventModel> events) {
    final query = _searchController.text.toLowerCase();
    return events.where((e) {
      if (query.isNotEmpty &&
          !e.title.toLowerCase().contains(query) &&
          !e.location.toLowerCase().contains(query)) return false;
      if (_selectedCategory != 'Tous' &&
          e.category.toLowerCase() != _selectedCategory.toLowerCase())
        return false;
      if (e.price < _minPrice || e.price > _maxPrice) return false;
      if (_startDate != null && e.date.isBefore(_startDate!)) return false;
      if (_endDate != null &&
          e.date.isAfter(_endDate!.add(const Duration(days: 1))))
        return false;
      if (_showOnlyFavorites && !_userFavorites.contains(e.id)) return false;
      
      // Place filter
      if (_selectedPlace != 'Toutes les villes' &&
          e.location != _selectedPlace) return false;
      
      return true;
    }).toList()
      ..sort((a, b) {
        final aFav = _userFavorites.contains(a.id);
        final bFav = _userFavorites.contains(b.id);
        if (aFav && !bFav) return -1;
        if (!aFav && bFav) return 1;
        return a.date.compareTo(b.date);
      });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 480;
    final expandedHeight = isSmallScreen ? 160.0 : 180.0;
    final headerPaddingTop = isSmallScreen ? 12.0 : 16.0;
    final headerPaddingBottom = isSmallScreen ? 16.0 : 24.0;
    final titleFontSize = isSmallScreen ? 28.0 : 34.0;
    final subtitleFontSize = isSmallScreen ? 13.0 : 15.0;

    return Scaffold(
      backgroundColor: _EventListTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header with Midnight Blue gradient
          SliverAppBar(
            expandedHeight: expandedHeight,
            pinned: true,
            backgroundColor: _EventListTheme.midnightBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _EventListTheme.midnightBlue,
                      _EventListTheme.midnightBlueLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, headerPaddingTop, 20, headerPaddingBottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Découvrir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              'Trouvez votre prochain événement',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w500,
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
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(isSmallScreen ? 52 : 60),
              child: Container(
                margin: EdgeInsets.fromLTRB(16, 0, 16, isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: _EventListTheme.textPrimary,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    hintStyle: TextStyle(
                      color: _EventListTheme.textHint,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: _EventListTheme.midnightBlue,
                      size: isSmallScreen ? 20 : 22,
                    ),
                    suffixIcon: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: isSmallScreen ? 16 : 18,
                                color: _EventListTheme.textSecondary,
                              ),
                              onPressed: () => setState(
                                () => _searchController.clear(),
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          Stack(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.tune_rounded,
                                  size: isSmallScreen ? 20 : 22,
                                  color: _showFilters || _hasActiveFilters
                                      ? _EventListTheme.midnightBlue
                                      : _EventListTheme.textSecondary,
                                ),
                                onPressed: () => setState(
                                  () => _showFilters = !_showFilters,
                                ),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                              if (_hasActiveFilters)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _EventListTheme.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10 : 14,
                      horizontal: 4,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filters panel
          if (_showFilters)
            SliverToBoxAdapter(
              child: Container(
                color: _EventListTheme.background,
                padding: EdgeInsets.fromLTRB(
                  20,
                  isSmallScreen ? 6 : 8,
                  20,
                  isSmallScreen ? 12 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtres',
                          style: TextStyle(
                            color: _EventListTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 18 : 20,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: _resetFilters,
                            style: TextButton.styleFrom(
                              foregroundColor: _EventListTheme.midnightBlue,
                            ),
                            child: Text(
                              'Réinitialiser',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 16),

                    // Favorites toggle
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _EventListTheme.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: isSmallScreen ? 18 : 22,
                            color: _EventListTheme.accent,
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Text(
                            'Favoris uniquement',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: _EventListTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _showOnlyFavorites,
                            onChanged: (v) =>
                                setState(() => _showOnlyFavorites = v),
                            activeColor: _EventListTheme.midnightBlue,
                            inactiveThumbColor: _EventListTheme.textSecondary,
                            inactiveTrackColor: _EventListTheme.border,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Price range
                    Text(
                      'Prix',
                      style: TextStyle(
                        color: _EventListTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _minPrice == 0 && _maxPrice == 200
                              ? 'Tous les prix'
                              : '${_minPrice.toInt()} – ${_maxPrice.toInt()} TND',
                          style: TextStyle(
                            color: _EventListTheme.midnightBlue,
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_minPrice, _maxPrice),
                      min: 0,
                      max: 200,
                      divisions: 20,
                      activeColor: _EventListTheme.midnightBlue,
                      inactiveColor: _EventListTheme.border,
                      labels: RangeLabels(
                        '${_minPrice.toInt()} TND',
                        '${_maxPrice.toInt()} TND',
                      ),
                      onChanged: (v) => setState(() {
                        _minPrice = v.start;
                        _maxPrice = v.end;
                      }),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Date range
                    Text(
                      'Période',
                      style: TextStyle(
                        color: _EventListTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: _dateButton(
                            label: _startDate == null
                                ? 'Début'
                                : DateFormat('dd MMM', 'fr')
                                    .format(_startDate!),
                            onTap: () => _selectDate(true),
                            active: _startDate != null,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Expanded(
                          child: _dateButton(
                            label: _endDate == null
                                ? 'Fin'
                                : DateFormat('dd MMM', 'fr')
                                    .format(_endDate!),
                            onTap: () => _selectDate(false),
                            active: _endDate != null,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        if (_startDate != null || _endDate != null)
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: isSmallScreen ? 16 : 18,
                              color: _EventListTheme.textSecondary,
                            ),
                            onPressed: () => setState(() {
                              _startDate = null;
                              _endDate = null;
                            }),
                            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Place filter
                    Text(
                      'Lieu',
                      style: TextStyle(
                        color: _EventListTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _EventListTheme.border,
                          width: 1,
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedPlace,
                        items: _availablePlaces.isEmpty
                            ? [
                                DropdownMenuItem(
                                  value: 'Toutes les villes',
                                  child: Text(
                                    'Toutes les villes',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      color: _EventListTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ]
                            : _availablePlaces
                                .map(
                                  (place) => DropdownMenuItem(
                                    value: place,
                                    child: Text(
                                      place,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: _EventListTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPlace = value);
                          }
                        },
                        underline: const SizedBox(),
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: _EventListTheme.textSecondary,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Category chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: isSmallScreen ? 48 : 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: isSmallScreen ? 8 : 10),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat['label'];
                  return GestureDetector(
                    onTap: () => setState(
                      () => _selectedCategory = cat['label'],
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? _EventListTheme.midnightBlue
                            : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: selected
                              ? _EventListTheme.midnightBlue
                              : _EventListTheme.border,
                          width: 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: _EventListTheme.midnightBlue
                                      .withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: isSmallScreen ? 16 : 18,
                            color: selected
                                ? Colors.white
                                : _EventListTheme.textSecondary,
                          ),
                          SizedBox(width: isSmallScreen ? 6 : 8),
                          Text(
                            cat['label'],
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : _EventListTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Events list
          StreamBuilder<List<EventModel>>(
            stream: _eventService.getEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _EventListTheme.midnightBlue,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 80,
                          color: _EventListTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun événement disponible',
                          style: TextStyle(
                            color: _EventListTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Update available places
              final places = <String>{'Toutes les villes'};
              for (var event in snapshot.data!) {
                if (event.location.isNotEmpty) {
                  places.add(event.location);
                }
              }
              final placesList = places.toList()..sort();
              if (!listEquals(placesList, _availablePlaces)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _availablePlaces = placesList);
                });
              }

              final filtered = _applyFilters(snapshot.data!);

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: _EventListTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun résultat trouvé',
                          style: TextStyle(
                            color: _EventListTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _resetFilters,
                          style: TextButton.styleFrom(
                            foregroundColor: _EventListTheme.midnightBlue,
                          ),
                          child: const Text('Réinitialiser les filtres'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          isSmallScreen ? 6 : 8,
                          20,
                          isSmallScreen ? 10 : 16,
                        ),
                        child: Text(
                          '${filtered.length} événement${filtered.length > 1 ? 's' : ''} trouvé${filtered.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            color: _EventListTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    final event = filtered[index - 1];
                    return EventCard(
                      event: event,
                      isFavorite: _userFavorites.contains(event.id),
                      hasUserReservation: _userReservations.contains(event.id),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailPage(event: event),
                        ),
                      ),
                      onFavoriteTap: () => _toggleFavorite(event.id),
                    );
                  },
                  childCount: filtered.length + 1,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required VoidCallback onTap,
    required bool active,
    bool isSmallScreen = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 12,
          vertical: isSmallScreen ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: active
              ? _EventListTheme.midnightBlue.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? _EventListTheme.midnightBlue : _EventListTheme.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: isSmallScreen ? 12 : 14,
              color: active
                  ? _EventListTheme.midnightBlue
                  : _EventListTheme.textSecondary,
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: active
                      ? _EventListTheme.midnightBlue
                      : _EventListTheme.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}