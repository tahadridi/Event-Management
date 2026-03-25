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
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;
  bool _cvvObscured = true;
  int _selectedCardType = 0;

  void _formatCardNumber(String value) {
    final clean = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    final formatted = buffer.toString();
    if (formatted != value) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _formatExpiry(String value) {
    final clean = value.replaceAll('/', '');
    String formatted = clean;
    if (clean.length >= 2) {
      formatted = '${clean.substring(0, 2)}/${clean.substring(2)}';
    }
    if (formatted != value) {
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  String get _cardBrand {
    final n = _cardNumberController.text.replaceAll(' ', '');
    if (n.startsWith('4')) return 'VISA';
    if (n.startsWith('5') || n.startsWith('2')) return 'MASTERCARD';
    if (n.startsWith('3')) return 'AMEX';
    return ['VISA', 'MASTERCARD', 'AMEX'][_selectedCardType];
  }

  Color get _cardColor {
    switch (_cardBrand) {
      case 'VISA':
        return const Color(0xFF1A1F71);
      case 'MASTERCARD':
        return const Color(0xFFEB001B);
      default:
        return const Color(0xFF007B5E);
    }
  }

  bool get _isFormValid {
    final cardClean = _cardNumberController.text.replaceAll(' ', '');
    return cardClean.length >= 15 &&
        _cardHolderController.text.trim().length >= 3 &&
        _expiryController.text.length == 5 &&
        _cvvController.text.length >= 3;
  }

  Future<void> _confirmPayment() async {
    if (!_isFormValid && widget.totalPrice > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs correctement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await Future.delayed(const Duration(seconds: 2));

      final docRef = await FirebaseFirestore.instance
          .collection('reservations')
          .add({
        'eventId': widget.event.id,
        'eventTitle': widget.event.title,
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Utilisateur',
        'numberOfSeats': widget.numberOfSeats,
        'totalPrice': widget.totalPrice,
        'status': 'confirmed',
        'organizerId': widget.event.organizerId,
        'createdAt': Timestamp.now(),
      });

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
        organizerId: widget.event.organizerId,
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFree = widget.totalPrice == 0;

    if (isFree) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Confirmation'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.confirmation_number_outlined,
                  size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text('Événement gratuit',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(widget.event.title,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('${widget.numberOfSeats} place(s) · Gratuit',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
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
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Confirmer gratuitement',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Purple header
            Container(
              width: double.infinity,
              color: Colors.deepPurple,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Récapitulatif',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(widget.event.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${widget.numberOfSeats} place(s)',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      Text(
                        '${widget.totalPrice.toStringAsFixed(0)} TND',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card preview
                  _buildCardPreview(),
                  const SizedBox(height: 24),

                  // Card type selector
                  const Text('Type de carte',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _cardTypeButton(0, 'Visa', const Color(0xFF1A1F71)),
                      const SizedBox(width: 10),
                      _cardTypeButton(
                          1, 'Mastercard', const Color(0xFFEB001B)),
                      const SizedBox(width: 10),
                      _cardTypeButton(2, 'Amex', const Color(0xFF007B5E)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Card number
                  _buildLabel('Numéro de carte'),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _cardNumberController,
                    hint: '0000  0000  0000  0000',
                    icon: Icons.credit_card,
                    maxLength: 19,
                    keyboardType: TextInputType.number,
                    onChanged: _formatCardNumber,
                  ),
                  const SizedBox(height: 16),

                  // Card holder
                  _buildLabel('Nom du titulaire'),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _cardHolderController,
                    hint: 'PRÉNOM NOM',
                    icon: Icons.person_outline,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Expiry + CVV
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Date d\'expiration'),
                            const SizedBox(height: 8),
                            _buildInput(
                              controller: _expiryController,
                              hint: 'MM/AA',
                              icon: Icons.date_range_outlined,
                              maxLength: 5,
                              keyboardType: TextInputType.number,
                              onChanged: _formatExpiry,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('CVV / CVC'),
                            const SizedBox(height: 8),
                            _buildInput(
                              controller: _cvvController,
                              hint: '•••',
                              icon: Icons.lock_outline,
                              maxLength: 4,
                              obscureText: _cvvObscured,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _cvvObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                    () => _cvvObscured = !_cvvObscured),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Security note
                  Row(
                    children: const [
                      Icon(Icons.lock, size: 13, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        'Paiement 100% sécurisé · Simulation uniquement',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding:
                            const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Payer ${widget.totalPrice.toStringAsFixed(0)} TND',
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    final number = _cardNumberController.text.isEmpty
        ? '••••  ••••  ••••  ••••'
        : _cardNumberController.text.padRight(19, '•');
    final holder = _cardHolderController.text.isEmpty
        ? 'VOTRE NOM'
        : _cardHolderController.text.toUpperCase();
    final expiry =
        _expiryController.text.isEmpty ? 'MM/AA' : _expiryController.text;

    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardColor, _cardColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.wifi, color: Colors.white54, size: 22),
              Text(_cardBrand,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          Text(number,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TITULAIRE',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(holder,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EXPIRE',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(expiry,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardTypeButton(int index, String label, Color color) {
    final selected = _selectedCardType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCardType = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54));
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int? maxLength,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      onChanged: (v) {
        onChanged?.call(v);
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: Colors.deepPurple),
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.deepPurple, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}