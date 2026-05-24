import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Manages Firebase Authentication state.
/// Mirrors AuthService.swift — anonymous sign-in, email sign-in/up,
/// link credential, sign out.
class AuthService extends ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  String? get uid => _user?.uid;
  bool get isAnonymous => _user?.isAnonymous ?? true;

  AuthService() {
    _setupAuthStateListener();
  }

  void _setupAuthStateListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      _isAuthenticated = user != null;
      notifyListeners();
    });
  }

  // ─── Sign In ───────────────────────────────

  Future<void> signInAnonymously() async {
    final result = await FirebaseAuth.instance.signInAnonymously();
    _user = result.user;
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _user = result.user;
    notifyListeners();
  }

  Future<void> signUpWithEmail(String email, String password) async {
    final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    _user = result.user;
    notifyListeners();
  }

  // ─── Link Anonymous → Permanent ───────────

  Future<void> linkEmail(String email, String password) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
    notifyListeners();
  }

  // ─── Sign Out ──────────────────────────────

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await FirebaseAuth.instance.currentUser?.delete();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
