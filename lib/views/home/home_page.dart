import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/notification_badge.dart';
import 'event_list_page.dart';
import '../organizer/my_events_page.dart';
import '../user/profile_page.dart';
import '../user/booking_history_page.dart';
import 'map_page.dart';
import 'calendar_page.dart';

class _NavItem {
  final IconData icon;
  final String label;
  
  _NavItem({required this.icon, required this.label});
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  bool? _isOrganizer;

  // Color palette
  static const Color midnightBlue = Color(0xFF081F5C);
  static const Color cream = Color(0xFFF8F3EA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color creamLight = Color(0xFFFEFAF2);

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await _authService.getUserRole(user.uid);
        if (mounted) setState(() => _isOrganizer = role == 'organizer');
      } else {
        if (mounted) setState(() => _isOrganizer = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isOrganizer = false);
    }
  }

  static const List<Widget> _userPages = [
    EventListPage(),
    BookingHistoryPage(),
    MapPage(),
    CalendarPage(),
    UserProfilePage()
  ];

  static const List<Widget> _organizerPages = [
    EventListPage(),
    BookingHistoryPage(),
    MyEventsPage(),
    MapPage(),
    CalendarPage(),
    UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isOrganizer == null) {
      return const Scaffold(
        backgroundColor: cream,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(midnightBlue),
          ),
        ),
      );
    }

    final pages = _isOrganizer! ? _organizerPages : _userPages;
    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    final navItems = _isOrganizer! ? _organizerNavItems() : _userNavItems();

    return Scaffold(
      backgroundColor: cream,
      body: pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
  child: Container(
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    height: 62,
    decoration: BoxDecoration(
      color: midnightBlue,
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(navItems.length, (index) {
          final isSelected = _selectedIndex == index;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    navItems[index].icon,
                    size: isSelected ? 24 : 20,
                    color: isSelected ? white : white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    navItems[index].label,
                    style: TextStyle(
                      fontSize: isSelected ? 11 : 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? white : white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ),
  ),
),
    );
  }

  List<_NavItem> _userNavItems() => [
        _NavItem(icon: Icons.explore_rounded, label: 'Découvrir'),
        _NavItem(icon: Icons.bookmark_rounded, label: 'Réservations'),
        _NavItem(icon: Icons.map_rounded, label: 'Carte'),
        _NavItem(icon: Icons.calendar_month_rounded, label: 'Calendrier'),
        _NavItem(icon: Icons.person_rounded, label: 'Profil'),
      ];

  List<_NavItem> _organizerNavItems() => [
        _NavItem(icon: Icons.explore_rounded, label: 'Découvrir'),
        _NavItem(icon: Icons.bookmark_rounded, label: 'Réservations'),
        _NavItem(icon: Icons.event_rounded, label: 'Mes événements'),
        _NavItem(icon: Icons.map_rounded, label: 'Carte'),
        _NavItem(icon: Icons.calendar_month_rounded, label: 'Calendrier'),
        _NavItem(icon: Icons.person_rounded, label: 'Profil'),
      ];
}