import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/review_service.dart';

class ReviewsList extends StatelessWidget {
  final String eventId;

  const ReviewsList({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final reviewService = ReviewService();

    return StreamBuilder(
      stream: reviewService.getEventReviews(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Aucun avis pour le moment',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final reviews = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            Icons.star,
                            size: 16,
                            color: i < review.rating
                                ? Colors.amber
                                : Colors.grey.shade300,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.comment,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy', 'fr').format(review.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}