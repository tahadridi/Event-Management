import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../models/reservation_model.dart';
import 'confirmation_page.dart';

class PaymentPage extends StatefulWidget {
  final EventModel event;
  final int numberOfSeats;
  final double totalPrice;

  const PaymentPage({
    super.key,
    required this.event,
    required this.numberOfSeats,
    required this.totalPrice,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _cardController = TextEditingController(text: '4242 4242 4242 4242');
  final _expiryController = TextEditingController(text: '12/26');
  final _cvvController = TextEditingController(text: '123');
  bool _isLoading = false;

  Future<void> _confirmPayment() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Simulate a short payment delay
      await Future.delayed(const Duration(seconds: 2));

      // Save reservation to Firestore
      final docRef =
          await FirebaseFirestore.instance.collection('reservations').add({
        'eventId': widget.event.id,
        'eventTitle': widget.event.title,
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Utilisateur',
        'numberOfSeats': widget.numberOfSeats,
        'totalPrice': widget.totalPrice,
        'status': 'confirmed',
        'createdAt': Timestamp.now(),
      });

      // Decrease available places in the event
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({
        'availablePlaces':
            widget.event.availablePlaces - widget.numberOfSeats,
      });

      final reservation = ReservationModel(
        id: docRef.id,
        eventId: widget.event.id,
        eventTitle: widget.event.title,
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Utilisateur',
        numberOfSeats: widget.numberOfSeats,
        totalPrice: widget.totalPrice,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmationPage(reservation: reservation),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFree = widget.totalPrice == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.event.title,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${widget.numberOfSeats} place(s) · '
                          '${isFree ? "Gratuit" : "${widget.totalPrice.toStringAsFixed(0)} TND"}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            if (!isFree) ...[
              const Text('Informations de paiement',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Simulation — aucun vrai paiement effectué',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              _buildField('Numéro de carte', _cardController,
                  hint: '0000 0000 0000 0000'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildField('Expiration', _expiryController,
                        hint: 'MM/YY')),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildField('CVV', _cvvController, hint: '123')),
              ]),
              const SizedBox(height: 28),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isFree
                            ? 'Confirmer gratuitement'
                            : 'Payer ${widget.totalPrice.toStringAsFixed(0)} TND',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}