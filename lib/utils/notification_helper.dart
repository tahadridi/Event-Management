import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();
  
  /// Check for upcoming events and notify user (call on app startup or periodically)
  static Future<void> checkUpcomingEvents() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await _notificationService.checkAndNotifyUpcomingEvents();
    } catch (e) {
      print('Error checking upcoming events: $e');
    }
  }
  
  /// Call this when event details are updated to notify participants
  static Future<void> notifyEventChanged({
    required String eventTitle,
    required String changeType, // 'date' or 'place'
    required String oldValue,
    required String newValue,
  }) async {
    try {
      await _notificationService.notifyEventDetailChanged(
        eventTitle: eventTitle,
        changeType: changeType,
        oldValue: oldValue,
        newValue: newValue,
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
