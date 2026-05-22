import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class EventChangeNotificationDialog extends StatefulWidget {
  final Map<String, dynamic> notification;
  final String? notificationId;
  final VoidCallback onDismiss;

  const EventChangeNotificationDialog({
    super.key,
    required this.notification,
    this.notificationId,
    required this.onDismiss,
  });

  @override
  State<EventChangeNotificationDialog> createState() =>
      _EventChangeNotificationDialogState();
}

class _EventChangeNotificationDialogState
    extends State<EventChangeNotificationDialog> {
  final NotificationService _notificationService = NotificationService();
  bool _isProcessing = false;

  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color accent = Color(0xFFE67E22);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  String get _notificationId =>
      widget.notificationId ?? widget.notification['id'] ?? '';

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);
    try {
      await _notificationService.acceptNotification(_notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci ! Vous êtes toujours inscrit à cet événement.'),
            backgroundColor: success,
          ),
        );
        Navigator.pop(context);
        widget.onDismiss();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = _extractErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCancel() async {
    // Validate that we have the required data
    final reservationId = widget.notification['reservationId'];
    final eventId = widget.notification['eventId'];
    
    if (reservationId == null || eventId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: données manquantes. Veuillez réessayer.'),
            backgroundColor: error,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog — first button dismisses, second proceeds to cancel
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la participation'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler votre participation à cet événement ?',
        ),
        actions: [
          // Dismiss - labelled 'Annuler'
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          // Confirm cancellation - labelled 'Continuer'
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isProcessing = true);
              try {
                await _notificationService.cancelParticipationDueToChanges(
                  notificationId: _notificationId,
                  reservationId: reservationId,
                  eventId: eventId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Participation annulée. Vos places ont été libérées.'),
                      backgroundColor: success,
                    ),
                  );
                  Navigator.pop(context);
                  widget.onDismiss();
                }
              } catch (e) {
                if (mounted) {
                  final errorMessage = _extractErrorMessage(e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: error,
                    ),
                  );
                }
              } finally {
                setState(() => _isProcessing = false);
              }
            },
            child: const Text(
              'Continuer',
              style: TextStyle(color: error),
            ),
          ),
        ],
      ),
    );
  }

  String _extractErrorMessage(dynamic exception) {
    final exceptionString = exception.toString();
    // Extract message from "Exception: message" format
    if (exceptionString.startsWith('Exception: ')) {
      return exceptionString.substring(11);
    }
    return exceptionString.isNotEmpty 
        ? exceptionString 
        : 'Une erreur s\'est produite. Veuillez réessayer.';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp is DateTime) ? timestamp : timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final oldDate = notification['oldDate'];
    final newDate = notification['newDate'];
    final oldLocation = notification['oldLocation'] ?? '';
    final newLocation = notification['newLocation'] ?? '';
    final changeType = (notification['changeType'] ?? 'unknown') as String;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                decoration: const BoxDecoration(
                  color: midnightBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification['title'] ?? 'Notification',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cream,
                            ),
                          ),
                          Text(
                            notification['eventTitle'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: cream),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message with change summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        notification['message'] ?? 'L\'événement a été modifié.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: midnightBlue,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Change details
                    if (changeType.contains('date'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📅 Date modifiée',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: midnightBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Avant : ${_formatDate(oldDate)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 1,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Maintenant : ${_formatDate(newDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    if (changeType.contains('location'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📍 Lieu modifié',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: midnightBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Avant : $oldLocation',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 1,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Maintenant : $newLocation',
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

                                    const SizedBox(height: 24),

                                    // Action buttons or readonly status
                                    Builder(builder: (_) {
                                      final status = (widget.notification['status'] ?? 'pending') as String;
                                      if (status != 'pending') {
                                        // If already handled, show a read-only status and hide buttons
                                        String label;
                                        Color bg;
                                        Color txt;
                                        if (status == 'accepted') {
                                          label = 'Confirmé';
                                          bg = success.withOpacity(0.12);
                                          txt = success;
                                        } else if (status == 'cancelled') {
                                          label = 'Annulé';
                                          bg = error.withOpacity(0.12);
                                          txt = error;
                                        } else {
                                          label = 'En attente';
                                          bg = accent.withOpacity(0.08);
                                          txt = accent;
                                        }
                                        return Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: bg,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                color: txt,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      // Pending: show actionable buttons
                                      return Row(
                                        children: [
                                          // Cancel participation button
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: _isProcessing ? null : _handleCancel,
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                side: const BorderSide(color: error),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text(
                                                'Annuler',
                                                style: TextStyle(
                                                  color: error,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Confirm attendance button
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: _isProcessing ? null : _handleAccept,
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                backgroundColor: success,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: _isProcessing
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<Color>(cream),
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Pas de soucis',
                                                      style: TextStyle(
                                                        color: cream,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
