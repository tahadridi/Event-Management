import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/user_service.dart';
import '../home/event_detail_page.dart';

// ─────────────────────────────────────────────────────────────
// DESIGN SYSTEM - Midnight Blue & White Theme
// ─────────────────────────────────────────────────────────────

class SearchTheme {
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF1A3A7C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnightBlue, midnightBlueLight],
  );
}

class EventSearchPage extends StatefulWidget {
  const EventSearchPage({Key? key}) : super(key: key);

  @override
  State<EventSearchPage> createState() => _EventSearchPageState();
}

class _EventSearchPageState extends State<EventSearchPage> {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCategory = 'Tous';
  double _minPrice = 0;
  double _maxPrice = 200;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;
  bool _showOnlyFavorites = false;
  List<EventModel> _searchResults = [];
  bool _isLoading = false;
  Set<String> _userFavorites = {};

  final List<String> _categories = [
    'Tous',
    'Conférence',
    'Atelier',
    'Séminaire',
    'Concert',
    'Sport',
    'Réunion',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserFavorites();
  }

  Future<void> _loadUserFavorites() async {
    final userService = UserService();
    try {
      final favorites = await userService.getUserFavoritesStream().first;
      if (mounted) {
        setState(() => _userFavorites = Set.from(favorites));
        await _performSearch();
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty && _selectedCategory == 'Tous' && !_showOnlyFavorites) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _eventService.searchEvents(
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        category: _selectedCategory == 'Tous' ? null : _selectedCategory,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 200 ? _maxPrice : null,
        startDate: _startDate,
        endDate: _endDate,
      );

      var filtered = _showOnlyFavorites
          ? results.where((event) => _userFavorites.contains(event.id)).toList()
          : results;

      filtered.sort((a, b) {
        final aIsFav = _userFavorites.contains(a.id);
        final bIsFav = _userFavorites.contains(b.id);
        if (aIsFav && !bIsFav) return -1;
        if (!aIsFav && bIsFav) return 1;
        return 0;
      });

      setState(() {
        _searchResults = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: SearchTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: SearchTheme.midnightBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      await _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchTheme.cream,
      appBar: AppBar(
        title: const Text(
          'Rechercher',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: SearchTheme.midnightBlue,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _performSearch(),
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Tapez un mot-clé...',
                    hintStyle: TextStyle(
                      color: SearchTheme.textHint,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: SearchTheme.midnightBlue,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: SearchTheme.textHint,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
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
                      borderSide: const BorderSide(
                        color: SearchTheme.midnightBlue,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: SearchTheme.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filter toggle
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showFilters = !_showFilters),
                    icon: Icon(
                      Icons.tune_rounded,
                      color: SearchTheme.midnightBlue,
                      size: 20,
                    ),
                    label: Text(
                      _showFilters ? 'Masquer les filtres' : 'Filtres',
                      style: TextStyle(
                        color: SearchTheme.midnightBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: SearchTheme.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Text(
                    'Catégorie',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: SearchTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(cat),
                        onSelected: (selected) {
                          setState(() => _selectedCategory = cat);
                          _performSearch();
                        },
                        backgroundColor: SearchTheme.cream,
                        selectedColor: SearchTheme.midnightBlue,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : SearchTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? SearchTheme.midnightBlue
                                : SearchTheme.textHint.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Price Range
                  Text(
                    'Prix (0 - 200 TND)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: SearchTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_minPrice.toStringAsFixed(0)} TND',
                          style: TextStyle(
                            fontSize: 13,
                            color: SearchTheme.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: SearchTheme.midnightBlue,
                            inactiveTrackColor: SearchTheme.textHint.withOpacity(0.3),
                            thumbColor: SearchTheme.midnightBlue,
                            overlayColor: SearchTheme.midnightBlue.withOpacity(0.2),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _minPrice,
                            min: 0,
                            max: 200,
                            divisions: 20,
                            label: _minPrice.toStringAsFixed(0),
                            onChanged: (value) {
                              setState(() => _minPrice = value);
                            },
                            onChangeEnd: (_) => _performSearch(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_maxPrice.toStringAsFixed(0)} TND',
                          style: TextStyle(
                            fontSize: 13,
                            color: SearchTheme.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: SearchTheme.midnightBlue,
                            inactiveTrackColor: SearchTheme.textHint.withOpacity(0.3),
                            thumbColor: SearchTheme.midnightBlue,
                            overlayColor: SearchTheme.midnightBlue.withOpacity(0.2),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _maxPrice,
                            min: 0,
                            max: 200,
                            divisions: 20,
                            label: _maxPrice.toStringAsFixed(0),
                            onChanged: (value) {
                              setState(() => _maxPrice = value);
                            },
                            onChangeEnd: (_) => _performSearch(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Date Range
                  Text(
                    'Période',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: SearchTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(true),
                          icon: Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: SearchTheme.midnightBlue,
                          ),
                          label: Text(
                            _startDate == null
                                ? 'Date début'
                                : DateFormat('dd/MM/yyy').format(_startDate!),
                            style: TextStyle(
                              color: _startDate == null
                                  ? SearchTheme.textSecondary
                                  : SearchTheme.midnightBlue,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: SearchTheme.textHint.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(false),
                          icon: Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: SearchTheme.midnightBlue,
                          ),
                          label: Text(
                            _endDate == null
                                ? 'Date fin'
                                : DateFormat('dd/MM/yyy').format(_endDate!),
                            style: TextStyle(
                              color: _endDate == null
                                  ? SearchTheme.textSecondary
                                  : SearchTheme.midnightBlue,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: SearchTheme.textHint.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_startDate != null || _endDate != null)
                        IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: SearchTheme.textHint,
                          ),
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                            _performSearch();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Favorites filter
                  Text(
                    'Favoris',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: SearchTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilterChip(
                    selected: _showOnlyFavorites,
                    label: const Text('Afficher uniquement les favoris'),
                    onSelected: (selected) {
                      setState(() => _showOnlyFavorites = selected);
                      _performSearch();
                    },
                    backgroundColor: SearchTheme.cream,
                    selectedColor: SearchTheme.midnightBlue,
                    labelStyle: TextStyle(
                      color: _showOnlyFavorites ? Colors.white : SearchTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    avatar: Icon(
                      _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: _showOnlyFavorites ? Colors.white : SearchTheme.error,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _showOnlyFavorites
                            ? SearchTheme.midnightBlue
                            : SearchTheme.textHint.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Reset button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedCategory = 'Tous';
                          _minPrice = 0;
                          _maxPrice = 200;
                          _startDate = null;
                          _endDate = null;
                          _showOnlyFavorites = false;
                          _searchResults = [];
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: SearchTheme.textHint.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Réinitialiser les filtres',
                        style: TextStyle(
                          color: SearchTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(SearchTheme.midnightBlue),
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: SearchTheme.midnightBlue.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: SearchTheme.midnightBlue.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Aucun résultat trouvé',
                              style: TextStyle(
                                fontSize: 16,
                                color: SearchTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez d\'ajuster vos filtres',
                              style: TextStyle(
                                fontSize: 14,
                                color: SearchTheme.textHint,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final event = _searchResults[index];
                          return _buildEventCard(event);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isFavorite = _userFavorites.contains(event.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SearchTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: SearchTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: SearchTheme.midnightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: SearchTheme.midnightBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: SearchTheme.midnightBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('dd MMM yyyy • HH:mm', 'fr').format(event.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: SearchTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: SearchTheme.midnightBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: SearchTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.isFree ? 'Gratuit' : '${event.displayPrice.toStringAsFixed(0)} TND',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: SearchTheme.midnightBlue,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: event.availablePlaces > 0
                          ? SearchTheme.success.withOpacity(0.1)
                          : SearchTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: event.availablePlaces > 0
                            ? SearchTheme.success
                            : SearchTheme.error,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          event.availablePlaces > 0
                              ? Icons.event_seat_rounded
                              : Icons.cancel_rounded,
                          size: 14,
                          color: event.availablePlaces > 0
                              ? SearchTheme.success
                              : SearchTheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.availablePlaces > 0
                              ? '${event.availablePlaces} places'
                              : 'Complet',
                          style: TextStyle(
                            fontSize: 12,
                            color: event.availablePlaces > 0
                                ? SearchTheme.success
                                : SearchTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isFavorite)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: SearchTheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Dans vos favoris',
                        style: TextStyle(
                          fontSize: 11,
                          color: SearchTheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}