import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'event_list_page.dart';
import '../organizer/my_events_page.dart';

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

  void _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await _authService.getUserRole(user.uid);
        setState(() {
          _isOrganizer = role == 'organizer';
        });
      } else {
        setState(() {
          _isOrganizer = false;
        });
      }
    } catch (e) {
      setState(() {
        _isOrganizer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOrganizer == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = [
      const EventListPage(),
      if (_isOrganizer == true) const MyEventsPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: _isOrganizer == true
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore),
                  label: 'Découvrir',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event),
                  label: 'Mes événements',
                ),
              ],
            )
          : null,
    );
  }
}
