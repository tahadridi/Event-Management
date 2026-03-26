import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/notification_badge.dart';
import 'event_list_page.dart';
import '../organizer/my_events_page.dart';
import '../user/profile_page.dart';
import '../user/booking_history_page.dart';
import '../home/map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;
  bool? _isOrganizer;

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

  // USER: Découvrir · Réservations · Profil
  static const List<Widget> _userPages = [
    EventListPage(),
    BookingHistoryPage(),
    MapPage(),
    UserProfilePage()
    
    
  ];

  // ORGANIZER: Découvrir · Réservations · Mes événements · Profil
  static const List<Widget> _organizerPages = [
    EventListPage(),
    BookingHistoryPage(),
    MyEventsPage(),
    MapPage(),
    UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isOrganizer == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final pages = _isOrganizer! ? _organizerPages : _userPages;
    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _isOrganizer! ? _organizerNavItems() : _userNavItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _userNavItems() => const [
        BottomNavigationBarItem(
            icon: Icon(Icons.explore), label: 'Découvrir'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bookmark), label: 'Réservations'),
        BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),label: 'Carte'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Profil')
       
     
      ];

  List<BottomNavigationBarItem> _organizerNavItems() => const [
        BottomNavigationBarItem(
            icon: Icon(Icons.explore), label: 'Découvrir'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bookmark), label: 'Réservations'),
        BottomNavigationBarItem(
            icon: Icon(Icons.event), label: 'Mes événements'),
        BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),label: 'Carte'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Profil'),
      ];
}