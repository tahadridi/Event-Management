import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../home/event_detail_page.dart';

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
  List<EventModel> _searchResults = [];
  bool _isLoading = false;

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty && _selectedCategory == 'Tous') {
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

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      appBar: AppBar(
        title: const Text('Rechercher des événements'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: 'Tapez un mot-clé...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filter toggle
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showFilters = !_showFilters),
                    icon: const Icon(Icons.tune),
                    label: const Text('Filtres'),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  const Text(
                    'Catégorie',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(cat),
                        onSelected: (selected) {
                          setState(() => _selectedCategory = cat);
                          _performSearch();
                        },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Price Range
                  const Text(
                    'Prix (0 - 200 TND)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_minPrice.toStringAsFixed(0)} TND',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
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
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_maxPrice.toStringAsFixed(0)} TND',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
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
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date Range
                  const Text(
                    'Période',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(true),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_startDate == null
                              ? 'Date début'
                              : DateFormat('dd/MM/yyy').format(_startDate!)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(false),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_endDate == null
                              ? 'Date fin'
                              : DateFormat('dd/MM/yyy').format(_endDate!)),
                        ),
                      ),
                      if (_startDate != null || _endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
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
                  const SizedBox(height: 12),
                  
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
                          _searchResults = [];
                        });
                      },
                      child: const Text('Réinitialiser les filtres'),
                    ),
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun résultat trouvé',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('dd MMM yyyy • HH:mm', 'fr').format(event.date),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.price == 0 ? 'Gratuit' : '${event.price.toStringAsFixed(0)} TND',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: event.availablePlaces > 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: event.availablePlaces > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Text(
                      event.availablePlaces > 0
                          ? '${event.availablePlaces} places'
                          : 'Complet',
                      style: TextStyle(
                        fontSize: 12,
                        color: event.availablePlaces > 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
