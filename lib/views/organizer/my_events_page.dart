import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'create_event_page.dart';
import 'edit_event_page.dart';
import 'organizer_statistics_page.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({Key? key}) : super(key: key);

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Color palette
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color midnightBlueLight = Color(0xFF1A3A7C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color creamDark = Color(0xFFF5EDE2);
  static const Color accent = Color(0xFFE67E22);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? error : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteEvent(EventModel event) async {
    if (!mounted) return;
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        title: const Text(
          'Supprimer l\'événement',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: midnightBlue,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${event.title}"? Cette action ne peut pas être annulée.',
          style: TextStyle(
            color: textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      try {
        await _eventService.deleteEvent(event.id);
        if (mounted) {
          _showSnackBar('Événement supprimé avec succès');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Erreur: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 480;
    
    // Responsive variables - reduced sizes to prevent overflow
    final appBarHeight = isSmallScreen ? 120.0 : 160.0;
    final headerTitleFontSize = isSmallScreen ? 22.0 : 28.0;
    final headerSubtitleFontSize = isSmallScreen ? 11.0 : 13.0;
    final headerPadding = isSmallScreen ? 12.0 : 24.0;
    final headerIconSize = isSmallScreen ? 40.0 : 50.0;
    final headerIconInnerSize = isSmallScreen ? 20.0 : 28.0;
    final listPadding = isSmallScreen ? 12.0 : 20.0;
    final fabFontSize = isSmallScreen ? 11.0 : 14.0;
    
    return Scaffold(
      backgroundColor: cream,
      body: CustomScrollView(
        slivers: [
          // Modern Header - Fixed SliverAppBar
          SliverAppBar(
            expandedHeight: appBarHeight,
            pinned: true,
            backgroundColor: cream,
            foregroundColor: midnightBlue,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cream,
                      creamDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(headerPadding, isSmallScreen ? 30 : 50, headerPadding, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: headerIconSize,
                              height: headerIconSize,
                              decoration: BoxDecoration(
                                color: midnightBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.event_note_rounded,
                                size: headerIconInnerSize,
                                color: midnightBlue,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 10 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mes Événements',
                                    style: TextStyle(
                                      fontSize: headerTitleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: midnightBlue,
                                      letterSpacing: -0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    'Gérez et organisez vos événements',
                                    style: TextStyle(
                                      fontSize: headerSubtitleFontSize,
                                      color: textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: midnightBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.bar_chart_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const OrganizerStatisticsPage(),
                                    ),
                                  );
                                },
                                tooltip: 'Statistiques',
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverFillRemaining(
            hasScrollBody: true,
            child: StreamBuilder<List<EventModel>>(
              stream: _eventService.getOrganizerEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(midnightBlue),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: error.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: 56,
                              color: error,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Oops! Une erreur est survenue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: midnightBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: midnightBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Réessayer',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return _buildEmptyState(isSmallScreen);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  color: midnightBlue,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(listPadding, 8, listPadding, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index * 0.05,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          )),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                            child: _buildModernEventCard(
                              context,
                              event,
                              isSmallScreen,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEventPage(),
            ),
          ).then((_) {
            if (mounted) {
              setState(() {});
            }
          });
        },
        backgroundColor: midnightBlue,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(
          'Créer',
          style: TextStyle(
            fontSize: fabFontSize,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    final iconSize = isSmallScreen ? 50.0 : 70.0;
    final titleFontSize = isSmallScreen ? 18.0 : 24.0;
    final subtitleFontSize = isSmallScreen ? 11.0 : 14.0;
    final buttonFontSize = isSmallScreen ? 13.0 : 16.0;
    final verticalSpacing = isSmallScreen ? 16.0 : 32.0;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 32, vertical: isSmallScreen ? 30 : 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isSmallScreen ? 90 : 140,
              height: isSmallScreen ? 90 : 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    midnightBlue.withOpacity(0.05),
                    midnightBlue.withOpacity(0.02),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: iconSize,
                color: midnightBlue.withOpacity(0.3),
              ),
            ),
            SizedBox(height: verticalSpacing),
            Text(
              'Aucun événement créé',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: midnightBlue,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 12),
            Text(
              'Commencez à créer votre premier événement',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: verticalSpacing),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEventPage(),
                  ),
                ).then((_) {
                  if (mounted) {
                    setState(() {});
                  }
                });
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Créer un événement',
                style: TextStyle(
                  fontSize: buttonFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: midnightBlue,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 32,
                  vertical: isSmallScreen ? 10 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEventCard(
    BuildContext context,
    EventModel event,
    bool isSmallScreen,
  ) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    final DateFormat timeFormat = DateFormat('HH:mm', 'fr_FR');
    
    final isExpired = event.date.isBefore(DateTime.now());
    final isAlmostFull = event.availablePlaces <= (event.totalPlaces * 0.2);
    final occupancyPercentage = ((event.totalPlaces - event.availablePlaces) / event.totalPlaces) * 100;
    
    // Responsive sizes - reduced to prevent overflow
    final heroBgHeight = isSmallScreen ? 100.0 : 140.0;
    final titleFontSize = isSmallScreen ? 16.0 : 20.0;
    final subtitleFontSize = isSmallScreen ? 10.0 : 12.0;
    final statusFontSize = isSmallScreen ? 9.0 : 11.0;
    final chipFontSize = isSmallScreen ? 9.0 : 11.0;
    final occupancyLabelFontSize = isSmallScreen ? 10.0 : 12.0;
    final occupancyPercentFontSize = isSmallScreen ? 10.0 : 12.0;
    final statLabelFontSize = isSmallScreen ? 9.0 : 11.0;
    final statValueFontSize = isSmallScreen ? 13.0 : 16.0;
    final datechipFontSize = isSmallScreen ? 10.0 : 12.0;
    final actionButtonFontSize = isSmallScreen ? 11.0 : 14.0;
    
    // Icon sizes
    final heroIconSize = isSmallScreen ? 8.0 : 12.0;
    final chipIconSize = isSmallScreen ? 10.0 : 12.0;
    final statIconSize = isSmallScreen ? 18.0 : 22.0;
    final dateChipIconSize = isSmallScreen ? 12.0 : 14.0;
    final actionButtonIconSize = isSmallScreen ? 14.0 : 18.0;
    
    // Spacing
    final heroContentPadding = isSmallScreen ? 10.0 : 20.0;
    final statsRowPadding = isSmallScreen ? 8.0 : 16.0;
    final dateChipSpacing = isSmallScreen ? 6.0 : 12.0;
    final contentCardPadding = isSmallScreen ? 12.0 : 20.0;
    final actionButtonSpacing = isSmallScreen ? 6.0 : 12.0;

    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              height: heroBgHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    midnightBlue,
                    midnightBlueLight,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(heroContentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12,
                            vertical: isSmallScreen ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? Colors.white.withOpacity(0.2)
                                : success.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isExpired
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_rounded,
                                size: heroIconSize,
                                color: Colors.white,
                              ),
                              SizedBox(width: isSmallScreen ? 3 : 6),
                              Text(
                                isExpired
                                    ? 'Terminé'
                                    : isAlmostFull
                                        ? 'Complet'
                                        : 'Actif',
                                style: TextStyle(
                                  fontSize: statusFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 10,
                            vertical: isSmallScreen ? 3 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            event.category,
                            style: TextStyle(
                              fontSize: chipFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: isSmallScreen ? 10.0 : 12.0,
                          color: Colors.white70,
                        ),
                        SizedBox(width: isSmallScreen ? 2 : 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(contentCardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateChip(
                          icon: Icons.calendar_today_rounded,
                          label: dateFormat.format(event.date),
                          fontSize: datechipFontSize,
                          iconSize: dateChipIconSize,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      SizedBox(width: dateChipSpacing),
                      Expanded(
                        child: _buildDateChip(
                          icon: Icons.access_time_rounded,
                          label: timeFormat.format(event.date),
                          fontSize: datechipFontSize,
                          iconSize: dateChipIconSize,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isSmallScreen ? 8.0 : 16.0),
                  
                  // Stats Row
                  Container(
                    padding: EdgeInsets.symmetric(vertical: statsRowPadding, horizontal: statsRowPadding),
                    decoration: BoxDecoration(
                      color: cream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildModernStatItem(
                          value: '${event.availablePlaces}',
                          label: 'Places',
                          icon: Icons.people_rounded,
                          color: midnightBlue,
                          valueFont: statValueFontSize,
                          labelFont: statLabelFontSize,
                          iconSize: statIconSize,
                        ),
                        Container(
                          width: 1,
                          height: isSmallScreen ? 25 : 35,
                          color: Colors.grey[300],
                        ),
                        _buildModernStatItem(
                          value: event.price == 0 ? 'Gratuit' : '${event.price} DT',
                          label: 'Prix',
                          icon: Icons.payments_rounded,
                          color: midnightBlue,
                          valueFont: statValueFontSize,
                          labelFont: statLabelFontSize,
                          iconSize: statIconSize,
                        ),
                      ],
                    ),
                  ),
                  
                  if (!isExpired) ...[
                    SizedBox(height: isSmallScreen ? 8.0 : 16.0),
                    
                    // Occupancy Progress
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Occupation',
                              style: TextStyle(
                                fontSize: occupancyLabelFontSize,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${occupancyPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: occupancyPercentFontSize,
                                fontWeight: FontWeight.w600,
                                color: _getOccupancyColor(occupancyPercentage),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: occupancyPercentage / 100,
                            minHeight: isSmallScreen ? 4 : 6,
                            backgroundColor: cream,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getOccupancyColor(occupancyPercentage),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  SizedBox(height: isSmallScreen ? 8.0 : 16.0),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernActionButton(
                          icon: Icons.edit_rounded,
                          label: 'Modifier',
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditEventPage(event: event),
                              ),
                            );
                            if (result == true && mounted) {
                              setState(() {});
                            }
                          },
                          color: midnightBlue,
                          fontSize: actionButtonFontSize,
                          iconSize: actionButtonIconSize,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      SizedBox(width: actionButtonSpacing),
                      Expanded(
                        child: _buildModernActionButton(
                          icon: Icons.delete_rounded,
                          label: 'Supprimer',
                          onPressed: () => _deleteEvent(event),
                          color: error,
                          fontSize: actionButtonFontSize,
                          iconSize: actionButtonIconSize,
                          isDestructive: true,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip({
    required IconData icon,
    required String label,
    required double fontSize,
    required double iconSize,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 5 : 8),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: midnightBlue),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required double valueFont,
    required double labelFont,
    required double iconSize,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: iconSize, color: color.withOpacity(0.7)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFont,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFont,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required double fontSize,
    required double iconSize,
    required bool isSmallScreen,
    bool isDestructive = false,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDestructive
                  ? error.withOpacity(0.3)
                  : color.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: isDestructive ? error : color,
              ),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? error : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getOccupancyColor(double percentage) {
    if (percentage < 30) return success;
    if (percentage < 70) return warning;
    return error;
  }
} 