import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../models/event_model.dart';
import '../../models/seat_model.dart';
import '../../models/reservation_model.dart';
import '../../services/seat_service.dart';

class SeatingPlanPage extends StatefulWidget {
  final EventModel event;

  const SeatingPlanPage({
    super.key,
    required this.event,
  });

  @override
  State<SeatingPlanPage> createState() => _SeatingPlanPageState();
}

class _SeatingPlanPageState extends State<SeatingPlanPage> {
  final SeatService _seatService = SeatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Set<String> _selectedSeatIds = {};
  final Set<String> _bookedSeatIds = {};
  final Set<String> _userBookedSeatIds = {};

  late List<SeatModel> _allSeats = [];
  bool _isLoading = true;
  String? _hoveredSeatId;

  // Listener for real-time reservation updates
  late final StreamSubscription<QuerySnapshot>? _reservationSubscription;

  // Color palette - Midnight Blue & Cream (matching your design)
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color accent = Color(0xFFE67E22); // Orange accent
  static const Color success = Color(0xFF10B981); // Available
  static const Color error = Color(0xFFEF4444); // Booked
  static const Color warning = Color(0xFFF59E0B); // Selected
  static const Color info = Color(0xFF3B82F6); // User's booked
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadSeats();
    // Set up real-time listener for reservation updates
    _reservationSubscription = _db
        .collection('reservations')
        .where('eventId', isEqualTo: widget.event.id)
        .snapshots()
        .listen((_) {
          // When reservations change, reload them
          _loadReservations();
        });
  }

  @override
  void dispose() {
    _reservationSubscription?.cancel();
    super.dispose();
  }

  String _extractErrorMessage(dynamic exception) {
    final exceptionString = exception.toString();
    // Extract message from "Exception: message" format
    if (exceptionString.startsWith('Exception: ')) {
      return exceptionString.substring(11);
    }
    return 'Une erreur s\'est produite. Veuillez réessayer.';
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _loadSeats() async {
    try {
      final seats = await _seatService.getSeatsByEvent(widget.event.id);
      _allSeats = seats;
      await _loadReservations();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar(_extractErrorMessage(e));
      }
    }
  }

  Future<void> _loadReservations() async {
    try {
      final userId = _auth.currentUser?.uid;
      
      // Clear old booked seats before reloading
      _bookedSeatIds.clear();
      _userBookedSeatIds.clear();
      
      final querySnapshot = await _db
          .collection('reservations')
          .where('eventId', isEqualTo: widget.event.id)
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (final doc in querySnapshot.docs) {
        final reservation = ReservationModel.fromFirestore(doc);
        for (final seatNumber in reservation.selectedSeats) {
          final seatDoc = _allSeats.firstWhere(
            (s) => s.seatNumber == seatNumber,
            orElse: () => SeatModel(
              id: '',
              eventId: '',
              row: '',
              column: 0,
              status: '',
              price: 0,
              zone: '',
            ),
          );
          if (seatDoc.id.isNotEmpty) {
            _bookedSeatIds.add(seatDoc.id);
            if (reservation.userId == userId) {
              _userBookedSeatIds.add(seatDoc.id);
            }
          }
        }
      }
      
      // Trigger update
      setState(() {});
    } catch (e) {
      // Silently fail for reservation loading
    }
  }

  void _toggleSeat(SeatModel seat) {
    HapticFeedback.lightImpact();
    
    if (_bookedSeatIds.contains(seat.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.block, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Ce siège est déjà réservé'),
            ],
          ),
          backgroundColor: error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      if (_selectedSeatIds.contains(seat.id)) {
        _selectedSeatIds.remove(seat.id);
      } else {
        _selectedSeatIds.add(seat.id);
      }
    });
  }

  List<SeatModel> get _selectedSeats =>
      _allSeats.where((s) => _selectedSeatIds.contains(s.id)).toList();

  double get _totalPrice => _selectedSeats.fold(0, (sum, s) => sum + s.price);

  String get _selectedSeatsDisplay =>
      _selectedSeats.map((s) => s.seatNumber).join(', ');

  int get _remainingSeats =>
      _allSeats.where((s) => !_bookedSeatIds.contains(s.id) && !_selectedSeatIds.contains(s.id)).length;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: midnightBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: cream),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélection des sièges',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cream,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              widget.event.title.length > 30
                  ? '${widget.event.title.substring(0, 30)}...'
                  : widget.event.title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(midnightBlue),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chargement du plan de salle...',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 16,
                      left: isSmallScreen ? 16 : 24,
                      right: isSmallScreen ? 16 : 24,
                      bottom: 120,
                    ),
                    child: Column(
                      children: [
                        // Pricing Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.event_seat,
                                  color: accent,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tarifs',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildPriceChip(
                                          'Front',
                                          widget.event.frontSeatPrice,
                                          accent,
                                        ),
                                        const SizedBox(width: 12),
                                        _buildPriceChip(
                                          'Standard',
                                          widget.event.regularSeatPrice,
                                          midnightBlue,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Elegant Legend
                        _buildPremiumLegend(isSmallScreen),
                        const SizedBox(height: 32),

                        // Stage
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                midnightBlue,
                                midnightBlue.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: midnightBlue.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'SCÈNE',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: cream,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Seating Grid
                        _buildPremiumSeatingGrid(isSmallScreen),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Selection Confirmation Panel
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  bottom: _selectedSeats.isEmpty ? -200 : 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: midnightBlue,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 3,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Sièges sélectionnés',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: accent,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _selectedSeatsDisplay,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: cream,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_totalPrice.toStringAsFixed(0)} TND',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(context, _selectedSeats);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Confirmer ${_selectedSeats.length} siège(s)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPriceChip(String label, double price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: ${price.toStringAsFixed(0)} TND',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPremiumLegend(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 16,
        runSpacing: 12,
        children: [
          _buildLegendItem('Disponible', success, Icons.check_circle),
          _buildLegendItem('Sélectionné', warning, Icons.star),
          _buildLegendItem('Réservé', error, Icons.lock),
          _buildLegendItem('Vos places', info, Icons.verified_user),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_seat, color: accent, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Places restantes: $_remainingSeats',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSeatingGrid(bool isSmallScreen) {
    final seatsByRow = <String, List<SeatModel>>{};

    for (final seat in _allSeats) {
      seatsByRow.putIfAbsent(seat.row, () => []);
      seatsByRow[seat.row]!.add(seat);
    }

    for (final row in seatsByRow.values) {
      row.sort((a, b) => a.column.compareTo(b.column));
    }

    final sortedRows = seatsByRow.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Get max seats per row for calculation
    int maxSeatsPerRow = sortedRows.isEmpty 
        ? 10 
        : sortedRows.map((e) => e.value.length).reduce((a, b) => a > b ? a : b);

    // Calculate dynamic seat size based on available width
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (isSmallScreen ? 50 : 100); // Row label + padding
    final seatSize = (availableWidth / maxSeatsPerRow).clamp(30.0, 50.0);
    final spacing = seatSize > 40 ? 8.0 : 4.0;

    return Column(
      children: sortedRows.map((entry) {
        final row = entry.key;
        final seats = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // Row label
              SizedBox(
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: midnightBlue,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: midnightBlue.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      row,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cream,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Seats (all on one line, horizontally scrollable)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: seats.asMap().entries.map((seatEntry) {
                      final seatIndex = seatEntry.key;
                      final seat = seatEntry.value;

                      final isSelected = _selectedSeatIds.contains(seat.id);
                      final isBooked = _bookedSeatIds.contains(seat.id);
                      final isUserBooked = _userBookedSeatIds.contains(seat.id);
                      final isAvailable = !isBooked && !isUserBooked;
                      final isHovered = _hoveredSeatId == seat.id;

                      Color seatColor;
                      
                      if (isUserBooked) {
                        seatColor = info;
                      } else if (isBooked) {
                        seatColor = error;
                      } else if (isSelected) {
                        seatColor = warning;
                      } else {
                        seatColor = success;
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          right: seatIndex == seats.length - 1 ? 0 : spacing,
                        ),
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoveredSeatId = seat.id),
                          onExit: (_) => setState(() => _hoveredSeatId = null),
                          child: GestureDetector(
                            onTap: () => _toggleSeat(seat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: seatSize,
                              height: seatSize,
                              decoration: BoxDecoration(
                                color: seatColor.withOpacity(isSelected ? 1.0 : 0.8),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  if (isHovered && isAvailable)
                                    BoxShadow(
                                      color: seatColor.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  if (isSelected)
                                    BoxShadow(
                                      color: warning.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                ],
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  seat.seatNumber,
                                  style: TextStyle(
                                    fontSize: seatSize > 40 ? 10 : 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}