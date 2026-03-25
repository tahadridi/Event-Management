import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationBadge extends StatelessWidget {
  final NotificationService _notificationService = NotificationService();

  NotificationBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _notificationService.getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // Navigate to notifications page
                _showNotificationsSheet(context);
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _notificationService.markAllAsRead(),
                      child: const Text('Marquer tout comme lu'),
                    ),
                  ],
                ),
              ),
              // Notifications list
              Expanded(
                child: StreamBuilder(
                  stream:
                      _notificationService.getUserNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Pas de notifications',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final notifications = snapshot.data!;
                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return GestureDetector(
                          onTap: () async {
                            await _notificationService
                                .markAsRead(notif.id);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: notif.isRead
                                  ? Colors.white
                                  : Colors.deepPurple
                                      .shade50,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color: notif.isRead
                                    ? Colors.grey.shade200
                                    : Colors.deepPurple,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getIconForType(
                                          notif.type),
                                      color: Colors
                                          .deepPurple,
                                    ),
                                    const SizedBox(
                                        width: 8),
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration:
                                            const BoxDecoration(
                                          color: Colors
                                              .deepPurple,
                                          shape: BoxShape
                                              .circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'booking':
        return Icons.bookmark;
      case 'payment':
        return Icons.payment;
      case 'review':
        return Icons.rate_review;
      case 'event':
        return Icons.event;
      default:
        return Icons.notifications;
    }
  }
}
