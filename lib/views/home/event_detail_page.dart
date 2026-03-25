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
bool _hasReviewed = false;
bool _initialLoadDone = false; 

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
  if (_initialLoadDone) return; // ← ne recharge jamais une 2e fois
  try {
    final results = await Future.wait([
      _userService.isFavorite(widget.event.id),
      _reviewService.getAverageRating(widget.event.id),
      _reviewService.hasUserReviewed(widget.event.id),
    ]);

    if (mounted) {
      setState(() {
        _isFavorite = results[0] as bool;
        _averageRating = results[1] as double;
        _hasReviewed = results[2] as bool;
        _initialLoadDone = true; // ← marque comme chargé
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
                ? '❤️ Ajouté aux favoris'
                : '💔 Retiré des favoris'),
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

  // ← Plus de _submitReview ici, c'est dans AddReviewSheet
  void _showAddReviewDialog() async {
    // Get user name from Firestore
    String userName = 'Utilisateur';
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          userName = userDoc.data()?['name'] ?? _auth.currentUser?.email ?? 'Utilisateur';
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
    }

    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => AddReviewSheet(
        eventId: widget.event.id,
        userName: userName,
        onReviewSubmitted: () async {
          // Just refresh the rating, don't rebuild entire page
          if (mounted) {
            final newRating =
                await _reviewService.getAverageRating(widget.event.id);
            if (mounted) {
              setState(() {
                _averageRating = newRating;
                _hasReviewed = true;
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Avis publié avec succès')),
            );
          }
        },
      ),
    );
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.event, size: 80, color: Colors.white30),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Catégorie + Rating
                  Row(
                    children: [
                      Chip(
                        label: Text(widget.event.category),
                        backgroundColor: Colors.deepPurple.shade50,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor),
                        ),
                        child: Text(
                          widget.event.status,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_averageRating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 18, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              _averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _infoRow(Icons.calendar_today,
                      DateFormat('EEEE dd MMMM yyyy • HH:mm', 'fr')
                          .format(widget.event.date)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.location_on, widget.event.location),
                  const SizedBox(height: 12),
                  _infoRow(Icons.person,
                      'Organisé par ${widget.event.organizerName}'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.people,
                      '${widget.event.availablePlaces} / ${widget.event.totalPlaces} places disponibles'),

                  const Divider(height: 32),

                  const Text('Description',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
                    style: const TextStyle(
                        fontSize: 15, height: 1.6, color: Colors.black87),
                  ),

                  const SizedBox(height: 32),

                  // Prix + Bouton réserver
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Prix',
                              style: TextStyle(color: Colors.grey)),
                          Text(
                            widget.event.price == 0
                                ? 'Gratuit'
                                : '${widget.event.price.toStringAsFixed(0)} TND',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.event.availablePlaces == 0
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BookingPage(event: widget.event),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.bookmark_add),
                          label: Text(widget.event.availablePlaces == 0
                              ? 'Complet'
                              : 'Réserver'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Section avis
                  const Text('Avis des participants',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Bouton donner avis — toujours disponible
               if (!_initialLoadDone)
  const SizedBox(
    height: 44,
    child: Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  )
else
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: _showAddReviewDialog,
      icon: const Icon(Icons.rate_review),
      label: Text(_hasReviewed ? 'Modifier votre avis' : 'Donner votre avis'),
    ),
  ),

                  const SizedBox(height: 16),

                  // ← Widget isolé : plus de StreamBuilder ici
                  ReviewsList(eventId: widget.event.id),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 15, color: Colors.black87)),
        ),
      ],
    );
  }
}