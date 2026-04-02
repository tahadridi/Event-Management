import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../models/event_model.dart';
import '../../models/reservation_model.dart';
import '../reservation/reservation_details_page.dart';

// ─────────────────────────────────────────────────────────────
// DESIGN SYSTEM - Midnight Blue & White Theme
// ─────────────────────────────────────────────────────────────

class BookingTheme {
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
  
  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({Key? key}) : super(key: key);

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin {
  final ReservationService _reservationService = ReservationService();
  late TabController _tabController;

  // Filters
  String _filterStatus = 'Tous';
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isConfirmed(String status) =>
      status.toLowerCase() == 'confirmed' ||
      status.toLowerCase() == 'confirmée';

  bool _isCancelled(String status) =>
      status.toLowerCase() == 'cancelled' ||
      status.toLowerCase() == 'annulée' ||
      status.toLowerCase() == 'annulé';

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> bookings) {
    var filtered = bookings.where((b) {
      final reservation = b['reservation'] as ReservationModel;
      final event = b['event'] as EventModel;
      final status = reservation.status.toLowerCase();
      final isPast = event.date.isBefore(DateTime.now());

      switch (_filterStatus) {
        case 'Confirmée':
          return _isConfirmed(reservation.status) && !isPast;
        case 'Terminée':
          return _isConfirmed(reservation.status) && isPast;
        case 'Annulée':
          return _isCancelled(reservation.status);
        default:
          return true;
      }
    }).toList();

    filtered.sort((a, b) {
      final resA = a['reservation'] as ReservationModel;
      final resB = b['reservation'] as ReservationModel;
      switch (_sortBy) {
        case 'oldest':
          return resA.createdAt.compareTo(resB.createdAt);
        case 'price':
          return resB.totalPrice.compareTo(resA.totalPrice);
        default:
          return resB.createdAt.compareTo(resA.createdAt);
      }
    });

    return filtered;
  }

  Future<void> _cancelBooking(String reservationId, EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Annuler la réservation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: BookingTheme.midnightBlue,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir annuler votre réservation pour "${event.title}" ?',
          style: TextStyle(
            color: BookingTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Non',
              style: TextStyle(
                color: BookingTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BookingTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Oui, annuler',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _reservationService.cancelReservation(reservationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Réservation annulée avec succès'),
                ],
              ),
              backgroundColor: BookingTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: BookingTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BookingTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title
            _buildHeader(),
            
