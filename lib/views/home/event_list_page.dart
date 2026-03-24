import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../widgets/event_card.dart';
import 'event_detail_page.dart';
class EventListPage extends StatelessWidget {
  const EventListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Bouton temporaire pour ajouter un événement test
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await eventService.addTestEvent();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Événement test ajouté !')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: eventService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun événement pour le moment',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              return EventCard(
                event: events[index],
                onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(event: events[index]),
                      ),
                    );
                  },
              );
            },
          );
        },
      ),
    );
  }
}