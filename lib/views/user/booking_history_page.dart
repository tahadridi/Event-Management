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

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final ReservationService _reservationService = ReservationService();
  String _selectedTab = 'upcoming'; // 'upcoming' or 'past'

  Future<void> _cancelBooking(
    String reservationId,
    EventModel event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Text(
            'Êtes-vous sûr de vouloir annuler votre réservation pour "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _reservationService.cancelReservation(reservationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Réservation annulée')),
          );
          setState(() {});
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
        title: const Text('Mes Réservations'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 'upcoming'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 'upcoming'
                                ? Colors.deepPurple
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'À venir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 'upcoming'
                                ? Colors.deepPurple
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 'past'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 'past'
                                ? Colors.deepPurple
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Historique',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 'past'
                                ? Colors.deepPurple
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedTab == 'upcoming'
                ? _buildUpcomingBookings()
                : _buildPastBookings(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reservationService.getUpcomingReservations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Pas de réservations à venir',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final reservation =
                bookings[index]['reservation'] as ReservationModel;
            final event = bookings[index]['event'] as EventModel?;

            if (event == null) return const SizedBox.shrink();

            return _buildBookingCard(
              reservation,
              event,
              canCancel: true,
              onCancel: () => _cancelBooking(reservation.id, event),
            );
          },
        );
      },
    );
  }

  Widget _buildPastBookings() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reservationService.getUserBookingHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Pas d\'historique',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final reservation =
                bookings[index]['reservation'] as ReservationModel;
            final event = bookings[index]['event'] as EventModel?;

            if (event == null) return const SizedBox.shrink();

            return _buildBookingCard(
              reservation,
              event,
              canCancel: event.date.isAfter(DateTime.now()),
              onCancel: event.date.isAfter(DateTime.now())
                  ? () => _cancelBooking(reservation.id, event)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildBookingCard(
    ReservationModel reservation,
    EventModel event, {
    required bool canCancel,
    VoidCallback? onCancel,
  }) {
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
            // Header
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: reservation.status.toLowerCase() == 'confirmed' ||
        reservation.status.toLowerCase() == 'confirmée'
    ? Colors.green.shade50
    : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: reservation.status.toLowerCase() == 'confirmed' ||
        reservation.status.toLowerCase() == 'confirmée'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  child: Text(
                    reservation.status.toLowerCase() == 'confirmed' || reservation.status.toLowerCase() == 'confirmée'
                        ? 'Confirmée'
                        : 'Annulée',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: reservation.status.toLowerCase() == 'confirmed' ||
        reservation.status.toLowerCase() == 'confirmée' 
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info rows
            _infoRow(
              Icons.calendar_today,
              DateFormat('EEEE dd MMMM yyyy • HH:mm', 'fr').format(event.date),
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.location_on, event.location),
            const SizedBox(height: 8),
            _infoRow(
              Icons.people,
              '${reservation.numberOfSeats} place(s) réservée(s)',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.attach_money,
              '${reservation.totalPrice.toStringAsFixed(2)} TND',
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 16),

            // Cancel button
            if (canCancel && onCancel != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text(
                    'Annuler la réservation',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.deepPurple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color ?? Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
