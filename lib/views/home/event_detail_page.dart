import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';
import '../../services/review_service.dart';
import '../../services/user_service.dart';
import '../../views/reservation/booking_page.dart';
import '../../widgets/add_review_sheet.dart';
import '../../widgets/reviews_list.dart';

class EventDetailPage extends StatefulWidget {
  final EventModel event;
  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final ReviewService _reviewService = ReviewService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isFavorite = false;
  double _averageRating = 0;
  int _reviewCount = 0;
  bool _hasReviewed = false;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_initialLoadDone) return;
    try {
      final isFavRes = await _userService.isFavorite(widget.event.id);
      final ratingRes =
          await _reviewService.getAverageRatingAndCount(widget.event.id);
      final hasReviewedRes =
          await _reviewService.hasUserReviewed(widget.event.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavRes;
          _averageRating = ratingRes['rating'] as double;
          _reviewCount = ratingRes['count'] as int;
          _hasReviewed = hasReviewedRes;
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
            content: Text(_isFavorite
                ? 'Ajouté aux favoris'
                : 'Retiré des favoris'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
                  backgroundColor: Colors.green),
            );
          }
        },
      ),
    );
  }

  Color get _categoryColor {
    switch (widget.event.category.toLowerCase()) {
      case 'concert':
      case 'musique':
        return const Color(0xFF7C3AED);
      case 'sport':
        return const Color(0xFF059669);
      case 'art':
      case 'exposition':
        return const Color(0xFFDB2777);
      case 'conférence':
      case 'séminaire':
        return const Color(0xFF2563EB);
      case 'atelier':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Color get _statusColor {
    switch (widget.event.status) {
      case 'Complet':
        return Colors.red;
      case 'En attente':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final catColor = _categoryColor;
    final availabilityPercent = event.totalPlaces > 0
        ? event.availablePlaces / event.totalPlaces
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: CustomScrollView(
        slivers: [
          // ── App bar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: catColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    key: ValueKey(_isFavorite),
                    color:
                        _isFavorite ? Colors.red.shade300 : Colors.white,
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 60, 16),
              title: Text(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient bg using category color
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          catColor.withOpacity(0.9),
                          catColor,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                  // Decorative pattern
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  // Category icon centered
                  Center(
                    child: Icon(
                      _categoryIcon(),
                      size: 72,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Quick info strip ─────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(event.category,
                            style: TextStyle(
                                color: catColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(event.status,
                            style: TextStyle(
                                color: _statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                      const Spacer(),
                      // Rating
                      if (_averageRating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 3),
                            Text(
                              _averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            Text(' ($_reviewCount)',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Event info cards ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Date card
                      _infoCard(
                        icon: Icons.calendar_month_outlined,
                        color: catColor,
                        title: 'Date & heure',
                        value: DateFormat('EEEE dd MMMM yyyy • HH:mm',
                                'fr')
                            .format(event.date),
                      ),
                      const SizedBox(height: 10),
                      // Location card
                      _infoCard(
                        icon: Icons.location_on_outlined,
                        color: catColor,
                        title: 'Lieu',
                        value: event.location,
                      ),
                      const SizedBox(height: 10),
                      // Organizer card
                      _infoCard(
                        icon: Icons.person_outline,
                        color: catColor,
                        title: 'Organisateur',
                        value: event.organizerName,
                      ),
                      const SizedBox(height: 10),

                      // Availability card with progress bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color:
                                        catColor.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.people_outline,
                                      color: catColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Disponibilité',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight:
                                                  FontWeight.w600)),
                                      Text(
                                        '${event.availablePlaces} / ${event.totalPlaces} places',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  event.availablePlaces == 0
                                      ? 'Complet'
                                      : '${(availabilityPercent * 100).toInt()}%',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: availabilityPercent > 0.5
                                          ? Colors.green
                                          : availabilityPercent > 0.2
                                              ? Colors.orange
                                              : Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: availabilityPercent,
                                minHeight: 6,
                                backgroundColor:
                                    Colors.grey.shade100,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  availabilityPercent > 0.5
                                      ? Colors.green
                                      : availabilityPercent > 0.2
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Description ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(
                          event.description,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.7,
                              color: Color(0xFF555555)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Reviews ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Avis des participants',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          if (_averageRating > 0)
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < _averageRating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!_initialLoadDone)
                        const Center(
                            child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showAddReviewDialog,
                            icon: const Icon(Icons.rate_review,
                                size: 18),
                            label: Text(_hasReviewed
                                ? 'Modifier votre avis'
                                : 'Donner votre avis'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: catColor,
                              side: BorderSide(color: catColor),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ReviewsList(eventId: event.id),
                    ],
                  ),
                ),

                // ── Bottom spacing for the sticky button ──────────────
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // ── Sticky bottom bar: price + reserve ────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prix',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  event.price == 0
                      ? 'Gratuit'
                      : '${event.price.toStringAsFixed(0)} TND',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: catColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: event.availablePlaces == 0
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingPage(event: event),
                          ),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: catColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  event.availablePlaces == 0
                      ? 'Complet'
                      : 'Réserver maintenant',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A2E))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon() {
    switch (widget.event.category.toLowerCase()) {
      case 'concert':
      case 'musique':
        return Icons.music_note;
      case 'sport':
        return Icons.sports_soccer;
      case 'art':
      case 'exposition':
        return Icons.palette;
      case 'conférence':
      case 'séminaire':
        return Icons.mic;
      case 'atelier':
        return Icons.build;
      default:
        return Icons.event;
    }
  }
}