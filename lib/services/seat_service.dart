import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seat_model.dart';

class SeatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create seats for an event with two different prices (front and regular zones)
  Future<void> createSeatsForEvent({
    required String eventId,
    required int numberOfRows,
    required int seatsPerRow,
    required double frontSeatPrice,
    required double regularSeatPrice,
  }) async {
    final batch = _db.batch();
    
    // Limit seats per row to maximum 20
    final effectiveSeatsPerRow = seatsPerRow > 20 ? 20 : seatsPerRow;
    
    // Generate row letters (A, B, C, ... up to Z)
    const rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
    
    // Calculate front zone (20% of rows)
    final frontRowCount = (numberOfRows * 0.2).ceil();
    
    for (int row = 0; row < numberOfRows; row++) {
      for (int column = 1; column <= effectiveSeatsPerRow; column++) {
        final seatRef = _db.collection('events').doc(eventId).collection('seats').doc();
        
        // Determine zone: first 20% rows are front, rest are regular
        final isFrontZone = row < frontRowCount;
        final price = isFrontZone ? frontSeatPrice : regularSeatPrice;
        final zone = isFrontZone ? 'front' : 'regular';
        
        final seat = SeatModel(
          id: seatRef.id,
          eventId: eventId,
          row: rows[row],
          column: column,
          status: 'available',
          price: price,
          zone: zone,
        );
        batch.set(seatRef, seat.toMap());
      }
    }
    
    await batch.commit();
  }

  // Get all seats for an event
  Future<List<SeatModel>> getSeatsByEvent(String eventId) async {
    final snapshot = await _db
        .collection('events')
        .doc(eventId)
        .collection('seats')
        .get(); // No orderBy to avoid index issues
    
    // Sort in code instead
    final seats = snapshot.docs.map((doc) => SeatModel.fromFirestore(doc)).toList();
    seats.sort((a, b) {
      final rowCompare = a.row.compareTo(b.row);
      if (rowCompare != 0) return rowCompare;
      return a.column.compareTo(b.column);
    });
    return seats;
  }

  // Get available seats for an event
  Future<List<SeatModel>> getAvailableSeats(String eventId) async {
    final snapshot = await _db
        .collection('events')
        .doc(eventId)
        .collection('seats')
        .get(); // No where/orderBy to avoid index issues
    
    // Filter and sort in code instead
    final seats = snapshot.docs
        .map((doc) => SeatModel.fromFirestore(doc))
        .where((seat) => seat.status == 'available')
        .toList();
    
    seats.sort((a, b) {
      final rowCompare = a.row.compareTo(b.row);
      if (rowCompare != 0) return rowCompare;
      return a.column.compareTo(b.column);
    });
    return seats;
  }

  // Book seats
  Future<void> bookSeats({
    required String eventId,
    required List<String> seatIds,
    required String userId,
  }) async {
    final batch = _db.batch();
    
    for (final seatId in seatIds) {
      final seatRef = _db
          .collection('events')
          .doc(eventId)
          .collection('seats')
          .doc(seatId);
      
      batch.update(seatRef, {
        'status': 'booked',
        'bookedBy': userId,
        'bookedAt': Timestamp.now(),
      });
    }
    
    await batch.commit();
  }

  // Get seat details
  Future<SeatModel?> getSeat(String eventId, String seatId) async {
    final doc = await _db
        .collection('events')
        .doc(eventId)
        .collection('seats')
        .doc(seatId)
        .get();
    
    if (!doc.exists) return null;
    return SeatModel.fromFirestore(doc);
  }

  // Get seats by IDs
  Future<List<SeatModel>> getSeatsByIds({
    required String eventId,
    required List<String> seatIds,
  }) async {
    if (seatIds.isEmpty) return [];
    
    final snapshot = await _db
        .collection('events')
        .doc(eventId)
        .collection('seats')
        .where(FieldPath.documentId, whereIn: seatIds)
        .get();
    
    return snapshot.docs.map((doc) => SeatModel.fromFirestore(doc)).toList();
  }

  // Cancel seat booking (revert to available)
  Future<void> cancelSeatBooking({
    required String eventId,
    required List<String> seatIds,
  }) async {
    final batch = _db.batch();
    
    for (final seatId in seatIds) {
      final seatRef = _db
          .collection('events')
          .doc(eventId)
          .collection('seats')
          .doc(seatId);
      
      batch.update(seatRef, {
        'status': 'available',
        'bookedBy': null,
        'bookedAt': null,
      });
    }
    
    await batch.commit();
  }

  // Stream of seats for real-time updates
  Stream<List<SeatModel>> watchSeats(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .collection('seats')
        .snapshots()
        .map((snapshot) {
          final seats = snapshot.docs
              .map((doc) => SeatModel.fromFirestore(doc))
              .toList();
          // Sort in code to avoid index issues
          seats.sort((a, b) {
            final rowCompare = a.row.compareTo(b.row);
            if (rowCompare != 0) return rowCompare;
            return a.column.compareTo(b.column);
          });
          return seats;
        });
  }

  // Delete all seats for an event
  Future<void> deleteSeatsForEvent(String eventId) async {
    final snapshot = await _db
        .collection('events')
        .doc(eventId)
        .collection('seats')
        .get();
    
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}
