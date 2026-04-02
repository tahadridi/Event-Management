import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Inscription
  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required bool isOrganizer,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Profil complet avec tous les champs nécessaires
    await _db.collection('users').doc(cred.user!.uid).set({
      'id': cred.user!.uid,
      'name': name,
      'email': email,
      'phone': '',
      'bio': '',
      'profileImageUrl': '',
      'role': isOrganizer ? 'organizer' : 'user',
      'favoriteEventIds': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  // Connexion avec Remember Me
  Future<UserCredential> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    // Note: On mobile platforms, Firebase Auth automatically persists the user
    // session. The rememberMe parameter is handled differently:
    // - On mobile: User stays logged in until explicitly signed out
    // - We'll use SharedPreferences to remember the user's preference
    //   for UI display, but the actual auth state is handled by Firebase
    
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Save remember me preference using SharedPreferences
    // This will be used to determine if we should auto-login on app start
    await _saveRememberMePreference(rememberMe);
    
    return userCredential;
  }

  // Save remember me preference
  Future<void> _saveRememberMePreference(bool rememberMe) async {
    // Using SharedPreferences to store the preference
    // You'll need to add shared_preferences package
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', rememberMe);
  }

  // Check if user wants to stay logged in
  Future<bool> getRememberMePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('remember_me') ?? true; // Default to true
    } catch (e) {
      return true;
    }
  }

  // Envoyer un email de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Aucun utilisateur trouvé avec cet email');
      } else if (e.code == 'invalid-email') {
        throw Exception('Adresse email invalide');
      } else {
        throw Exception('Erreur: ${e.message}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
    // Clear remember me preference on logout
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
  }

  // Récupérer le rôle de l'utilisateur connecté
  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'user';
  }

  // Stream de l'état de connexion
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}