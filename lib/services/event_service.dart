import 'dart:math';
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

  // Rechercher les événements avec filtres
  Future<List<EventModel>> searchEvents({
    String? searchQuery,
    String? category,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query =
          _db.collection('events').where('date', isGreaterThan: Timestamp.now());

      // Appliquer le filtre de catégorie
      if (category != null && category.isNotEmpty && category != 'Tous') {
        query = query.where('category', isEqualTo: category);
      }

      // Appliquer le filtre de date de début
      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      // Appliquer le filtre de date de fin
      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      var events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Appliquer le filtre de prix en Dart (Firestore ne supporte pas bien les plages)
      if (minPrice != null || maxPrice != null) {
        events = events.where((event) {
          final price = event.price;
          if (minPrice != null && price < minPrice) return false;
          if (maxPrice != null && price > maxPrice) return false;
          return true;
        }).toList();
      }

      // Appliquer la recherche par texte
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        events = events.where((event) {
          return event.title.toLowerCase().contains(query) ||
              event.description.toLowerCase().contains(query) ||
              event.location.toLowerCase().contains(query);
        }).toList();
      }

      // Trier par date
      events.sort((a, b) => a.date.compareTo(b.date));

      return events;
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Récupérer les événements par catégorie
  Stream<List<EventModel>> getEventsByCategory(String category) {
    return _db
        .collection('events')
        .where('date', isGreaterThan: Timestamp.now())
        .where('category', isEqualTo: category)
        .orderBy('date')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // Récupérer les événements gratuits
  Stream<List<EventModel>> getFreeEvents() {
    return _db
        .collection('events')
        .where('date', isGreaterThan: Timestamp.now())
        .where('price', isEqualTo: 0)
        .orderBy('date')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // Récupérer les événements à proximité
  Stream<List<EventModel>> getNearbyEvents(
      {required double latitude, required double longitude, required double radius}) {
    return getEvents().map((events) {
      return events.where((event) {
        final distance = _calculateDistance(latitude, longitude,
            event.latitude, event.longitude);
        return distance <= radius;
      }).toList();
    });
  }

  // Calculer la distance entre deux coordonnées
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Supprimer un événement
  Future<void> deleteEvent(String eventId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final eventDoc = await _db.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Événement non trouvé');
      }

      final event = EventModel.fromFirestore(eventDoc);
      if (event.organizerId != currentUser.uid) {
        throw Exception('Vous n\'êtes pas autorisé à supprimer cet événement');
      }

      await _db.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // Mettre à jour le statut d'un événement
  Future<void> updateEventStatus(String eventId, String status) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final eventDoc = await _db.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Événement non trouvé');
      }

      final event = EventModel.fromFirestore(eventDoc);
      if (event.organizerId != currentUser.uid) {
        throw Exception('Vous n\'êtes pas autorisé à modifier cet événement');
      }

      await _db
          .collection('events')
          .doc(eventId)
          .update({'status': status});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // Mettre à jour un événement complet
  Future<void> updateEvent({
    required String eventId,
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

      final eventDoc = await _db.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Événement non trouvé');
      }

      final event = EventModel.fromFirestore(eventDoc);
      if (event.organizerId != currentUser.uid) {
        throw Exception(
            'Vous n\'êtes pas autorisé à modifier cet événement');
      }

      // Combiner la date et l'heure
      final DateTime eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      await _db.collection('events').doc(eventId).update({
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'date': Timestamp.fromDate(eventDateTime),
        'totalPlaces': totalPlaces,
        'price': price,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'événement: $e');
    }
  }
}

