import 'package:flutter/material.dart';
import '../../models/reservation_model.dart';

class ConfirmationPage extends StatelessWidget {
  final ReservationModel reservation;

  const ConfirmationPage({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 90),
              const SizedBox(height: 20),
              const Text('Réservation confirmée !',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                reservation.eventTitle,
                style:
                    const TextStyle(fontSize: 16, color: Colors.deepPurple),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Ticket card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Column(
                  children: [
                    _ticketRow('Places réservées',
                        '${reservation.numberOfSeats}'),
                    const Divider(height: 20),
                    _ticketRow(
                      'Montant payé',
                      reservation.totalPrice == 0
                          ? 'Gratuit'
                          : '${reservation.totalPrice.toStringAsFixed(0)} TND',
                    ),
                    const Divider(height: 20),
                    _ticketRow('Statut', 'Confirmé ✓'),
                    const Divider(height: 20),
                    _ticketRow('Réf.',
                        reservation.id.substring(0, 8).toUpperCase()),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Retour à l'accueil"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ticketRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}