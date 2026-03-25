import 'package:flutter/material.dart';
import '../services/review_service.dart';

class AddReviewSheet extends StatefulWidget {
  final String eventId;
  final String userName;
  final VoidCallback onReviewSubmitted;

  const AddReviewSheet({
    super.key,
    required this.eventId,
    required this.userName,
    required this.onReviewSubmitted,
  });

  @override
  State<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<AddReviewSheet> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez écrire un commentaire')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _reviewService.addReview(
        eventId: widget.eventId,
        rating: _selectedRating,
        comment: _reviewController.text.trim(),
        userName: widget.userName,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre
            const Text(
              'Donner votre avis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Étoiles
            const Text(
              'Note',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return GestureDetector(
                  // ← setState ici ne touche QUE ce widget
                  onTap: () => setState(() => _selectedRating = index + 1),
                  child: Icon(
                    Icons.star,
                    size: 44,
                    color: index < _selectedRating
                        ? Colors.amber
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Commentaire
            const Text(
              'Commentaire',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Partagez votre expérience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bouton publier
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Publication...' : 'Publier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}