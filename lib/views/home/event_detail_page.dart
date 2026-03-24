import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';

class EventDetailPage extends StatelessWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec image de fond colorée
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                event.title,
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

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Catégorie
                  Row(
                    children: [
                      Chip(
                        label: Text(event.category),
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
                          event.status,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Infos principales
                  _infoRow(Icons.calendar_today,
                      DateFormat('EEEE dd MMMM yyyy • HH:mm', 'fr')
                          .format(event.date)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.location_on, event.location),
                  const SizedBox(height: 12),
                  _infoRow(Icons.person, 'Organisé par ${event.organizerName}'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.people,
                      '${event.availablePlaces} / ${event.totalPlaces} places disponibles'),

                  const Divider(height: 32),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
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
                            event.price == 0
                                ? 'Gratuit'
                                : '${event.price.toStringAsFixed(0)} TND',
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
                          onPressed: event.availablePlaces == 0
                              ? null
                              : () {
                                  // Navigation vers réservation (prochaine phase)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Réservation bientôt disponible !')),
                                  );
                                },
                          icon: const Icon(Icons.bookmark_add),
                          label: Text(event.availablePlaces == 0
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
              style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ),
      ],
    );
  }
}