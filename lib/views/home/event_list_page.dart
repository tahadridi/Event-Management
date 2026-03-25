import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/user_service.dart';
import '../../widgets/event_card.dart';
import 'event_detail_page.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final eventService = EventService();
  final userService = UserService();
  Set<String> _userFavorites = {};

  @override
  void initState() {
    super.initState();
    _loadUserFavorites();
  }

  Future<void> _loadUserFavorites() async {
    try {
      final favorites = await userService.getUserFavoritesStream().first;
      if (mounted) {
        setState(() => _userFavorites = Set.from(favorites));
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Découvrir'),
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
          
          var events = snapshot.data!;
          
          // Trier pour mettre les favoris en haut
          events.sort((a, b) {
            final aIsFav = _userFavorites.contains(a.id);
            final bIsFav = _userFavorites.contains(b.id);
            if (aIsFav && !bIsFav) return -1;
            if (!aIsFav && bIsFav) return 1;
            return 0;
          });
          
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isFav = _userFavorites.contains(event.id);
              return EventCard(
                event: event,
                isFavorite: isFav,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailPage(event: event),
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