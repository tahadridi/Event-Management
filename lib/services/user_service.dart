import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user profile
  Stream<UserModel?> getCurrentUserStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(null);

    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update user profile
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String bio,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _db.collection('users').doc(userId).update({
        'name': name,
        'phone': phone,
        'bio': bio,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Toggle favorite event
  Future<void> toggleFavorite(String eventId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final userDoc = _db.collection('users').doc(userId);
      final user = await userDoc.get();
      
      if (!user.exists) throw Exception('User not found');

      final favorites =
          List<String>.from(user.data()?['favoriteEventIds'] ?? []);

      if (favorites.contains(eventId)) {
        favorites.remove(eventId);
      } else {
        favorites.add(eventId);
      }

     await userDoc.set(
  {
    'favoriteEventIds': favorites,
    'updatedAt': FieldValue.serverTimestamp(),
  },
  SetOptions(merge: true),  
);
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Check if event is favorite
  Future<bool> isFavorite(String eventId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final favorites = List<String>.from(userDoc.data()?['favoriteEventIds'] ?? []);
      
      return favorites.contains(eventId);
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Get user's favorite events
  Stream<List<String>> getUserFavoritesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return [];
          return List<String>.from(doc.data()?['favoriteEventIds'] ?? []);
        });
  }

  // Create user profile (called after registration)
  Future<void> createUserProfile({
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _db.collection('users').doc(userId).set({
        'id': userId,
        'email': email,
        'name': name,
        'phone': '',
        'role': role,
        'favoriteEventIds': [],
        'profileImageUrl': '',
        'bio': '',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
