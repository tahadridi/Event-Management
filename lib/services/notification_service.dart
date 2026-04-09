import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../models/event_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's notifications
  Stream<List<NotificationModel>> getUserNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get unread notification count
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      rethrow;
    }
  }

  // Create notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    required String resourceId,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'resourceId': resourceId,
        'isRead': false,
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== EVENT CHANGE NOTIFICATIONS ====================

  /// Detect if changes are major (date or location changed)
  bool isMajorChange(EventModel oldEvent, EventModel newEvent) {
    return oldEvent.date != newEvent.date || 
           oldEvent.location != newEvent.location;
  }

  /// Send notifications to all participants when major changes occur
  Future<void> notifyParticipantsOfChanges({
    required String eventId,
    required String eventTitle,
    required EventModel oldEvent,
    required EventModel newEvent,
  }) async {
    try {
      // Determine what changed
      String changeType = '';
      if (oldEvent.date != newEvent.date) changeType += 'date ';
      if (oldEvent.location != newEvent.location) changeType += 'location';

      // Get all reservations for this event
      final reservationsSnapshot = await _db
          .collection('reservations')
          .where('eventId', isEqualTo: eventId)
          .get();

      if (reservationsSnapshot.docs.isEmpty) return;

      final batch = _db.batch();
      final now = Timestamp.now();

      for (final reservationDoc in reservationsSnapshot.docs) {
        final reservation = reservationDoc.data() as Map<String, dynamic>;
        final userId = reservation['userId'] as String;

        // Create notification document for participant
        final notificationRef = _db.collection('notifications').doc();
        
        String changeDescription = '';
        if (oldEvent.date != newEvent.date) {
          changeDescription = 'Date modifiée: ${_formatDate(oldEvent.date)} → ${_formatDate(newEvent.date)}';
        }
        if (oldEvent.location != newEvent.location) {
          if (changeDescription.isNotEmpty) changeDescription += ' | ';
          changeDescription += 'Lieu: ${oldEvent.location} → ${newEvent.location}';
        }

        batch.set(notificationRef, {
          'userId': userId,
          'eventId': eventId,
          'eventTitle': eventTitle,
          'type': 'event_modified_major',
          'title': 'L\'événement "$eventTitle" a été modifié',
          'message': '$changeDescription. Vérifiez les changements.',
          'isRead': false,
          'status': 'pending', // pending, accepted, cancelled
          'changeType': changeType.trim(),
          'oldDate': Timestamp.fromDate(oldEvent.date),
          'newDate': Timestamp.fromDate(newEvent.date),
          'oldLocation': oldEvent.location,
          'newLocation': newEvent.location,
          'reservationId': reservationDoc.id,
          'createdAt': now,
        });
      }

      await batch.commit();

    } catch (e) {
      print('Error notifying participants: $e');
      rethrow;
    }
  }

  /// User accepts the notification (acknowledges the change)
  Future<void> acceptNotification(String notificationId) async {
    try {
      await _db
          .collection('notifications')
          .doc(notificationId)
          .update({
            'status': 'accepted',
            'isRead': true,
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      rethrow;
    }
  }

  /// User cancels participation due to event changes
  Future<void> cancelParticipationDueToChanges({
    required String notificationId,
    required String reservationId,
    required String eventId,
  }) async {
    try {
      final batch = _db.batch();

      // Update notification status
      final notificationRef = _db.collection('notifications').doc(notificationId);
      batch.update(notificationRef, {
        'status': 'cancelled',
        'isRead': true,
        'updatedAt': Timestamp.now(),
      });

      // Get reservation to extract seat count
      final reservationDoc = await _db
          .collection('reservations')
          .doc(reservationId)
          .get();
      
      final reservation = reservationDoc.data() as Map<String, dynamic>;
      final numberOfSeats = reservation['numberOfSeats'] as int? ?? 1;

      // Delete reservation
      final reservationRef = _db.collection('reservations').doc(reservationId);
      batch.delete(reservationRef);

      // Get current event and update available places
      final eventDoc = await _db.collection('events').doc(eventId).get();
      final event = eventDoc.data() as Map<String, dynamic>;
      final currentAvailable = event['availablePlaces'] as int? ?? 0;

      final eventRef = _db.collection('events').doc(eventId);
      batch.update(eventRef, {
        'availablePlaces': currentAvailable + numberOfSeats,
      });

      await batch.commit();
      
    } catch (e) {
      print('Error cancelling participation: $e');
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} à $hour:$minute';
  }
}
