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

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final ReservationService _reservationService = ReservationService();
  final AuthService _authService = AuthService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isOrganizer = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<_CalendarEvent> _selectedEvents = [];

  Map<DateTime, List<_CalendarEvent>> _eventsByDay = {};

  List<_CalendarEvent> _allMonthEvents = [];

  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color accent = Color(0xFFE67E22);
  static const Color success = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
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
          _updateMonthEvents();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateMonthEvents() {
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    
    _allMonthEvents = [];
    for (var i = 0; i <= endOfMonth.difference(startOfMonth).inDays; i++) {
      final day = startOfMonth.add(Duration(days: i));
      final events = _getEventsForDay(day);
      _allMonthEvents.addAll(events);
    }
  }

  Future<void> _loadUserData() async {
    final bookings = await _reservationService.getUserBookingHistory().first;
    final map = <DateTime, List<_CalendarEvent>>{};

    for (final b in bookings) {
      final reservation = b['reservation'] as ReservationModel;
      final event = b['event'] as EventModel;

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

  Future<void> _loadOrganizerData() async {
    final map = <DateTime, List<_CalendarEvent>>{};

    final myEvents = await _eventService.getOrganizerEvents().first;
    for (final event in myEvents) {
      final day = _normalizeDate(event.date);
      map.putIfAbsent(day, () => []);
      map[day]!.add(_CalendarEvent(
        event: event,
        type: CalendarEventType.myEvent,
      ));
    }

    final bookings = await _reservationService.getUserBookingHistory().first;
    for (final b in bookings) {
      final reservation = b['reservation'] as ReservationModel;
      final event = b['event'] as EventModel;

      final status = reservation.status.toLowerCase();
      if (status == 'cancelled' || status == 'annulée' || status == 'annulé') {
        continue;
      }

      final day = _normalizeDate(event.date);
      map.putIfAbsent(day, () => []);

      final alreadyAdded = map[day]!.any((e) => e.event.id == event.id);
      if (!alreadyAdded) {
        map[day]!.add(_CalendarEvent(
          event: event,
          type: CalendarEventType.reservation,
        ));
      }
    }

    setState(() => _eventsByDay = map);
  }

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

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _updateMonthEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;
    
    return Scaffold(
      backgroundColor: cream,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(midnightBlue),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(isSmallScreen),
                  
                  // Legend (for organizers)
                  if (_isOrganizer) _buildLegend(isSmallScreen),
                  
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Calendar with dynamic height
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
                            child: _buildCalendar(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          const Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                            indent: 20,
                            endIndent: 20,
                          ),
                          
                          // Month header
                          _buildMonthHeader(isSmallScreen),
                          
                          // All events for the month
                          if (_allMonthEvents.isEmpty)
                            _buildEmptyMonthState(isSmallScreen)
                          else
                            _buildAllMonthEventsList(isSmallScreen),
                          
                          const SizedBox(height: 100),
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
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 20,
        MediaQuery.of(context).padding.top + 8,
        isSmallScreen ? 16 : 20,
        12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
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
                  'Calendrier',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: midnightBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _isOrganizer 
                      ? 'Mes événements et réservations'
                      : 'Mes réservations',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    color: textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: midnightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                setState(() => _isLoading = true);
                _loadData();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _buildLegendItem(
              color: success,
              label: 'Mes événements',
              icon: Icons.event_available_rounded,
              isSmallScreen: isSmallScreen,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: _buildLegendItem(
              color: accent,
              label: 'Réservations',
              icon: Icons.bookmark_rounded,
              isSmallScreen: isSmallScreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 24 : 28,
          height: isSmallScreen ? 24 : 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: isSmallScreen ? 14 : 16, color: color),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 480;
        final isMediumScreen = screenWidth >= 480 && screenWidth < 768;
        
        // Calculate responsive sizes
        final double calendarHeight;
        final double cellMargin;
        final double markerSize;
        final double dayTextSize;
        final double weekdayTextSize;
        
        if (isSmallScreen) {
          calendarHeight = 340.0;
          cellMargin = 2.0;
          markerSize = 4.0;
          dayTextSize = 12.0;
          weekdayTextSize = 11.0;
        } else if (isMediumScreen) {
          calendarHeight = 380.0;
          cellMargin = 4.0;
          markerSize = 5.0;
          dayTextSize = 14.0;
          weekdayTextSize = 12.0;
        } else {
          calendarHeight = 400.0;
          cellMargin = 6.0;
          markerSize = 6.0;
          dayTextSize = 15.0;
          weekdayTextSize = 13.0;
        }
        
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: calendarHeight,
            child: TableCalendar<_CalendarEvent>(
              firstDay: DateTime(2024),
              lastDay: DateTime(2027),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: _onDaySelected,
              onPageChanged: _onPageChanged,
              locale: 'fr_FR',
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: midnightBlue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: midnightBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(
                  fontSize: dayTextSize,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                weekendTextStyle: TextStyle(
                  fontSize: dayTextSize,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                outsideTextStyle: TextStyle(
                  fontSize: dayTextSize - 1,
                  color: textSecondary.withOpacity(0.5),
                ),
                cellMargin: EdgeInsets.all(cellMargin),
                markerDecoration: const BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 2,
                markerSize: markerSize,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: weekdayTextSize,
                  fontWeight: FontWeight.w600,
                  color: midnightBlue,
                ),
                weekendStyle: TextStyle(
                  fontSize: weekdayTextSize,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: (isSmallScreen ? 14 : 16),
                  fontWeight: FontWeight.w700,
                  color: midnightBlue,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded, 
                  color: midnightBlue, 
                  size: (isSmallScreen ? 20 : 24),
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded, 
                  color: midnightBlue, 
                  size: (isSmallScreen ? 20 : 24),
                ),
                headerPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  
                  final eventTypes = <Color>{};
                  for (final event in events) {
                    eventTypes.add(event.type == CalendarEventType.myEvent 
                        ? success 
                        : accent);
                  }
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: eventTypes.take(2).map((color) {
                      return Container(
                        width: markerSize,
                        height: markerSize,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
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
          ),
        );
      },
    );
  }

  Widget _buildMonthHeader(bool isSmallScreen) {
    final monthFormat = DateFormat(isSmallScreen ? 'MMM yyyy' : 'MMMM yyyy', 'fr');
    
    return Container(
      padding: EdgeInsets.fromLTRB(isSmallScreen ? 16 : 20, 16, isSmallScreen ? 16 : 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: midnightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: isSmallScreen ? 18 : 20,
              color: midnightBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              monthFormat.format(_focusedDay),
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: midnightBlue,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: midnightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_allMonthEvents.length}',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: midnightBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMonthState(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 40 : 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isSmallScreen ? 70 : 90,
              height: isSmallScreen ? 70 : 90,
              decoration: BoxDecoration(
                color: midnightBlue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: isSmallScreen ? 35 : 45,
                color: midnightBlue.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun événement ce mois-ci',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les événements apparaîtront ici',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllMonthEventsList(bool isSmallScreen) {
    final Map<DateTime, List<_CalendarEvent>> groupedEvents = {};
    for (final event in _allMonthEvents) {
      final date = _normalizeDate(event.event.date);
      groupedEvents.putIfAbsent(date, () => []);
      groupedEvents[date]!.add(event);
    }
    
    final sortedDates = groupedEvents.keys.toList()..sort();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final events = groupedEvents[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header for each day
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: midnightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: isSmallScreen ? 12 : 14,
                      color: midnightBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(isSmallScreen ? 'EEEE d MMM' : 'EEEE d MMMM', 'fr').format(date),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: midnightBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: midnightBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${events.length}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11,
                          fontWeight: FontWeight.bold,
                          color: midnightBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Events for that day
            ...events.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEventTile(event, isSmallScreen),
            )),
          ],
        );
      },
    );
  }

  Widget _buildEventTile(_CalendarEvent calEvent, bool isSmallScreen) {
    final event = calEvent.event;
    final isMyEvent = calEvent.type == CalendarEventType.myEvent;
    final isPast = event.date.isBefore(DateTime.now());

    final Color accentColor = isMyEvent ? success : midnightBlue;
    final Color badgeColor = isMyEvent ? success : accent;
    final String badgeText = isMyEvent ? 'Mon événement' : 'Réservé';
    final IconData badgeIcon = isMyEvent ? Icons.star_rounded : Icons.bookmark_rounded;

    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: event),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
            border: Border.all(
              color: accentColor.withOpacity(0.15),
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
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
            child: Row(
              children: [
                // Time Container
                Container(
                  width: isSmallScreen ? 60 : 70,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(0.1),
                        accentColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('HH:mm').format(event.date),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM', 'fr').format(event.date),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 9 : 10,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: isSmallScreen ? 12 : 14),

                // Event Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 13 : 14,
                          color: isPast ? textSecondary : textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: isSmallScreen ? 11 : 12,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: isSmallScreen ? 8 : 10),

                // Badge and Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: isSmallScreen ? 9 : 10, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 8 : 9,
                              color: badgeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: midnightBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        event.isFree
                            ? 'Gratuit'
                          : '${event.displayPrice.toStringAsFixed(0)} TND',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11,
                          fontWeight: FontWeight.bold,
                          color: midnightBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary.withOpacity(0.5),
                  size: isSmallScreen ? 18 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum CalendarEventType { reservation, myEvent }

class _CalendarEvent {
  final EventModel event;
  final CalendarEventType type;

  _CalendarEvent({required this.event, required this.type});
}