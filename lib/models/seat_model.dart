import 'package:cloud_firestore/cloud_firestore.dart';

class SeatModel {
  final String id;
  final String eventId;
  final String row;
  final int column;
  final String status; // 'available', 'booked', 'reserved'
  final String? bookedBy; // User ID who booked it
  final double price;
  final DateTime? bookedAt;
  final String zone; // 'front' (20% first rows) or 'regular'

  SeatModel({
    required this.id,
    required this.eventId,
    required this.row,
    required this.column,
    required this.status,
    this.bookedBy,
    required this.price,
    this.bookedAt,
    required this.zone,
  });

  // Concatenate row and column for display (e.g., "A1", "B5")
  String get seatNumber => '$row$column';

  // Convertir Firestore → SeatModel
  factory SeatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SeatModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      row: data['row'] ?? '',
      column: data['column'] ?? 0,
      status: data['status'] ?? 'available',
      bookedBy: data['bookedBy'] as String?,
      price: (data['price'] ?? 0).toDouble(),
      bookedAt: data['bookedAt'] != null
          ? (data['bookedAt'] as Timestamp).toDate()
          : null,
      zone: data['zone'] ?? 'regular',
    );
  }

  // Convertir SeatModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'row': row,
      'column': column,
      'status': status,
      'bookedBy': bookedBy,
      'price': price,
      'bookedAt': bookedAt != null ? Timestamp.fromDate(bookedAt!) : null,
      'zone': zone,
    };
  }

  // Copy with updated status
  SeatModel copyWith({
    String? status,
    String? bookedBy,
    DateTime? bookedAt,
    String? zone,
  }) {
    return SeatModel(
      id: id,
      eventId: eventId,
      row: row,
      column: column,
      status: status ?? this.status,
      bookedBy: bookedBy ?? this.bookedBy,
      price: price,
      bookedAt: bookedAt ?? this.bookedAt,
      zone: zone ?? this.zone,
    );
  }
}
