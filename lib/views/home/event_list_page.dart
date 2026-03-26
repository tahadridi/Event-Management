import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/user_service.dart';
import '../../widgets/event_card.dart';
import 'event_detail_page.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  Set<String> _userFavorites = {};
  String _selectedCategory = 'Tous';
  double _minPrice = 0;
  double _maxPrice = 200;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showOnlyFavorites = false;
  bool _showFilters = false;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Tous', 'icon': Icons.apps},
    {'label': 'Concert', 'icon': Icons.music_note},
    {'label': 'Sport', 'icon': Icons.sports_soccer},
    {'label': 'Art', 'icon': Icons.palette},
    {'label': 'Conférence', 'icon': Icons.mic},
    {'label': 'Atelier', 'icon': Icons.build},
    {'label': 'Séminaire', 'icon': Icons.school},
    {'label': 'Autre', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    });
  }

  bool get _hasActiveFilters =>
      _selectedCategory != 'Tous' ||
      _minPrice > 0 ||
      _maxPrice < 200 ||
      _startDate != null ||
      _endDate != null ||
      _showOnlyFavorites;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Découvrir',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Trouvez votre prochain événement',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Search bar pinned
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un événement...',
                    hintStyle: const TextStyle(
                        color: Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.deepPurple, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Colors.grey),
                            onPressed: () => setState(
                                () => _searchController.clear()),
                          ),
                        // Filter toggle button
                        Stack(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.tune,
                                size: 20,
                                color: _showFilters || _hasActiveFilters
                                    ? Colors.deepPurple
                                    : Colors.grey,
                              ),
                              onPressed: () => setState(
                                  () => _showFilters = !_showFilters),
                            ),
                            if (_hasActiveFilters)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.deepPurple,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // ── Filters panel ─────────────────────────────────────────
          if (_showFilters)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filtres',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Réinitialiser',
                                style:
                                    TextStyle(color: Colors.deepPurple)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Favorites toggle
                    Row(
                      children: [
                        const Icon(Icons.favorite,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Favoris uniquement',
                            style: TextStyle(fontSize: 14)),
                        const Spacer(),
                        Switch(
                          value: _showOnlyFavorites,
                          onChanged: (v) =>
                              setState(() => _showOnlyFavorites = v),
                          activeColor: Colors.deepPurple,
                        ),
                      ],
                    ),

                    const Divider(),

                    // Price range
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Prix',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(
                          _minPrice == 0 && _maxPrice == 200
                              ? 'Tous les prix'
                              : '${_minPrice.toInt()} – ${_maxPrice.toInt()} TND',
                          style: const TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_minPrice, _maxPrice),
                      min: 0,
                      max: 200,
                      divisions: 20,
                      activeColor: Colors.deepPurple,
                      labels: RangeLabels(
                        '${_minPrice.toInt()} TND',
                        '${_maxPrice.toInt()} TND',
                      ),
                      onChanged: (v) => setState(() {
                        _minPrice = v.start;
                        _maxPrice = v.end;
                      }),
                    ),

                    const Divider(),

                    // Date range
                    const Text('Période',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _dateButton(
                            label: _startDate == null
                                ? 'Date début'
                                : DateFormat('dd/MM/yy')
                                    .format(_startDate!),
                            onTap: () => _selectDate(true),
                            active: _startDate != null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dateButton(
                            label: _endDate == null
                                ? 'Date fin'
                                : DateFormat('dd/MM/yy')
                                    .format(_endDate!),
                            onTap: () => _selectDate(false),
                            active: _endDate != null,
                          ),
                        ),
                        if (_startDate != null || _endDate != null)
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Colors.grey),
                            onPressed: () => setState(() {
                              _startDate = null;
                              _endDate = null;
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── Category chips ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat['label'];
                  return GestureDetector(
                    onTap: () => setState(
                        () => _selectedCategory = cat['label']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.deepPurple
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: Colors.deepPurple
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(cat['icon'] as IconData,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(cat['label'],
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Events list ────────────────────────────────────────────
          StreamBuilder<List<EventModel>>(
            stream: _eventService.getEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Aucun événement pour le moment',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              final filtered = _applyFilters(snapshot.data!);

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Aucun résultat',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _resetFilters,
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
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 4),
                        child: Text(
                          '${filtered.length} événement${filtered.length > 1 ? 's' : ''} trouvé${filtered.length > 1 ? 's' : ''}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500),
                        ),
                      );
                    }
                    final event = filtered[index - 1];
                    return EventCard(
                      event: event,
                      isFavorite: _userFavorites.contains(event.id),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailPage(event: event),
                        ),
                      ),
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

  Widget _dateButton(
      {required String label,
      required VoidCallback onTap,
      required bool active}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? Colors.deepPurple.withOpacity(0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? Colors.deepPurple : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today,
                size: 13,
                color: active ? Colors.deepPurple : Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color:
                        active ? Colors.deepPurple : Colors.grey.shade600,
                    fontWeight: active
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}