import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../reservation/payment_page.dart';

class BookingPage extends StatefulWidget {
  final EventModel event;

  const BookingPage({super.key, required this.event});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int _seats = 1;

  double get _total => _seats * widget.event.price;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isFree = event.price == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(event.location,
                            style: const TextStyle(color: Colors.black54))),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.event, size: 16, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Text(
                      '${event.date.day}/${event.date.month}/${event.date.year}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Seat selector
            const Text('Nombre de places',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                _circleButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (_seats > 1) setState(() => _seats--);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('$_seats',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                ),
                _circleButton(
                  icon: Icons.add,
                  onTap: () {
                    if (_seats < event.availablePlaces)
                      setState(() => _seats++);
                  },
                ),
                const Spacer(),
                Text(
                  '${event.availablePlaces} places dispo.',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 16),

            // Price breakdown
            _priceRow('Prix par place',
                isFree ? 'Gratuit' : '${event.price.toStringAsFixed(0)} TND'),
            const SizedBox(height: 8),
            _priceRow('Nombre de places', '$_seats'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _priceRow(
              'Total',
              isFree ? 'Gratuit' : '${_total.toStringAsFixed(0)} TND',
              isBold: true,
            ),

            const SizedBox(height: 36),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentPage(
                        event: event,
                        numberOfSeats: _seats,
                        totalPrice: _total,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isFree ? 'Confirmer la réservation' : 'Passer au paiement',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.deepPurple),
        ),
        child: Icon(icon, color: Colors.deepPurple),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? Colors.black : Colors.black87)),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? Colors.deepPurple : Colors.black87)),
      ],
    );
  }
}