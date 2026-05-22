import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/event_model.dart';
import '../../models/reservation_model.dart';
import '../../services/review_service.dart';
import '../../services/user_service.dart';
import '../../services/reservation_service.dart';
import '../../views/reservation/booking_page.dart';
import '../../widgets/add_review_sheet.dart';
import '../../widgets/reviews_list.dart';
import 'dart:ui' as ui;
class EventDetailPage extends StatefulWidget {
  final EventModel event;
  
  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage>
    with TickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  final UserService _userService = UserService();
  final ReservationService _reservationService = ReservationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isFavorite = false;
  double _averageRating = 0;
  int _reviewCount = 0;
  bool _hasReviewed = false;
  bool _initialLoadDone = false;
  ReservationModel? _userReservation;
  late EventModel _currentEvent;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _locationScrollController;
  
  // Stream subscriptions for real-time updates
  StreamSubscription<DocumentSnapshot>? _eventSubscription;
  StreamSubscription<QuerySnapshot>? _reservationSubscription;

  // Color palette - Midnight Blue & Cream
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF1A3A7C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color creamDark = Color(0xFFE8E0D4);
  static const Color accent = Color(0xFFE67E22);
  static const Color accentLight = Color(0xFFF39C12);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _loadInitialData();
    _setupRealtimeListeners();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    
    // Initialize location scroll controller with very slow speed
    _locationScrollController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
  }

  void _setupRealtimeListeners() {
    // Listen to event changes
    _eventSubscription = _db
        .collection('events')
        .doc(widget.event.id)
        .snapshots()
        .listen((eventDoc) {
      if (eventDoc.exists && mounted) {
        setState(() {
          _currentEvent = EventModel.fromFirestore(eventDoc);
        });
      }
    });

    // Listen to user's CONFIRMED reservation for this event only
    _reservationSubscription = _db
        .collection('reservations')
        .where('eventId', isEqualTo: widget.event.id)
        .where('userId', isEqualTo: _auth.currentUser?.uid ?? '')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        // Only show confirmed reservations, filter out cancelled ones
        final confirmedReservations = snapshot.docs
            .where((doc) {
              final status = (doc.data()['status'] as String).toLowerCase();
              return status == 'confirmed' || status == 'confirmée';
            })
            .toList();

        if (confirmedReservations.isNotEmpty) {
          setState(() {
            _userReservation =
                ReservationModel.fromFirestore(confirmedReservations.first);
          });
        } else {
          setState(() {
            _userReservation = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationScrollController.dispose();
    _eventSubscription?.cancel();
    _reservationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_initialLoadDone) return;
    try {
      final isFavRes = await _userService.isFavorite(widget.event.id);
      final ratingRes =
          await _reviewService.getAverageRatingAndCount(widget.event.id);
      final hasReviewedRes =
          await _reviewService.hasUserReviewed(widget.event.id);
      
      // Don't load user reservation here - let the real-time listener handle it
      // This prevents showing cancelled reservations
      
      if (mounted) {
        setState(() {
          _isFavorite = isFavRes;
          _averageRating = ratingRes['rating'] as double;
          _reviewCount = ratingRes['count'] as int;
          _hasReviewed = hasReviewedRes;
          // _userReservation will be set by the real-time listener
          _initialLoadDone = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _initialLoadDone = true);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await _userService.toggleFavorite(widget.event.id);
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _isFavorite ? accent : midnightBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showAddReviewDialog() async {
    String userName = 'Utilisateur';
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (doc.exists) {
          userName = doc.data()?['name'] ??
              _auth.currentUser?.email ??
              'Utilisateur';
        }
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => AddReviewSheet(
        eventId: widget.event.id,
        userName: userName,
        onReviewSubmitted: () async {
          if (mounted) {
            final res = await _reviewService
                .getAverageRatingAndCount(widget.event.id);
            if (mounted) {
              setState(() {
                _averageRating = res['rating'] as double;
                _reviewCount = res['count'] as int;
                _hasReviewed = true;
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avis publié avec succès'),
                backgroundColor: success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = _currentEvent;
    final dayFormat = DateFormat('dd').format(event.date);
    final monthFormat = DateFormat('MMM', 'fr').format(event.date).toUpperCase();
    final timeFormat = DateFormat('HH:mm', 'fr').format(event.date);

    return Scaffold(
      backgroundColor: cream,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // Hero image section
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Hero image with overlay
                    Container(
                      height: 420,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          image: (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(event.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: midnightBlue.withOpacity(0.3),
                      ),
                      child: (event.imageUrl == null || event.imageUrl!.isEmpty)
                          ? Center(
                              child: Icon(
                                _categoryIcon(),
                                size: 100,
                                color: midnightBlue.withOpacity(0.2),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                    cream,
                                  ],
                                  stops: const [0.3, 0.6, 1.0],
                                ),
                              ),
                            ),
                    ),

                    // Back button
                    Positioned(
                      top: 48,
                      left: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: midnightBlue,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    // Favorite button
                    Positioned(
                      top: 48,
                      right: 20,
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isFavorite ? error : midnightBlue,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    // Category badge
                    Positioned(
                      bottom: 140,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: midnightBlue,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: midnightBlue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryIcon(),
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              event.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Event title
                    Positioned(
                      bottom: 60,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildScrollingLocation(event.location),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content section
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Stats grid
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'Date',
                                    mainValue: dayFormat,
                                    subValue: monthFormat,
                                    secondLine: timeFormat,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: textLight.withOpacity(0.3),
                                ),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.timer_rounded,
                                    label: 'Heure',
                                    mainValue: timeFormat.split(':')[0],
                                    subValue: 'h${timeFormat.split(':')[1]}',
                                    secondLine: '',
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: textLight.withOpacity(0.3),
                                ),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.local_offer_rounded,
                                    label: 'Prix',
                                    mainValue: event.isFree
                                        ? 'Gratuit'
                                      : event.displayPrice.toStringAsFixed(0),
                                    subValue: event.isFree ? '' : 'TND',
                                    secondLine: '',
                                    isHighlighted: !event.isFree,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Capacity indicator
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
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
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.event_seat_rounded,
                                        color: midnightBlue,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Places disponibles',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${event.availablePlaces} places',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: event.availablePlaces > 10
                                                  ? success
                                                  : event.availablePlaces > 0
                                                      ? accent
                                                      : error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (event.availablePlaces > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: event.availablePlaces > 10
                                              ? success.withOpacity(0.1)
                                              : accent.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          event.availablePlaces > 10
                                              ? 'Disponible'
                                              : 'Dernières places',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: event.availablePlaces > 10
                                                ? success
                                                : accent,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (event.totalPlaces -
                                            event.availablePlaces) /
                                        event.totalPlaces,
                                    minHeight: 8,
                                    backgroundColor:
                                        textLight.withOpacity(0.2),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      event.availablePlaces > 10
                                          ? success
                                          : event.availablePlaces > 0
                                              ? accent
                                              : error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Description section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
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
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: midnightBlue,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'À propos',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  event.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // User's reserved seats section
                          if (_userReservation != null)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
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
                                        width: 4,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: success,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Vos places',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _userReservation!.status.toLowerCase() == 'confirmed' ||
                                                  _userReservation!.status.toLowerCase() == 'confirmée'
                                              ? success.withOpacity(0.1)
                                              : accent.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _userReservation!.status.toLowerCase() == 'confirmed' ||
                                                  _userReservation!.status.toLowerCase() == 'confirmée'
                                              ? 'Confirmée'
                                              : 'En attente',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _userReservation!.status.toLowerCase() == 'confirmed' ||
                                                    _userReservation!.status.toLowerCase() == 'confirmée'
                                                ? success
                                                : accent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: _userReservation!.selectedSeats
                                        .map((seatNumber) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: success
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: success.withOpacity(0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    seatNumber,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: success,
                                                    ),
                                                  ),
                                                  const Text(
                                                    'Place',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Rating and reviews section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
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
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: midnightBlue,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Avis',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_averageRating > 0) ...[
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 20,
                                        color: Color(0xFFFFB800),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _averageRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFFB800),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '($_reviewCount)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _showAddReviewDialog,
                                    icon: Icon(
                                      _hasReviewed
                                          ? Icons.edit_rounded
                                          : Icons.rate_review_rounded,
                                      size: 18,
                                      color: midnightBlue,
                                    ),
                                    label: Text(
                                      _hasReviewed
                                          ? 'Modifier votre avis'
                                          : 'Donner votre avis',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: midnightBlue,
                                      side: BorderSide(
                                        color: midnightBlue.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ReviewsList(eventId: event.id),
                              ],
                            ),
                          ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Beautiful Booking Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cream.withOpacity(0),
                    cream.withOpacity(0.9),
                    cream,
                    cream,
                  ],
                  stops: const [0, 0.1, 0.3, 1],
                ),
              ),
              child: SafeArea(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: event.availablePlaces == 0
                      ? _buildSoldOutButton()
                      : _buildBookButton(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    final event = _currentEvent;
    final isLowStock = event.availablePlaces <= 10;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: midnightBlue.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingPage(event: event),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: midnightBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background gradient effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        midnightBlue,
                        midnightBlueLight,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                child: Row(
                  children: [
                    // Left icon with pulse animation
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.book_online_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Center text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Réserver maintenant',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (event.price > 0)
                            Text(
                              '${event.price.toStringAsFixed(0)} TND / place',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          if (isLowStock)
                            Text(
                              '⚠️ Plus que ${event.availablePlaces} places!',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Right price/availability badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isLowStock 
                            ? accent 
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: isLowStock
                            ? [
                                BoxShadow(
                                  color: accent.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${event.availablePlaces}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? Colors.white : Colors.white,
                            ),
                          ),
                          Text(
                            'places',
                            style: TextStyle(
                              fontSize: 9,
                              color: isLowStock 
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Arrow icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoldOutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade400,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cancel_rounded,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              const Text(
                'Complet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.event.totalPlaces} places',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String mainValue,
    required String subValue,
    required String secondLine,
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: midnightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: midnightBlue,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              mainValue,
              style: TextStyle(
                fontSize: isHighlighted ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? accent : textPrimary,
              ),
            ),
            if (subValue.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                subValue,
                style: const TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        if (secondLine.isNotEmpty)
          Text(
            secondLine,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
      ],
    );
  }

  IconData _categoryIcon() {
    switch (widget.event.category.toLowerCase()) {
      case 'concert':
      case 'musique':
        return Icons.music_note_rounded;
      case 'sport':
        return Icons.sports_soccer_rounded;
      case 'art':
      case 'exposition':
        return Icons.palette_rounded;
      case 'conférence':
      case 'séminaire':
        return Icons.mic_rounded;
      case 'atelier':
        return Icons.build_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Widget _buildScrollingLocation(String location) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: location,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white70,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    // Check if text is too long (200 is approximate max width for location in hero)
    final isOverflow = textPainter.width > 200;

    if (!isOverflow) {
      return Text(
        location,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white70,
        ),
        maxLines: 1,
      );
    }

    // If too long, create scrollable container with automatic scroll
    // Start animation automatically on first build if overflow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isOverflow && _locationScrollController.status == AnimationStatus.dismissed) {
        _locationScrollController.repeat();
      }
    });

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: AnimatedBuilder(
        animation: _locationScrollController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(-(_locationScrollController.value * textPainter.width), 0),
            child: Row(
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(width: 32),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}