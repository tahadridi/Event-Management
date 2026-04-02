import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../models/event_model.dart';
import '../../models/reservation_model.dart';
import '../../services/event_service.dart';
import '../../services/reservation_service.dart';

class OrganizerStatisticsPage extends StatefulWidget {
  const OrganizerStatisticsPage({Key? key}) : super(key: key);

  @override
  State<OrganizerStatisticsPage> createState() =>
      _OrganizerStatisticsPageState();
}

class _OrganizerStatisticsPageState extends State<OrganizerStatisticsPage>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final ReservationService _reservationService = ReservationService();
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'fr_TN',
    symbol: 'TND',
    decimalDigits: 0,
  );
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF1A3A7C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color creamDark = Color(0xFFF5EDE2);
  static const Color accent = Color(0xFFE67E22);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardWhite = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: StreamBuilder<List<EventModel>>(
          stream: _eventService.getOrganizerEvents(),
          builder: (context, eventSnapshot) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _reservationService.getOrganizerReservations(),
              builder: (context, reservationSnapshot) {
                if (eventSnapshot.connectionState == ConnectionState.waiting ||
                    reservationSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(midnightBlue),
                    ),
                  );
                }

                final events = eventSnapshot.data ?? [];
                final reservations = reservationSnapshot.data ?? [];

                int totalReservations = 0;
                int totalSeatsBooked = 0;
                double totalRevenue = 0;
                int totalCapacity = 0;

                for (var res in reservations) {
                  final reservation = res['reservation'] as ReservationModel;
                  if (reservation.status.toLowerCase() == 'confirmed' ||
                      reservation.status.toLowerCase() == 'confirmée') {
                    totalReservations++;
                    totalSeatsBooked += reservation.numberOfSeats;
                    totalRevenue += reservation.totalPrice;
                  }
                }

                for (var event in events) {
                  totalCapacity += event.totalPlaces;
                }

                final occupancyRate = totalCapacity > 0
                    ? (totalSeatsBooked / totalCapacity * 100).toStringAsFixed(1)
                    : '0.0';

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),
                      
                      const SizedBox(height: 8),

                      // Stats Cards
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _buildStatsGrid(
                            events.length,
                            totalReservations,
                            totalRevenue,
                            occupancyRate,
                          ),
                        ),
                      ),

                      // Events Performance
                      if (events.isNotEmpty) ...[
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            child: _buildSectionHeader(
                              'Performance des Événements',
                              'Top 3 des événements les plus performants',
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildEventsPerformance(events, reservations),
                          ),
                        ),
                      ],

                      // Recent Activity
                      if (reservations.isNotEmpty) ...[
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                            child: _buildSectionHeader(
                              'Activité Récente',
                              'Dernières réservations',
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildRecentReservations(reservations),
                          ),
                        ),
                      ],

                      // Category Distribution
                      if (events.isNotEmpty) ...[
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                            child: _buildSectionHeader(
                              'Distribution par Catégorie',
                              'Événements par catégorie',
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            child: _buildCategoryStats(events),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cream, creamDark],
        ),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: midnightBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Analysez vos performances',
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildStatsGrid(
    int totalEvents,
    int totalReservations,
    double totalRevenue,
    String occupancyRate,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          title: 'Événements',
          value: totalEvents.toString(),
          icon: Icons.calendar_today_rounded,
          color: midnightBlue,
          gradient: [midnightBlue, midnightBlueLight],
        ),
        _buildStatCard(
          title: 'Réservations',
          value: totalReservations.toString(),
          icon: Icons.bookmark_rounded,
          color: success,
          gradient: [success, success.withOpacity(0.8)],
        ),
        _buildStatCard(
          title: 'Revenus',
          value: '${totalRevenue.toStringAsFixed(0)} TND',
          icon: Icons.trending_up_rounded,
          color: accent,
          gradient: [accent, accent.withOpacity(0.8)],
        ),
        _buildStatCard(
          title: "Taux d'occupation",
          value: '$occupancyRate%',
          icon: Icons.pie_chart_rounded,
          color: warning,
          gradient: [warning, warning.withOpacity(0.8)],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: midnightBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: midnightBlue,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsPerformance(
    List<EventModel> events,
    List<Map<String, dynamic>> reservations,
  ) {
    final eventBookings = <String, List<ReservationModel>>{};
    for (var res in reservations) {
      final reservation = res['reservation'] as ReservationModel;
      if (reservation.status.toLowerCase() == 'confirmed' ||
          reservation.status.toLowerCase() == 'confirmée') {
        eventBookings.putIfAbsent(reservation.eventId, () => []);
        eventBookings[reservation.eventId]!.add(reservation);
      }
    }

    final eventPerformance = events.map((event) {
      final bookings = eventBookings[event.id] ?? [];
      final seatsBooked = bookings.fold<int>(0, (sum, res) => sum + res.numberOfSeats);
      final occupancy = event.totalPlaces > 0
          ? ((seatsBooked / event.totalPlaces) * 100).toStringAsFixed(1)
          : '0.0';
      return {
        'event': event,
        'bookings': bookings.length,
        'seatsBooked': seatsBooked,
        'occupancy': occupancy,
      };
    }).toList();

    eventPerformance.sort((a, b) =>
        double.parse(b['occupancy'].toString())
            .compareTo(double.parse(a['occupancy'].toString())));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: eventPerformance.take(3).length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final perf = eventPerformance[index];
        final event = perf['event'] as EventModel;
        final occupancy = double.parse(perf['occupancy'].toString());

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(20),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getOccupancyColor(occupancy).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${perf['occupancy']}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _getOccupancyColor(occupancy),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.receipt_rounded,
                    '${perf['bookings']} réservation${(perf['bookings'] as int? ?? 0) > 1 ? 's' : ''}',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.event_seat_rounded,
                    '${perf['seatsBooked']}/${event.totalPlaces} places',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: occupancy / 100,
                  minHeight: 6,
                  backgroundColor: cream,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getOccupancyColor(occupancy),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOccupancyColor(double? occupancy) {
    if ((occupancy ?? 0) > 80) return success;
    if ((occupancy ?? 0) > 50) return warning;
    return error;
  }

  Widget _buildRecentReservations(List<Map<String, dynamic>> reservations) {
    final recent = reservations
        .where((res) {
          final reservation = res['reservation'] as ReservationModel;
          return reservation.status.toLowerCase() == 'confirmed' ||
              reservation.status.toLowerCase() == 'confirmée';
        })
        .take(4)
        .toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final res = recent[index];
        final reservation = res['reservation'] as ReservationModel;
        final event = res['event'] as EventModel;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(20),
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
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: midnightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: midnightBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reservation.numberOfSeats} ${reservation.numberOfSeats > 1 ? 'places' : 'place'} · ${event.title}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${reservation.totalPrice.toStringAsFixed(0)} TND',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: midnightBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM', 'fr').format(reservation.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryStats(List<EventModel> events) {
    final categoryMap = <String, int>{};
    for (var event in events) {
      categoryMap.update(
        event.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedCategories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = sortedCategories[index];
        final percentage = (entry.value / events.length) * 100;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(20),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getCategoryColor(index),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${entry.value} ${entry.value > 1 ? 'événements' : 'événement'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 6,
                  backgroundColor: cream,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCategoryColor(index),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getCategoryColor(int index) {
    const colors = [
      midnightBlue,
      success,
      accent,
      warning,
      Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }
}