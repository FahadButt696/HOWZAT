// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Login with Email and Password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCred.user;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // Register with Email and Password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCred.user;
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;
}
