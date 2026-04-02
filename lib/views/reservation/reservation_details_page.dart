import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/reservation_model.dart';

// ─────────────────────────────────────────────────────────────
// DESIGN SYSTEM - Midnight Blue & Cream Theme
// ─────────────────────────────────────────────────────────────

class ReservationTheme {
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF1A3A7C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnightBlue, midnightBlueLight],
  );
}

class ReservationDetailsPage extends StatelessWidget {
  final ReservationModel reservation;

  const ReservationDetailsPage({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;
    final isFree = reservation.totalPrice == 0;
    final ticketRef = reservation.id.substring(0, 8).toUpperCase();
    final qrData =
        'TICKET:${reservation.id}|EVENT:${reservation.eventId}|USER:${reservation.userId}|SEATS:${reservation.numberOfSeats}|REF:$ticketRef';

    // Responsive sizes
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
    final verticalPadding = isSmallScreen ? 16.0 : 20.0;
    final qrSize = isSmallScreen ? 160.0 : 200.0;
    final headerPadding = isSmallScreen ? 16.0 : 24.0;
    final contentPadding = isSmallScreen ? 16.0 : 24.0;
    final titleFontSize = isSmallScreen ? 18.0 : 22.0;
    final headerFontSize = isSmallScreen ? 16.0 : 18.0;
    final detailFontSize = isSmallScreen ? 13.0 : 14.0;
    final labelFontSize = isSmallScreen ? 12.0 : 13.0;
    final iconSize = isSmallScreen ? 18.0 : 20.0;
    final buttonPadding = isSmallScreen ? 12.0 : 16.0;
    final buttonFontSize = isSmallScreen ? 14.0 : 16.0;

    // Determine status
    final isConfirmed = reservation.status.toLowerCase() == 'confirmed' ||
        reservation.status.toLowerCase() == 'confirmée';
    final isCancelled = reservation.status.toLowerCase() == 'cancelled' ||
        reservation.status.toLowerCase() == 'annulée';
    final isPast = reservation.createdAt.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    Color statusColor;
    Color statusBgColor;
    String displayStatus;
    IconData statusIcon;

    if (isCancelled) {
      statusColor = ReservationTheme.error;
      statusBgColor = ReservationTheme.error.withOpacity(0.1);
      displayStatus = 'Annulée';
      statusIcon = Icons.cancel_rounded;
    } else if (isConfirmed && isPast) {
      statusColor = ReservationTheme.textSecondary;
      statusBgColor = ReservationTheme.textSecondary.withOpacity(0.1);
      displayStatus = 'Terminée';
      statusIcon = Icons.check_circle_rounded;
    } else if (isConfirmed) {
      statusColor = ReservationTheme.success;
      statusBgColor = ReservationTheme.success.withOpacity(0.1);
      displayStatus = 'Confirmée';
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = ReservationTheme.warning;
      statusBgColor = ReservationTheme.warning.withOpacity(0.1);
      displayStatus = 'En attente';
      statusIcon = Icons.pending_rounded;
    }

    return Scaffold(
      backgroundColor: ReservationTheme.cream,
      appBar: AppBar(
        title: Text(
          'Détails de la réservation',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: ReservationTheme.midnightBlue,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            child: Column(
              children: [
                // Ticket Card
                Container(
                  decoration: BoxDecoration(
                    color: ReservationTheme.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Ticket header
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(headerPadding),
                        decoration: BoxDecoration(
                          gradient: ReservationTheme.primaryGradient,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        statusIcon,
                                        size: 12,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        displayStatus,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: isSmallScreen ? 10 : 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'E-BILLET',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isSmallScreen ? 9 : 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              reservation.eventTitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Réf: $ticketRef',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dashed separator
                      _DashedDivider(isSmallScreen: isSmallScreen),

                      // QR Code
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 16 : 20,
                          horizontal: isSmallScreen ? 12 : 16,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ReservationTheme.cream,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: qrSize,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: ReservationTheme.midnightBlue,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF2D2D2D),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Présentez ce QR code à l\'entrée',
                              style: TextStyle(
                                color: ReservationTheme.textSecondary,
                                fontSize: isSmallScreen ? 11 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Dashed separator
                      _DashedDivider(isSmallScreen: isSmallScreen),

                      // Ticket details
                      Padding(
                        padding: EdgeInsets.all(contentPadding),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.person_outline_rounded,
                              'Titulaire',
                              reservation.userName,
                              iconSize: iconSize,
                              labelFontSize: labelFontSize,
                              valueFontSize: detailFontSize,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.event_seat_outlined,
                              'Places',
                              '${reservation.numberOfSeats} place${reservation.numberOfSeats > 1 ? 's' : ''}',
                              iconSize: iconSize,
                              labelFontSize: labelFontSize,
                              valueFontSize: detailFontSize,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.payments_outlined,
                              'Prix total',
                              isFree
                                  ? 'Gratuit'
                                  : '${reservation.totalPrice.toStringAsFixed(0)} TND',
                              isHighlight: true,
                              iconSize: iconSize,
                              labelFontSize: labelFontSize,
                              valueFontSize: detailFontSize,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.access_time_rounded,
                              'Réservé le',
                              DateFormat('dd MMM yyyy', 'fr')
                                  .format(reservation.createdAt),
                              iconSize: iconSize,
                              labelFontSize: labelFontSize,
                              valueFontSize: detailFontSize,
                            ),
                            if (isConfirmed && !isPast)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _buildDetailRow(
                                  Icons.check_circle_outline_rounded,
                                  'Statut',
                                  'Confirmé',
                                  valueColor: ReservationTheme.success,
                                  iconSize: iconSize,
                                  labelFontSize: labelFontSize,
                                  valueFontSize: detailFontSize,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ReservationTheme.midnightBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: buttonPadding),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_rounded,
                              size: buttonFontSize - 2,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Retour à l'accueil",
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: ReservationTheme.midnightBlue,
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(vertical: buttonPadding),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_outline_rounded,
                              color: ReservationTheme.midnightBlue,
                              size: buttonFontSize - 2,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Voir mes réservations',
                              style: TextStyle(
                                color: ReservationTheme.midnightBlue,
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isHighlight = false,
    Color? valueColor,
    required double iconSize,
    required double labelFontSize,
    required double valueFontSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ReservationTheme.midnightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: ReservationTheme.midnightBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: ReservationTheme.textSecondary,
              fontSize: labelFontSize,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              fontSize: valueFontSize,
              color: valueColor ?? ReservationTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dashed Divider Widget
// ─────────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  final bool isSmallScreen;
  
  const _DashedDivider({required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final circleSize = isSmallScreen ? 12.0 : 14.0;
    final dashWidth = isSmallScreen ? 2.0 : 3.0;
    final dashSpacing = isSmallScreen ? 4.0 : 6.0;
    
    return Row(
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: ReservationTheme.cream,
            shape: BoxShape.circle,
            border: Border.all(
              color: ReservationTheme.midnightBlue.withOpacity(0.2),
              width: 1.5,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final count = (constraints.maxWidth / dashSpacing).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => Container(
                    width: dashWidth,
                    height: 1,
                    color: ReservationTheme.midnightBlue.withOpacity(0.2),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: ReservationTheme.cream,
            shape: BoxShape.circle,
            border: Border.all(
              color: ReservationTheme.midnightBlue.withOpacity(0.2),
              width: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}