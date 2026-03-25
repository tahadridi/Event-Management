import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Réservations à venir
Stream<List<Map<String, dynamic>>> getUpcomingReservations() {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return Stream.value([]);

  return _db
      .collection('reservations')
      .where('userId', isEqualTo: userId)
      // ← pas de orderBy ici
      .snapshots()
      .asyncMap((snapshot) => _enrichReservations(
            snapshot.docs,
            filterFuture: true,
            filterConfirmed: true,
          ));
}

  // Historique complet
Stream<List<Map<String, dynamic>>> getUserBookingHistory() {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return Stream.value([]);

  return _db
      .collection('reservations')
      .where('userId', isEqualTo: userId)
      
      .snapshots()
      .asyncMap((snapshot) => _enrichReservations(snapshot.docs));
}

  // Méthode commune — récupère les events en une seule fois
  Future<List<Map<String, dynamic>>> _enrichReservations(
  List<QueryDocumentSnapshot> docs, {
  bool filterFuture = false,
  bool filterConfirmed = false,
}) async {
  if (docs.isEmpty) return [];

  final eventIds = docs
      .map((doc) => (doc.data() as Map<String, dynamic>)['eventId'] as String)
      .toSet()
      .toList();

  final eventSnaps = await Future.wait(
    eventIds.map((id) => _db.collection('events').doc(id).get()),
  );

  final eventMap = <String, EventModel>{};
  for (final snap in eventSnaps) {
    if (snap.exists) {
      eventMap[snap.id] = EventModel.fromFirestore(snap);
    }
  }

  final result = <Map<String, dynamic>>[];
  for (final doc in docs) {
    final reservation = ReservationModel.fromFirestore(doc);
    final event = eventMap[reservation.eventId];
    if (event == null) continue;

    // Filtre les événements futurs
    if (filterFuture && event.date.isBefore(DateTime.now())) continue;

    // Filtre les réservations confirmées (accepte les 2 valeurs possibles)
    if (filterConfirmed) {
      final status = reservation.status.toLowerCase();
      if (status != 'confirmed' && status != 'confirmée') continue;
    }

    result.add({'reservation': reservation, 'event': event});
  }

  // Tri par date de création décroissant côté Dart
  result.sort((a, b) {
    final resA = a['reservation'] as ReservationModel;
    final resB = b['reservation'] as ReservationModel;
    return resB.createdAt.compareTo(resA.createdAt);
  });

  return result;
}

  // Annuler une réservation
  Future<bool> cancelReservation(String reservationId) async {
    try {
      final reservationDoc =
          await _db.collection('reservations').doc(reservationId).get();
      if (!reservationDoc.exists) throw Exception('Réservation introuvable');

      final reservation = ReservationModel.fromFirestore(reservationDoc);

      // Remettre les places disponibles
      await _db.collection('events').doc(reservation.eventId).update({
        'availablePlaces': FieldValue.increment(reservation.numberOfSeats),
      });

      // Mettre à jour le statut à 'Annulée' au lieu de supprimer
      await _db.collection('reservations').doc(reservationId).update({
        'status': 'Annulée',
      });
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Modifier le nombre de places
  Future<bool> updateReservation({
    required String reservationId,
    required int newNumberOfSeats,
  }) async {
    try {
      final reservationDoc =
          await _db.collection('reservations').doc(reservationId).get();
      if (!reservationDoc.exists) throw Exception('Réservation introuvable');

      final reservation = ReservationModel.fromFirestore(reservationDoc);
      final oldSeats = reservation.numberOfSeats;
      final diff = oldSeats - newNumberOfSeats;
      final pricePerSeat = reservation.totalPrice / oldSeats;

      await _db.collection('reservations').doc(reservationId).update({
        'numberOfSeats': newNumberOfSeats,
        'totalPrice': newNumberOfSeats * pricePerSeat,
      });

      await _db.collection('events').doc(reservation.eventId).update({
        'availablePlaces': FieldValue.increment(diff),
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Pour l'organisateur
  Stream<List<Map<String, dynamic>>> getOrganizerReservations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('reservations')
        .where('organizerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) => _enrichReservations(snapshot.docs));
  }
}