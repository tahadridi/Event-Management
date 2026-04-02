import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime date;
  final int totalPlaces;
  final int availablePlaces;
  final double price;
  final String organizerId;
  final String organizerName;
  final String? imageUrl;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.totalPlaces,
    required this.availablePlaces,
    required this.price,
    required this.organizerId,
    required this.organizerName,
    this.imageUrl,
  });

  // Convertir Firestore → EventModel
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      totalPlaces: data['totalPlaces'] ?? 0,
      availablePlaces: data['availablePlaces'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      imageUrl: data['imageUrl'] as String?,
    );
  }

  // Convertir EventModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'date': Timestamp.fromDate(date),
      'totalPlaces': totalPlaces,
      'availablePlaces': availablePlaces,
      'price': price,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'imageUrl': imageUrl,
    };
  }

  String get status {
    if (availablePlaces == 0) return 'Complet';
    if (availablePlaces < totalPlaces * 0.2) return 'En attente';
    return 'Disponible';
  }
}