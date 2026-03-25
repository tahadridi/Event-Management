import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../models/event_model.dart';
import '../../models/reservation_model.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({Key? key}) : super(key: key);

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin {
  final ReservationService _reservationService = ReservationService();
  late TabController _tabController;

  // Filtres pour l'historique
  String _filterStatus = 'Tous'; // 'Tous', 'Confirmée', 'Annulée', 'Terminée'
  String _sortBy = 'recent'; // 'recent', 'oldest', 'price'

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

  // Filtre + tri appliqués côté Dart
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

    // Tri
    filtered.sort((a, b) {
      final resA = a['reservation'] as ReservationModel;
      final resB = b['reservation'] as ReservationModel;
      switch (_sortBy) {
        case 'oldest':
          return resA.createdAt.compareTo(resB.createdAt);
        case 'price':
          return resB.totalPrice.compareTo(resA.totalPrice);
        default: // recent
          return resB.createdAt.compareTo(resA.createdAt);
      }
    });

    return filtered;
  }

  Future<void> _cancelBooking(
      String reservationId, EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Text(
            'Êtes-vous sûr de vouloir annuler votre réservation pour "${event.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _reservationService.cancelReservation(reservationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Réservation annulée')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'Terminées'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildPastTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // Onglet 1 — À venir (confirmées + date future)
  Widget _buildUpcomingTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reservationService.getUserBookingHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

  // Onglet 2 — Terminées (confirmées + date passée)
  Widget _buildPastTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reservationService.getUserBookingHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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

  // Onglet 3 — Historique complet avec filtres
  Widget _buildHistoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reservationService.getUserBookingHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data ?? [];
        final filtered = _applyFilters(all);

        return Column(
          children: [
            // Barre de filtres
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  // Filtre statut
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Tous', 'Confirmée', 'Terminée', 'Annulée']
                            .map((s) {
                          final isSelected = _filterStatus == s;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(s),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _filterStatus = s),
                              selectedColor: Colors.deepPurple,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // Tri
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort, color: Colors.deepPurple),
                    tooltip: 'Trier',
                    onSelected: (val) => setState(() => _sortBy = val),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'recent', child: Text('Plus récent')),
                      const PopupMenuItem(
                          value: 'oldest', child: Text('Plus ancien')),
                      const PopupMenuItem(
                          value: 'price', child: Text('Prix décroissant')),
                    ],
                  ),
                ],
              ),
            ),

            // Compteur
            if (all.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filtered.length} réservation(s)',
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ),

            // Liste
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty(Icons.search_off, 'Aucun résultat')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final res = filtered[index]['reservation']
                            as ReservationModel;
                        final event =
                            filtered[index]['event'] as EventModel;
                        final canCancel = _isConfirmed(res.status) &&
                            event.date.isAfter(DateTime.now());
                        return _buildCard(res, event,
                            canCancel: canCancel);
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
        ? (isPast ? Colors.blue : Colors.green)
        : (isCancelled ? Colors.red : Colors.orange);

    String statusLabel = isConfirmed
        ? (isPast ? 'Terminée' : 'Confirmée')
        : (isCancelled ? 'Annulée' : reservation.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header titre + badge statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _infoRow(Icons.calendar_today,
                DateFormat('dd MMM yyyy • HH:mm', 'fr').format(event.date)),
            const SizedBox(height: 6),
            _infoRow(Icons.location_on, event.location),
            const SizedBox(height: 6),
            _infoRow(Icons.confirmation_number,
                '${reservation.numberOfSeats} place(s)'),
            const SizedBox(height: 6),
            _infoRow(
              Icons.payments_outlined,
              '${reservation.totalPrice.toStringAsFixed(2)} TND',
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 6),
            _infoRow(
              Icons.access_time,
              'Réservé le ${DateFormat('dd MMM yyyy', 'fr').format(reservation.createdAt)}',
              color: Colors.grey,
            ),

            if (canCancel) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _cancelBooking(reservation.id, event),
                  icon: const Icon(Icons.cancel_outlined,
                      color: Colors.red, size: 18),
                  label: const Text('Annuler la réservation',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color ?? Colors.deepPurple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 13, color: color ?? Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}