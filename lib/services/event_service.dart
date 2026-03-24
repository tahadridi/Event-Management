import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Récupérer tous les événements à venir
  Stream<List<EventModel>> getEvents() {
    return _db
        .collection('events')
        .where('date', isGreaterThan: Timestamp.now())
        .orderBy('date')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // Ajouter un événement test (pour tester sans formulaire)
  Future<void> addTestEvent() async {
    await _db.collection('events').add({
      'title': 'Concert Jazz Tunis',
      'description': 'Un superbe concert de jazz au coeur de Tunis.',
      'category': 'Musique',
      'location': 'Tunis, Tunisie',
      'latitude': 36.8065,
      'longitude': 10.1815,
      'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7))),
      'totalPlaces': 100,
      'availablePlaces': 100,
      'price': 25.0,
      'organizerId': 'test',
      'organizerName': 'Organisateur Test',
    });
  }
}