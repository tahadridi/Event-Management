import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final String organizerId;
  final int numberOfSeats;
  final double totalPrice;
  final String status; // 'Confirmée' or 'Annulée'
  final DateTime createdAt;

  ReservationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    required this.numberOfSeats,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.organizerId = '',
  });

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'userId': userId,
        'userName': userName,
        'numberOfSeats': numberOfSeats,
        'totalPrice': totalPrice,
        'status': status,
        'organizerId': organizerId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ReservationModel.fromDoc(DocumentSnapshot doc) {
  final d = doc.data() as Map<String, dynamic>;
  return ReservationModel(
    id: doc.id,
    eventId: d['eventId'] ?? '',
    eventTitle: d['eventTitle'] ?? '',
    userId: d['userId'] ?? '',
    userName: d['userName'] ?? '',
    numberOfSeats: d['numberOfSeats'] ?? 1,
    totalPrice: (d['totalPrice'] ?? 0).toDouble(),
    status: d['status'] ?? 'confirmed',
    createdAt: (d['createdAt'] as Timestamp).toDate(),
    organizerId: d['organizerId'] ?? '',
  );
}

  // Alias for consistency with other models
  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    return ReservationModel.fromDoc(doc);
  }}