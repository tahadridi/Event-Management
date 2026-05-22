import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../widgets/event_change_notification_dialog.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  late Stream<QuerySnapshot> _notificationsStream;
  bool _streamInitialized = false;

  // Color palette
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color creamDark = Color(0xFFF5EDE2);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _notificationsStream = _db
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            print('Firestore Stream Error: $error');
            return null;
          });
      _streamInitialized = true;
    }
  }

  void _retryStream() {
    setState(() {
      _streamInitialized = false;
      _initializeStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Non authentifié')),
      );
    }

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: midnightBlue,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: midnightBlue,
        centerTitle: false,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cream, creamDark],
            ),
          ),
        ),
      ),
      body: !_streamInitialized
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 56,
                      color: error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Impossible d\'initialiser',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: midnightBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Impossible de charger vos notifications.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _retryStream,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: midnightBlue,
                      foregroundColor: cream,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _notificationsStream,
              builder: (context, snapshot) {
                print('Stream state: ${snapshot.connectionState}, hasError: ${snapshot.hasError}');
                if (snapshot.hasError) {
                  print('Error details: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 56,
                            color: error,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Erreur lors du chargement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: midnightBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Impossible de charger les notifications. Vérifiez votre connexion.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _retryStream,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: midnightBlue,
                            foregroundColor: cream,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(midnightBlue),
                    ),
                  );
                }

                final notifications = snapshot.data?.docs ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: info.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 56,
                            color: info,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Aucune notification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: midnightBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vous êtes à jour !',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notifDoc = notifications[index];
                    final notif = notifDoc.data() as Map<String, dynamic>;

                    return _buildNotificationCard(
                      context,
                      notif,
                      notifDoc.id,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> notification,
    String notificationId,
  ) {
    final notificationType = notification['type'] ?? 'unknown';
    
    // Handle different notification types with different layouts
    if (notificationType == 'event_modified_major') {
      return _buildEventChangeCard(context, notification, notificationId);
    } else {
      return _buildGenericCard(context, notification, notificationId);
    }
  }

  Widget _buildEventChangeCard(
    BuildContext context,
    Map<String, dynamic> notification,
    String notificationId,
  ) {
    final eventTitle = notification['eventTitle'] ?? 'Événement';
    final changeType = notification['changeType'] ?? '';
    final oldDate = (notification['oldDate'] as Timestamp?)?.toDate();
    final newDate = (notification['newDate'] as Timestamp?)?.toDate();
    final oldLocation = notification['oldLocation'] ?? '';
    final newLocation = notification['newLocation'] ?? '';

    final dateFormat = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR');

    String getChangeTypeLabel() {
      if (changeType.contains('date') && changeType.contains('location')) {
        return 'Date et lieu modifiés';
      } else if (changeType.contains('date')) {
        return 'Date modifiée';
      } else if (changeType.contains('location')) {
        return 'Lieu modifié';
      }
      return 'Événement modifié';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await showDialog(
              context: context,
              builder: (dialogContext) => EventChangeNotificationDialog(
                notification: {...notification, 'id': notificationId},
                notificationId: notificationId,
                onDismiss: () {
                  Navigator.pop(dialogContext);
                  if (mounted) setState(() {});
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: midnightBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            getChangeTypeLabel(),
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Show real status from notification document
                    Builder(builder: (_) {
                      final status = notification['status'] ?? 'pending';
                      String label;
                      Color color;
                      if (status == 'accepted') {
                        label = 'Confirmé';
                        color = success;
                      } else if (status == 'cancelled') {
                        label = 'Annulé';
                        color = error;
                      } else {
                        label = 'En attente';
                        color = warning;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                if (changeType.contains('date')) ...[
                  _buildChangePreview(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    oldValue: oldDate != null ? dateFormat.format(oldDate) : 'N/A',
                    newValue: newDate != null ? dateFormat.format(newDate) : 'N/A',
                  ),
                  const SizedBox(height: 12),
                ],
                if (changeType.contains('location')) ...[
                  _buildChangePreview(
                    icon: Icons.location_on_rounded,
                    label: 'Lieu',
                    oldValue: oldLocation,
                    newValue: newLocation,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Text(
                      'Cliquez pour répondre',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenericCard(
    BuildContext context,
    Map<String, dynamic> notification,
    String notificationId,
  ) {
    final title = notification['title'] ?? 'Notification';
    final message = notification['message'] ?? '';
    final createdAt = (notification['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final notificationType = notification['type'] ?? 'unknown';

    IconData getIcon() {
      if (notificationType == 'upcoming_event') {
        return Icons.calendar_today_rounded;
      }
      return Icons.notifications_rounded;
    }

    Color getColor() {
      if (notificationType == 'upcoming_event') {
        return info;
      }
      return warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: getColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        getIcon(),
                        color: getColor(),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: midnightBlue,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChangePreview({
    required IconData icon,
    required String label,
    required String oldValue,
    required String newValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: midnightBlue),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: midnightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avant',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oldValue,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: error,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: textSecondary, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Après',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      newValue,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: success,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
