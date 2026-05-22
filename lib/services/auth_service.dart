import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Convertir les erreurs Firebase en messages utilisateur-friendly
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé. Veuillez vous connecter ou utiliser un autre email.';
      case 'weak-password':
        return 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
      case 'invalid-email':
        return 'Adresse email invalide. Veuillez vérifier.';
      case 'user-disabled':
        return 'Ce compte a été désactivé. Contactez le support.';
      case 'user-not-found':
        return 'Cet email n\'existe pas. Veuillez vous inscrire.';
      case 'wrong-password':
        return 'Mot de passe incorrect. Réessayez.';
      case 'operation-not-allowed':
        return 'Cette opération n\'est pas autorisée. Contactez le support.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cet email.';
      default:
        return 'Une erreur s\'est produite. Veuillez réessayer.';
    }
  }

  // Inscription
  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required bool isOrganizer,
  }) async {
    try {
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
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      throw Exception('Une erreur s\'est produite lors de l\'inscription.');
    }
  }

  // Connexion avec Remember Me
  Future<UserCredential> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
   
    
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save remember me preference using SharedPreferences
      // This will be used to determine if we should auto-login on app start
      await _saveRememberMePreference(rememberMe);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      throw Exception('Une erreur s\'est produite lors de la connexion.');
    }
  }

  // Connexion avec Google
  Future<UserCredential> signInWithGoogle({bool rememberMe = true}) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Connexion Google annulée');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception(
          'Google a retourné des identifiants incomplets. Vérifiez la configuration SHA-1/SHA-256 Android dans Firebase.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _saveRememberMePreference(rememberMe);
      await _ensureUserProfile(userCredential.user);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception('Google auth (${e.code}): ${e.message ?? _getErrorMessage(e)}');
    } on PlatformException catch (e) {
      throw Exception('Google platform (${e.code}): ${e.message ?? e.details ?? 'Erreur inconnue'}');
    } catch (e) {
      throw Exception('Google sign-in error: $e');
    }
  }

  Future<void> _ensureUserProfile(User? user) async {
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email?.split('@').first ?? 'Utilisateur');

    final data = <String, dynamic>{
      'id': user.uid,
      'name': displayName,
      'email': user.email ?? '',
      'phone': doc.data()?['phone'] ?? '',
      'bio': doc.data()?['bio'] ?? '',
      'profileImageUrl': user.photoURL ?? doc.data()?['profileImageUrl'] ?? '',
      'role': doc.data()?['role'] ?? 'user',
      'favoriteEventIds': doc.data()?['favoriteEventIds'] ?? [],
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!doc.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await userRef.set(data, SetOptions(merge: true));
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
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      throw Exception('Une erreur s\'est produite. Veuillez réessayer.');
    }
  }

  // Vérifie si l'email est déjà associé à un compte Firebase Auth
  Future<bool> emailHasAuthAccount(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } on FirebaseAuthException {
      return false;
    } catch (_) {
      return false;
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

  // Changer le mot de passe
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Créer une nouvelle authentification avec le mot de passe actuel
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Réauthentifier l'utilisateur
      await user.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e));
    } catch (e) {
      throw Exception('Une erreur s\'est produite. Veuillez réessayer.');
    }
  }
}