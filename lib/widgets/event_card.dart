import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final double rating;
  final int reviewCount;
  final bool hasUserReservation;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.rating = 0,
    this.reviewCount = 0,
    this.hasUserReservation = false,
  });

  // Badge status
  String get _badgeText {
    if (hasUserReservation) return 'Réservé';
    if (event.availablePlaces == 0) return 'Complet';
    if (event.availablePlaces <= (event.totalPlaces * 0.2)) return 'Dernières places';
    if (event.availablePlaces < event.totalPlaces) return 'Quelques places';
    return 'Disponible';
  }

  Color get _badgeColor {
    if (hasUserReservation) return const Color(0xFF3B82F6); // Blue for user reservations
    if (event.availablePlaces == 0) return const Color(0xFF6B7280);
    if (event.availablePlaces <= (event.totalPlaces * 0.2)) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  // Color palette - Midnight Blue & Cream
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF0F2A6B);
  static const Color midnightBlueCard = Color(0xFF0C2466);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color creamDark = Color(0xFFE8E0D4);
  static const Color accent = Color(0xFFE67E22); // Warm orange accent
  static const Color accentLight = Color(0xFFF39C12);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color starColor = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat('dd').format(event.date);
    final monthFormat = DateFormat('MMM', 'fr').format(event.date).toUpperCase();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;
    final imageWidth = isSmallScreen ? 100 : 130;
    final imageHeight = isSmallScreen ? 120 : 150;
    final contentPadding = isSmallScreen ? 10.0 : 14.0;
    final titleFontSize = isSmallScreen ? 14.0 : 16.0;
    final subtitleFontSize = isSmallScreen ? 10.0 : 11.0;
    final smallFontSize = isSmallScreen ? 9.0 : 11.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16, vertical: 8),
        child: Material(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top - Image with date badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 140,
                              decoration: BoxDecoration(
                                image: (event.imageUrl?.isNotEmpty ?? false)
                                    ? DecorationImage(
                                        image: NetworkImage(event.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: midnightBlue.withOpacity(0.05),
                              ),
                              child: (event.imageUrl?.isEmpty ?? true)
                                  ? Icon(
                                      Icons.event_rounded,
                                      size: 40,
                                      color: midnightBlue.withOpacity(0.3),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              width: 45,
                              height: 52,
                              decoration: BoxDecoration(
                                color: midnightBlue,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: midnightBlue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayFormat,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    monthFormat,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Status badge - small screen
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _badgeColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _badgeText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Bottom - Content
                      Padding(
                        padding: EdgeInsets.all(contentPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and favorite
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: onFavoriteTap,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 18,
                                      color: isFavorite ? accent : textLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Location
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: TextStyle(
                                      fontSize: smallFontSize,
                                      color: textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Date and time
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd MMM • HH:mm', 'fr')
                                        .format(event.date),
                                    style: TextStyle(
                                      fontSize: smallFontSize - 1,
                                      color: textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Rating and Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (rating > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: starColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 10,
                                          color: starColor,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$rating',
                                          style: TextStyle(
                                            fontSize: smallFontSize - 1,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: midnightBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    event.price == 0
                                        ? 'GRATUIT'
                                        : '${event.price.toStringAsFixed(0)} TND',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: smallFontSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side - Image with date badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            child: Container(
                              width: imageWidth.toDouble(),
                              height: imageHeight.toDouble(),
                              decoration: BoxDecoration(
                                image: (event.imageUrl?.isNotEmpty ?? false)
                                    ? DecorationImage(
                                        image: NetworkImage(event.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: midnightBlue.withOpacity(0.05),
                              ),
                              child: (event.imageUrl?.isEmpty ?? true)
                                  ? Icon(
                                      Icons.event_rounded,
                                      size: 50,
                                      color: midnightBlue.withOpacity(0.3),
                                    )
                                  : null,
                            ),
                          ),
                          // Date badge with midnight blue
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              width: 50,
                              height: 58,
                              decoration: BoxDecoration(
                                color: midnightBlue,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: midnightBlue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayFormat,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    monthFormat,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Status badge - large screen
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _badgeColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _badgeText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Right side - Content
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(contentPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and favorite button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: onFavoriteTap,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 22,
                                        color: isFavorite
                                            ? accent
                                            : textLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 10),
                              
                              // Location
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: TextStyle(
                                        fontSize: smallFontSize,
                                        color: textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Date and time
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy • HH:mm', 'fr')
                                        .format(event.date),
                                    style: TextStyle(
                                      fontSize: smallFontSize,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Rating and Price row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Rating
                                  if (rating > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: starColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 12,
                                            color: starColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$rating',
                                            style: TextStyle(
                                              fontSize: subtitleFontSize,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                          if (reviewCount > 0)
                                            Text(
                                              ' ($reviewCount)',
                                              style: TextStyle(
                                                fontSize: smallFontSize,
                                                color: textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  
                                  // Price Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: midnightBlue,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: midnightBlue.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      event.price == 0
                                          ? 'GRATUIT'
                                          : '${event.price.toStringAsFixed(0)} TND',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: smallFontSize,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}