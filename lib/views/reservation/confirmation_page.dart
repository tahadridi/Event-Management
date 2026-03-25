import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/reservation_model.dart';

class ConfirmationPage extends StatelessWidget {
  final ReservationModel reservation;

  const ConfirmationPage({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final isFree = reservation.totalPrice == 0;
    final ticketRef = reservation.id.substring(0, 8).toUpperCase();
    final qrData =
        'TICKET:${reservation.id}|EVENT:${reservation.eventId}|USER:${reservation.userId}|SEATS:${reservation.numberOfSeats}|REF:$ticketRef';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Billet confirmé'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 52),
                  const SizedBox(height: 10),
                  const Text('Réservation confirmée !',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(height: 4),
                  Text(reservation.eventTitle,
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                      textAlign: TextAlign.center),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Ticket card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Ticket header (purple)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('E-BILLET',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                letterSpacing: 2)),
                        const SizedBox(height: 4),
                        Text(reservation.eventTitle,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Réf: $ticketRef',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dashed separator
                  _DashedDivider(),

                  // QR Code
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.deepPurple,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Scannez ce QR pour voir les détails du billet',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Dashed separator
                  _DashedDivider(),

                  // Ticket details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _ticketRow(Icons.person_outline, 'Titulaire',
                            reservation.userName),
                        const SizedBox(height: 14),
                        _ticketRow(Icons.event_seat_outlined, 'Places',
                            '${reservation.numberOfSeats} place(s)'),
                        const SizedBox(height: 14),
                        _ticketRow(
                          Icons.payments_outlined,
                          'Montant',
                          isFree
                              ? 'Gratuit'
                              : '${reservation.totalPrice.toStringAsFixed(0)} TND',
                        ),
                        const SizedBox(height: 14),
                        _ticketRow(
                          Icons.access_time,
                          'Réservé le',
                          DateFormat('dd MMM yyyy à HH:mm', 'fr')
                              .format(reservation.createdAt),
                        ),
                        const SizedBox(height: 14),
                        _ticketRow(
                          Icons.check_circle_outline,
                          'Statut',
                          'Confirmé',
                          valueColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Retour à l'accueil",
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepPurple),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Voir mes réservations',
                    style:
                        TextStyle(color: Colors.deepPurple, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _ticketRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: valueColor ?? Colors.black87)),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final count = (constraints.maxWidth / 8).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => Container(
                    width: 4,
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
        ),
      ],
    );
  }
}