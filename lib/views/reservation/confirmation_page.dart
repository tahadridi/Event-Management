import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/reservation_model.dart';

// ─────────────────────────────────────────────────────────────
// DESIGN SYSTEM - Midnight Blue & White Theme
// ─────────────────────────────────────────────────────────────

class ConfirmationTheme {
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF1A3A7C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnightBlue, midnightBlueLight],
  );
}

class ConfirmationPage extends StatelessWidget {
  final ReservationModel reservation;

  const ConfirmationPage({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final isFree = reservation.totalPrice == 0;
    final ticketRef = reservation.id.substring(0, 8).toUpperCase();
    final qrData =
        'TICKET:${reservation.id}|EVENT:${reservation.eventId}|USER:${reservation.userId}|SEATS:${reservation.numberOfSeats}|REF:$ticketRef';

    return Scaffold(
      backgroundColor: ConfirmationTheme.cream,
      appBar: AppBar(
        title: const Text(
          'Billet confirmé',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: ConfirmationTheme.midnightBlue,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ConfirmationTheme.success.withOpacity(0.1),
                    ConfirmationTheme.success.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ConfirmationTheme.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ConfirmationTheme.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: ConfirmationTheme.success,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Réservation confirmée !',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ConfirmationTheme.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reservation.eventTitle,
                    style: TextStyle(
                      color: ConfirmationTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Ticket card
            Container(
              decoration: BoxDecoration(
                color: ConfirmationTheme.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Ticket header (midnight blue gradient)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: ConfirmationTheme.primaryGradient,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'E-BILLET',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reservation.eventTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Réf: $ticketRef',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dashed separator
                  _DashedDivider(),

                  // QR Code
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ConfirmationTheme.cream,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: ConfirmationTheme.midnightBlue,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scannez ce QR code pour valider votre billet',
                          style: TextStyle(
                            color: ConfirmationTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Dashed separator
                  _DashedDivider(),

                  // Ticket details
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _ticketRow(
                          Icons.person_outline,
                          'Titulaire',
                          reservation.userName,
                        ),
                        const SizedBox(height: 16),
                        _ticketRow(
                          Icons.event_seat_outlined,
                          'Places',
                          '${reservation.numberOfSeats} place(s)',
                        ),
                        const SizedBox(height: 16),
                        _ticketRow(
                          Icons.payments_outlined,
                          'Montant',
                          isFree
                              ? 'Gratuit'
                              : '${reservation.totalPrice.toStringAsFixed(0)} TND',
                        ),
                        const SizedBox(height: 16),
                        _ticketRow(
                          Icons.access_time,
                          'Réservé le',
                          DateFormat('dd MMM yyyy', 'fr')
                              .format(reservation.createdAt),
                        ),
                        const SizedBox(height: 16),
                        _ticketRow(
                          Icons.check_circle_outline,
                          'Statut',
                          'Confirmé',
                          valueColor: ConfirmationTheme.success,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ConfirmationTheme.midnightBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Retour à l'accueil",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ConfirmationTheme.midnightBlue, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_outline,
                      color: ConfirmationTheme.midnightBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voir mes réservations',
                      style: TextStyle(
                        color: ConfirmationTheme.midnightBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _ticketRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ConfirmationTheme.midnightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: ConfirmationTheme.midnightBlue,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: ConfirmationTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: valueColor ?? ConfirmationTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: ConfirmationTheme.cream,
            shape: BoxShape.circle,
            border: Border.all(color: ConfirmationTheme.midnightBlue.withOpacity(0.2)),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final count = (constraints.maxWidth / 8).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => Container(
                    width: 4,
                    height: 1,
                    color: ConfirmationTheme.midnightBlue.withOpacity(0.2),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: ConfirmationTheme.cream,
            shape: BoxShape.circle,
            border: Border.all(color: ConfirmationTheme.midnightBlue.withOpacity(0.2)),
          ),
        ),
      ],
    );
  }
}