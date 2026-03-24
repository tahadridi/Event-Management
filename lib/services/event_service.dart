import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Créer un nouvel événement
  Future<void> createEvent({
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime date,
    required TimeOfDay time,
    required int totalPlaces,
    required double price,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Combiner la date et l'heure
      final DateTime eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      // Récupérer les informations de l'organisateur
      final userDoc = await _db.collection('users').doc(currentUser.uid).get();
      final organizerName = userDoc.data()?['name'] ?? 'Organisateur';

      // Créer l'événement
      await _db.collection('events').add({
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'date': Timestamp.fromDate(eventDateTime),
        'totalPlaces': totalPlaces,
        'availablePlaces': totalPlaces,
        'price': price,
        'organizerId': currentUser.uid,
        'organizerName': organizerName,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'événement: $e');
    }
  }

  // Récupérer les événements créés par l'organisateur actuel
  Stream<List<EventModel>> getOrganizerEvents() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _db
        .collection('events')
        .where('organizerId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snap) {
          final events = snap.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();
          // Trier par date (décroissant) dans le code Dart
          events.sort((a, b) => b.date.compareTo(a.date));
          return events;
        });
  }
}