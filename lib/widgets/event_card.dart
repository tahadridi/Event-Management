import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool isFavorite;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isFavorite = false,
  });

  Color get _categoryColor {
    switch (event.category.toLowerCase()) {
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
    switch (event.status) {
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
    final catColor = _categoryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored top banner
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: catColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: category + status + favorite
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isFavorite)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite,
                              size: 14, color: Colors.red),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Date + Location
                  _infoRow(
                    Icons.calendar_month_outlined,
                    DateFormat('EEE dd MMM • HH:mm', 'fr').format(event.date),
                    catColor,
                  ),
                  const SizedBox(height: 6),
                  _infoRow(
                    Icons.location_on_outlined,
                    event.location,
                    catColor,
                  ),

                  const SizedBox(height: 14),

                  // Bottom row: price + places
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: catColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.price == 0
                              ? 'Gratuit'
                              : '${event.price.toStringAsFixed(0)} TND',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      // Places left
                      Row(
                        children: [
                          Icon(
                            event.availablePlaces > 0
                                ? Icons.event_seat_outlined
                                : Icons.block,
                            size: 15,
                            color: event.availablePlaces > 10
                                ? Colors.green
                                : event.availablePlaces > 0
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.availablePlaces == 0
                                ? 'Complet'
                                : '${event.availablePlaces} places',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: event.availablePlaces > 10
                                  ? Colors.green
                                  : event.availablePlaces > 0
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color.withOpacity(0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF555555)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}