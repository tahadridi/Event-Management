import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/seat_model.dart';
import '../reservation/payment_page.dart';
import '../reservation/seating_plan_page.dart';
import '../../widgets/custom_back_button.dart';

class BookingPage extends StatefulWidget {
  final EventModel event;

  const BookingPage({super.key, required this.event});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with SingleTickerProviderStateMixin {
  int _seats = 1;
  List<SeatModel> _selectedSeats = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF1A3A7C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color creamDark = Color(0xFFF5EDE2);
  static const Color accent = Color(0xFFE67E22);
  static const Color success = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  double get _total {
    if (widget.event.hasSeats && _selectedSeats.isNotEmpty) {
      return _selectedSeats.fold(0.0, (sum, seat) => sum + seat.price);
    }
    return _seats * widget.event.price;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isFree = event.price == 0;
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cream, creamDark],
                  ),
                ),
                child: Row(
                  children: [
                    CustomBackButton(
                      backgroundColor: midnightBlue.withOpacity(0.1),
                      iconColor: midnightBlue,
                      size: 44,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Réservation',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: midnightBlue,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Confirmez votre participation',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Summary Card
                        _buildEventSummaryCard(event, dateFormat, timeFormat),
                        
                        const SizedBox(height: 24),

                        // Seat Selection Card
                        _buildSeatSelectionCard(event, isFree),
                        
                        const SizedBox(height: 24),

                        // Price Breakdown Card
                        _buildPriceBreakdownCard(isFree),
                        
                        const SizedBox(height: 32),

                        // Action Button
                        _buildActionButton(isFree, event),
                        
                        const SizedBox(height: 20),
                        
                        // Additional Info
                        _buildAdditionalInfo(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventSummaryCard(EventModel event, DateFormat dateFormat, DateFormat timeFormat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [midnightBlue, midnightBlueLight],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          
          // Details Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: midnightBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: midnightBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lieu',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.location,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Date and Time
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: midnightBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: midnightBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateFormat.format(event.date),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: midnightBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: midnightBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Heure',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeFormat.format(event.date),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatSelectionCard(EventModel event, bool isFree) {
    if (event.hasSeats) {
      // Seat-based booking UI
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: midnightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_seat_rounded,
                    size: 22,
                    color: midnightBlue,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sélection des places',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Seating plan button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push<List<SeatModel>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeatingPlanPage(event: event),
                    ),
                  );
                  
                  if (result != null && result.isNotEmpty) {
                    setState(() {
                      _selectedSeats = result;
                    });
                    HapticFeedback.heavyImpact();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: midnightBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedSeats.isEmpty ? Icons.add_rounded : Icons.check_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectedSeats.isEmpty 
                        ? 'Ouvrir la salle' 
                        : '${_selectedSeats.length} place(s) sélectionnée(s)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_selectedSeats.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Places sélectionnées: ${_selectedSeats.map((s) => s.seatNumber).join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: success,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    // Traditional quantity selector
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: midnightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.people_rounded,
                  size: 22,
                  color: midnightBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nombre de places',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Seat Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSeatButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (_seats > 1) {
                    setState(() => _seats--);
                    HapticFeedback.lightImpact();
                  }
                },
                isDisabled: _seats <= 1,
              ),
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      midnightBlue.withOpacity(0.1),
                      midnightBlue.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    '$_seats',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: midnightBlue,
                    ),
                  ),
                ),
              ),
              _buildSeatButton(
                icon: Icons.add_rounded,
                onTap: () {
                  if (_seats < event.availablePlaces) {
                    setState(() => _seats++);
                    HapticFeedback.lightImpact();
                  }
                },
                isDisabled: _seats >= event.availablePlaces,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Availability info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getAvailabilityColor(event.availablePlaces).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getAvailabilityIcon(event.availablePlaces),
                  size: 18,
                  color: _getAvailabilityColor(event.availablePlaces),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getAvailabilityText(event.availablePlaces),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getAvailabilityColor(event.availablePlaces),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDisabled,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDisabled ? cream : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDisabled ? creamDark : midnightBlue.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isDisabled ? textSecondary : midnightBlue,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBreakdownCard(bool isFree) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: midnightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  size: 22,
                  color: midnightBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Détails du paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildPriceRow(
            'Prix par place',
            isFree ? 'Gratuit' : '${widget.event.price.toStringAsFixed(0)} TND',
          ),
          const SizedBox(height: 12),
          _buildPriceRow(
            'Nombre de places',
            '$_seats',
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildPriceRow(
            'Total',
            isFree ? 'Gratuit' : '${_total.toStringAsFixed(0)} TND',
            isBold: true,
            isTotal: true,
          ),
          
          if (!isFree) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 16,
                    color: success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paiement sécurisé',
                      style: TextStyle(
                        fontSize: 12,
                        color: success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? textPrimary : textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? midnightBlue : textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool isFree, EventModel event) {
    final hasSeatsSelected = event.hasSeats && _selectedSeats.isNotEmpty;
    final hasValidBooking = event.hasSeats ? hasSeatsSelected : true;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: hasValidBooking ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                event: event,
                numberOfSeats: event.hasSeats ? _selectedSeats.length : _seats,
                totalPrice: _total,
                selectedSeats: event.hasSeats ? _selectedSeats : null,
              ),
            ),
          );
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: midnightBlue,
          disabledBackgroundColor: textSecondary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFree ? Icons.check_circle_rounded : Icons.payment_rounded,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              event.hasSeats && _selectedSeats.isEmpty
                ? 'Sélectionnez des places'
                : (isFree ? 'Confirmer la réservation' : 'Passer au paiement'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: midnightBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: midnightBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vous recevrez un email de confirmation après la réservation',
              style: TextStyle(
                fontSize: 11,
                color: textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAvailabilityText(int availablePlaces) {
    if (availablePlaces > 50) {
      return 'Beaucoup de places disponibles';
    } else if (availablePlaces > 20) {
      return 'Places disponibles';
    } else if (availablePlaces > 5) {
      return 'Places limitées - Réservez vite !';
    } else {
      return 'Dernières places disponibles !';
    }
  }

  Color _getAvailabilityColor(int availablePlaces) {
    if (availablePlaces > 50) {
      return success;
    } else if (availablePlaces > 20) {
      return const Color(0xFF3B82F6);
    } else if (availablePlaces > 5) {
      return accent;
    } else {
      return const Color(0xFFEF4444);
    }
  }

  IconData _getAvailabilityIcon(int availablePlaces) {
    if (availablePlaces > 50) {
      return Icons.celebration_rounded;
    } else if (availablePlaces > 20) {
      return Icons.event_available_rounded;
    } else if (availablePlaces > 5) {
      return Icons.warning_rounded;
    } else {
      return Icons.error_rounded;
    }
  }
}