            // Tab Bar (moved below header)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: BookingTheme.midnightBlue,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: BookingTheme.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'À venir'),
                  Tab(text: 'Terminées'),
                  Tab(text: 'Historique'),
                ],
              ),
            ),
            
            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpcomingTab(),
                  _buildPastTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: BookingTheme.midnightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes réservations',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: BookingTheme.midnightBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérez vos événements réservés',
                  style: TextStyle(
                    fontSize: 13,
                    color: BookingTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reservationService.getUserBookingHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BookingTheme.midnightBlue),
            ),
          );
        }

        final all = snapshot.data ?? [];
        final upcoming = all.where((b) {
          final res = b['reservation'] as ReservationModel;
          final event = b['event'] as EventModel;
          return _isConfirmed(res.status) &&
              event.date.isAfter(DateTime.now());
        }).toList();

        if (upcoming.isEmpty) {
          return _buildEmpty(
              Icons.event_available, 'Aucune réservation à venir');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcoming.length,
          itemBuilder: (context, index) {
            final res = upcoming[index]['reservation'] as ReservationModel;
            final event = upcoming[index]['event'] as EventModel;
            return _buildCard(res, event, canCancel: true);
          },
        );
      },
    );
  }

  Widget _buildPastTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reservationService.getUserBookingHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BookingTheme.midnightBlue),
            ),
          );
        }

        final all = snapshot.data ?? [];
        final past = all.where((b) {
          final res = b['reservation'] as ReservationModel;
          final event = b['event'] as EventModel;
          return _isConfirmed(res.status) &&
              event.date.isBefore(DateTime.now());
        }).toList();

        if (past.isEmpty) {
          return _buildEmpty(Icons.history, 'Aucun événement terminé');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: past.length,
          itemBuilder: (context, index) {
            final res = past[index]['reservation'] as ReservationModel;
            final event = past[index]['event'] as EventModel;
            return _buildCard(res, event, canCancel: false, isPast: true);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reservationService.getUserBookingHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BookingTheme.midnightBlue),
            ),
          );
        }

        final all = snapshot.data ?? [];
        final filtered = _applyFilters(all);

        return Column(
          children: [
            // Filter bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Tous', 'Confirmée', 'Terminée', 'Annulée']
                            .map((s) {
                          final isSelected = _filterStatus == s;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(s),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _filterStatus = s),
                              backgroundColor: BookingTheme.cream,
                              selectedColor: BookingTheme.midnightBlue,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : BookingTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? BookingTheme.midnightBlue
                                      : BookingTheme.textHint.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.sort_rounded,
                        color: BookingTheme.midnightBlue,
                      ),
                      tooltip: 'Trier',
                      onSelected: (val) => setState(() => _sortBy = val),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'recent',
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 18),
                              SizedBox(width: 12),
                              Text('Plus récent'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'oldest',
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 18),
                              SizedBox(width: 12),
                              Text('Plus ancien'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'price',
                          child: Row(
                            children: [
                              Icon(Icons.attach_money, size: 18),
                              SizedBox(width: 12),
                              Text('Prix décroissant'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Counter
            if (all.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: BookingTheme.midnightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filtered.length} réservation(s)',
                      style: TextStyle(
                        color: BookingTheme.midnightBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty(Icons.search_off, 'Aucun résultat')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final res = filtered[index]['reservation']
                            as ReservationModel;
                        final event = filtered[index]['event'] as EventModel;
                        final canCancel = _isConfirmed(res.status) &&
                            event.date.isAfter(DateTime.now());
                        return _buildCard(res, event, canCancel: canCancel);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(
    ReservationModel reservation,
    EventModel event, {
    required bool canCancel,
    bool isPast = false,
  }) {
    final isConfirmed = _isConfirmed(reservation.status);
    final isCancelled = _isCancelled(reservation.status);

    Color statusColor = isConfirmed
        ? (isPast ? BookingTheme.midnightBlueLight : BookingTheme.success)
        : (isCancelled ? BookingTheme.error : BookingTheme.warning);

    String statusLabel = isConfirmed
        ? (isPast ? 'Terminée' : 'Confirmée')
        : (isCancelled ? 'Annulée' : reservation.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReservationDetailsPage(
              reservation: reservation,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BookingTheme.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: BookingTheme.textPrimary,
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: BookingTheme.textSecondary.withOpacity(0.5),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Event details
              _infoRow(
                Icons.calendar_today_rounded,
                DateFormat('dd MMM yyyy • HH:mm', 'fr').format(event.date),
                BookingTheme.midnightBlue,
              ),
              const SizedBox(height: 10),
              _infoRow(
                Icons.location_on_rounded,
                event.location,
                BookingTheme.textSecondary,
              ),
              const SizedBox(height: 10),
              _infoRow(
                Icons.confirmation_number_rounded,
                '${reservation.numberOfSeats} place(s)',
                BookingTheme.textSecondary,
              ),
              const SizedBox(height: 10),
              _infoRow(
                Icons.payments_rounded,
                reservation.totalPrice == 0
                    ? 'Gratuit'
                    : '${reservation.totalPrice.toStringAsFixed(0)} TND',
                BookingTheme.midnightBlue,
                isBold: true,
              ),
              const SizedBox(height: 10),
              _infoRow(
                Icons.access_time_rounded,
                'Réservé le ${DateFormat('dd MMM yyyy', 'fr').format(reservation.createdAt)}',
                BookingTheme.textHint,
              ),

              if (canCancel) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelBooking(reservation.id, event),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Annuler la réservation'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BookingTheme.error,
                      side: BorderSide(color: BookingTheme.error.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BookingTheme.midnightBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: BookingTheme.midnightBlue.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: BookingTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}