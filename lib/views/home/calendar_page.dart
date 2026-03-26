import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/reservation_model.dart';
import '../../services/event_service.dart';
import '../../services/reservation_service.dart';
import '../../services/auth_service.dart';
import 'event_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final EventService _eventService = EventService();
  final ReservationService _reservationService = ReservationService();
  final AuthService _authService = AuthService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isOrganizer = false;
  bool _isLoading = true;

  // Map date → liste d'events pour ce jour
  Map<DateTime, List<_CalendarEvent>> _eventsByDay = {};
  List<_CalendarEvent> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final role = await _authService.getUserRole(user.uid);
    final isOrganizer = role == 'organizer';

    if (isOrganizer) {
      await _loadOrganizerData();
    } else {
      await _loadUserData();
    }

    if (mounted) {
      setState(() {
        _isOrganizer = isOrganizer;
        _isLoading = false;
        _selectedEvents = _getEventsForDay(_selectedDay!);
      });
    }
  }

  // Charge les réservations de l'utilisateur
  Future<void> _loadUserData() async {
    final bookings =
        await _reservationService.getUserBookingHistory().first;

    final map = <DateTime, List<_CalendarEvent>>{};

    for (final b in bookings) {
      final reservation = b['reservation'] as ReservationModel;
      final event = b['event'] as EventModel;

      // Ignore les annulées
      final status = reservation.status.toLowerCase();
      if (status == 'cancelled' || status == 'annulée' || status == 'annulé') {
        continue;
      }

      final day = _normalizeDate(event.date);
      map.putIfAbsent(day, () => []);
      map[day]!.add(_CalendarEvent(
        event: event,
        type: CalendarEventType.reservation,
      ));
    }

    setState(() => _eventsByDay = map);
  }

  // Charge les événements de l'organisateur + ses réservations
  Future<void> _loadOrganizerData() async {
    final map = <DateTime, List<_CalendarEvent>>{};

    // Ses événements créés
    final myEvents = await _eventService.getOrganizerEvents().first;
    for (final event in myEvents) {
      final day = _normalizeDate(event.date);
      map.putIfAbsent(day, () => []);
      map[day]!.add(_CalendarEvent(
        event: event,
        type: CalendarEventType.myEvent,
      ));
    }

    // Ses réservations en tant qu'utilisateur
    final bookings =
        await _reservationService.getUserBookingHistory().first;
    for (final b in bookings) {
      final reservation = b['reservation'] as ReservationModel;
      final event = b['event'] as EventModel;

      final status = reservation.status.toLowerCase();
      if (status == 'cancelled' || status == 'annulée' || status == 'annulé') {
        continue;
      }

      final day = _normalizeDate(event.date);
      map.putIfAbsent(day, () => []);

      // Évite les doublons si l'organisateur a réservé son propre event
      final alreadyAdded = map[day]!
          .any((e) => e.event.id == event.id);
      if (!alreadyAdded) {
        map[day]!.add(_CalendarEvent(
          event: event,
          type: CalendarEventType.reservation,
        ));
      }
    }

    setState(() => _eventsByDay = map);
  }

  // Normalise une date (sans heure) pour la clé du map
  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<_CalendarEvent> _getEventsForDay(DateTime day) {
    return _eventsByDay[_normalizeDate(day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _getEventsForDay(selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Légende
                _buildLegend(),

                // Calendrier
                TableCalendar<_CalendarEvent>(
                  firstDay: DateTime(2024),
                  lastDay: DateTime(2027),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  onDaySelected: _onDaySelected,
                  onPageChanged: (focusedDay) =>
                      _focusedDay = focusedDay,
                  locale: 'fr_FR',
                  calendarStyle: CalendarStyle(
                    // Jour sélectionné
                    selectedDecoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    // Aujourd'hui
                    todayDecoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    // Marqueur d'événement
                    markerDecoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    markerSize: 6,
                    markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    // Marqueurs colorés selon le type
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return const SizedBox.shrink();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.take(3).map((e) {
                          final color =
                              e.type == CalendarEventType.myEvent
                                  ? Colors.green
                                  : Colors.orange;
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 1),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                // Header liste du jour sélectionné
                if (_selectedDay != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE dd MMMM yyyy', 'fr')
                              .format(_selectedDay!),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_selectedEvents.length} événement(s)',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                // Liste des événements du jour
                Expanded(
                  child: _selectedEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy,
                                  size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text(
                                'Aucun événement ce jour',
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _selectedEvents.length,
                          itemBuilder: (context, index) =>
                              _buildEventTile(
                                  _selectedEvents[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegend() {
    if (!_isOrganizer) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          _legendDot(Colors.green),
          const SizedBox(width: 6),
          const Text('Mes événements',
              style: TextStyle(fontSize: 12)),
          const SizedBox(width: 16),
          _legendDot(Colors.orange),
          const SizedBox(width: 6),
          const Text('Mes réservations',
              style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration:
            BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _buildEventTile(_CalendarEvent calEvent) {
    final event = calEvent.event;
    final isMyEvent = calEvent.type == CalendarEventType.myEvent;
    final isPast = event.date.isBefore(DateTime.now());

    final Color accentColor =
        isMyEvent ? Colors.green : Colors.deepPurple;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EventDetailPage(event: event)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Heure
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(event.date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isPast
                            ? Colors.grey
                            : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 12,
                            color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badge type + prix
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isMyEvent ? 'Mon event' : 'Réservé',
                      style: TextStyle(
                        fontSize: 10,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.price == 0
                        ? 'Gratuit'
                        : '${event.price.toStringAsFixed(0)} TND',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// Modèles internes
enum CalendarEventType { reservation, myEvent }

class _CalendarEvent {
  final EventModel event;
  final CalendarEventType type;

  _CalendarEvent({required this.event, required this.type});
}