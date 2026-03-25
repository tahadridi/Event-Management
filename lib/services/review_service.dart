import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get reviews for an event
  Stream<List<ReviewModel>> getEventReviews(String eventId) {
    return _db
        .collection('reviews')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => ReviewModel.fromFirestore(doc))
              .toList();
          // Sort by createdAt on client side to avoid composite index requirement
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  // Get average rating for event
  Future<double> getAverageRating(String eventId) async {
    try {
      final snapshot = await _db
          .collection('reviews')
          .where('eventId', isEqualTo: eventId)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final ratings = snapshot.docs.map((doc) => doc['rating'] as int).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      
      return average;
    } catch (e) {
      return 0.0;
    }
  }

  // Add review
  Future<void> addReview({
    required String eventId,
    required int rating,
    required String comment,
    required String userName,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _db.collection('reviews').add({
        'eventId': eventId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Check if user already reviewed
  Future<bool> hasUserReviewed(String eventId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final snapshot = await _db
          .collection('reviews')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
