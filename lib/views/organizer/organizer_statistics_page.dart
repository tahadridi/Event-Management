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
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'fr_TN');
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text(
          'Statistiques',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1A2E),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        toolbarHeight: 100,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8F9FF),
                Color(0xFFF0F2FF),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _eventService.getOrganizerEvents(),
        builder: (context, eventSnapshot) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _reservationService.getOrganizerReservations(),
            builder: (context, reservationSnapshot) {
              if (eventSnapshot.connectionState == ConnectionState.waiting ||
                  reservationSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(_fadeAnimation),
                              child: _buildHeroStats(
                                events.length,
                                totalReservations,
                                totalRevenue,
                                occupancyRate,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (events.isNotEmpty) ...[
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildSectionHeader(
                                'Performance des Événements',
                                'Top 3 des événements les plus performants',
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildEventsPerformance(events, reservations),
                            ),
                            const SizedBox(height: 32),
                          ],
                          if (reservations.isNotEmpty) ...[
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildSectionHeader(
                                'Activité Récente',
                                'Dernières réservations',
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildRecentReservations(reservations),
                            ),
                            const SizedBox(height: 32),
                          ],
                          if (events.isNotEmpty) ...[
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildSectionHeader(
                                'Distribution par Catégorie',
                                'Événements par catégorie',
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildCategoryStats(events),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeroStats(
    int totalEvents,
    int totalReservations,
    double totalRevenue,
    String occupancyRate,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
            const Color(0xFFA855F7),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Events',
                totalEvents.toString(),
                Icons.calendar_today,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildStatItem(
                'Bookings',
                totalReservations.toString(),
                Icons.bookmark_border,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Revenue',
                currencyFormat.format(totalRevenue).replaceAll('DT', ''),
                Icons.trending_up,
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildStatItem(
                'Occupancy',
                '$occupancyRate%',
                Icons.pie_chart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
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
                      gradient: LinearGradient(
                        colors: [
                          _getOccupancyColor(occupancy).withOpacity(0.1),
                          _getOccupancyColor(occupancy).withOpacity(0.05),
                        ],
                      ),
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
                    Icons.receipt,
                    '${perf['bookings']} bookings',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.event_seat,
                    '${perf['seatsBooked']}/${event.totalPlaces} seats',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: occupancy / 100,
                  minHeight: 6,
                  backgroundColor: Colors.grey[100],
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
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOccupancyColor(double occupancy) {
    if (occupancy > 80) return const Color(0xFF10B981);
    if (occupancy > 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.1),
                      const Color(0xFFA855F7).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reservation.numberOfSeats} ${reservation.numberOfSeats > 1 ? 'seats' : 'seat'} · ${event.title}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(reservation.totalPrice).replaceAll('DT', ''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd').format(reservation.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
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
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getCategoryColor(index),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${entry.value} ${entry.value > 1 ? 'events' : 'event'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
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
                  backgroundColor: Colors.grey[100],
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
                  color: Colors.grey[500],
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
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFA855F7),
      Color(0xFFEC4899),
      Color(0xFFF43F5E),
    ];
    return colors[index % colors.length];
  }
}