import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/event_model.dart';
import '../../models/seat_model.dart';
import '../../models/reservation_model.dart';
import '../../services/payment_service.dart';
import 'confirmation_page.dart';

// ─────────────────────────────────────────────────────────────
// DESIGN SYSTEM - Midnight Blue & White Theme
// ─────────────────────────────────────────────────────────────

class PaymentTheme {
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF1A3A7C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnightBlue, midnightBlueLight],
  );
  
  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class PaymentPage extends StatefulWidget {
  final EventModel event;
  final int numberOfSeats;
  final double totalPrice;
  final List<SeatModel>? selectedSeats;

  const PaymentPage({
    super.key,
    required this.event,
    required this.numberOfSeats,
    required this.totalPrice,
    this.selectedSeats,
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

  Future<void> _confirmPayment() async {
    setState(() => _isLoading = true);

    try {
      final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      final secretKey = dotenv.env['STRIPE_SECRET_KEY'];

      if (widget.totalPrice > 0 && (publishableKey == null || secretKey == null)) {
        throw Exception('Stripe not configured in .env');
      }

      if (publishableKey != null && publishableKey.isNotEmpty) {
        Stripe.publishableKey = publishableKey;
        await Stripe.instance.applySettings();
      }

      // For free events, skip payment
      if (widget.totalPrice == 0) {
        print('DEBUG: Free event - creating reservation directly');
        await _createReservation('free');
        return;
      }

      final paymentIntent = await PaymentService.createPaymentIntent(
        secretKey: secretKey!,
        amount: widget.totalPrice,
        currency: 'usd',
        description: widget.event.title,
      );

      final clientSecret = paymentIntent['client_secret'] as String?;
      final paymentIntentId = paymentIntent['id'] as String?;

      if (clientSecret == null || paymentIntentId == null) {
        throw Exception('Impossible de créer le PaymentIntent');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Event Project',
          style: ThemeMode.light,
          allowsDelayedPaymentMethods: false,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await _createReservation(paymentIntentId);
      
    } catch (e) {
      print('DEBUG: Exception - $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: PaymentTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _createReservation(String paymentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final selectedSeatNumbers = widget.selectedSeats?.map((s) => s.seatNumber).toList() ?? [];

      print('DEBUG: Creating reservation with paymentId: $paymentId');

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
        'selectedSeats': selectedSeatNumbers,
        'paymentId': paymentId,
        'createdAt': Timestamp.now(),
      });

      print('DEBUG: Reservation created with ID: ${docRef.id}');

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({
        'availablePlaces': widget.event.availablePlaces - widget.numberOfSeats,
      });

      print('DEBUG: Event updated with available places');

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
        selectedSeats: selectedSeatNumbers,
      );

      print('DEBUG: Attempting navigation to confirmation page...');

      if (mounted) {
        // Clear loading state before navigation
        setState(() => _isLoading = false);
        
        print('DEBUG: Navigating...');
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ConfirmationPage(reservation: reservation),
          ),
        );
        print('DEBUG: Navigation complete');
      } else {
        print('DEBUG: Widget not mounted, skipping navigation');
      }
    } catch (e) {
      print('DEBUG: Error creating reservation - $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: PaymentTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen to card number changes to update card brand
    _cardNumberController.addListener(() {
      setState(() {});
    });
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
        backgroundColor: PaymentTheme.cream,
        appBar: AppBar(
          title: const Text(
            'Confirmation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: PaymentTheme.midnightBlue,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      PaymentTheme.midnightBlue.withOpacity(0.1),
                      PaymentTheme.midnightBlueLight.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.confirmation_number_outlined,
                  size: 80,
                  color: PaymentTheme.midnightBlue,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Événement gratuit',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: PaymentTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.event.title,
                style: TextStyle(
                  fontSize: 16,
                  color: PaymentTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PaymentTheme.midnightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.numberOfSeats} place(s) · Gratuit',
                  style: TextStyle(
                    color: PaymentTheme.midnightBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PaymentTheme.midnightBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Confirmer gratuitement',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PaymentTheme.cream,
      appBar: AppBar(
        title: const Text(
          'Paiement sécurisé',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: PaymentTheme.midnightBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Midnight blue header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: PaymentTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Récapitulatif',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.numberOfSeats} place(s)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${widget.totalPrice.toStringAsFixed(0)} TND',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
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
                  const SizedBox(height: 8),
                  
                  // Card preview
                  _buildCardPreview(),
                  const SizedBox(height: 28),

                  // Card type selector
                  const Text(
                    'Type de carte',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: PaymentTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _cardTypeButton(0, 'Visa', const Color(0xFF1A1F71)),
                      const SizedBox(width: 12),
                      _cardTypeButton(
                          1, 'Mastercard', const Color(0xFFEB001B)),
                      const SizedBox(width: 12),
                      _cardTypeButton(2, 'Amex', const Color(0xFF007B5E)),
                    ],
                  ),
                  const SizedBox(height: 28),

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
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 20),

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
                                  color: PaymentTheme.textHint,
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
                  const SizedBox(height: 16),

                  // Security note
                  Row(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 14,
                        color: PaymentTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Paiement 100% sécurisé · Simulation uniquement',
                        style: TextStyle(
                          fontSize: 11,
                          color: PaymentTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PaymentTheme.midnightBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: PaymentTheme.textHint,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  'Payer ${widget.totalPrice.toStringAsFixed(0)} TND',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardColor, _cardColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withOpacity(0.3),
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
              const Icon(Icons.wifi, color: Colors.white70, size: 24),
              Text(
                _cardBrand,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TITULAIRE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    holder,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPIRE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : PaymentTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : PaymentTheme.textHint.withOpacity(0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? color : PaymentTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: PaymentTheme.textSecondary,
      ),
    );
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
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: PaymentTheme.textHint,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: PaymentTheme.midnightBlue,
        ),
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: PaymentTheme.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaymentTheme.textHint.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PaymentTheme.textHint.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PaymentTheme.midnightBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}