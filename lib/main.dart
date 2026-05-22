import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'views/auth/login_page.dart';
import 'views/home/home_page.dart';
import 'services/auth_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr', null);
  
  // Initialize local notifications
  final notificationService = NotificationService();
  await notificationService.initializeLocalNotifications();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reservi Events',
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('fr')],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  late final Future<bool> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrapAuthState();
  }

  Future<bool> _bootstrapAuthState() async {
    final rememberMe = await _authService.getRememberMePreference();
    if (!rememberMe && FirebaseAuth.instance.currentUser != null) {
      await _authService.logout();
    }
    return rememberMe;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        final rememberMe = snapshot.data ?? true;

        if (currentUser != null && rememberMe) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}