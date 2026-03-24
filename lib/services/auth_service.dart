import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    // Sauvegarder le rôle dans Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'role': isOrganizer ? 'organizer' : 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  // Connexion
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Récupérer le rôle de l'utilisateur connecté
  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'user';
  }

  // Stream de l'état de connexion
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}