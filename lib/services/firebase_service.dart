import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

/// Generic Firestore CRUD helper — all operations scoped to users/{uid}/.
/// Mirrors FirebaseService.swift.
class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collection Reference ─────────────────

  CollectionReference<Map<String, dynamic>> userCollection(String name) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw YNABError.notAuthenticated;
    return _db.collection('users').doc(uid).collection(name);
  }

  DocumentReference<Map<String, dynamic>> userDocument(
      String collection, String docId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw YNABError.notAuthenticated;
    return _db.collection('users').doc(uid).collection(collection).doc(docId);
  }

  // ─── Create ───────────────────────────────

  Future<String> add(Map<String, dynamic> data, String collection) async {
    final ref = await userCollection(collection).add(data);
    return ref.id;
  }

  // ─── Read ─────────────────────────────────

  Future<List<Map<String, dynamic>>> fetch(String collection) async {
    final snapshot = await userCollection(collection).get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  Future<Map<String, dynamic>?> fetchDocument(
      String collection, String id) async {
    final doc = await userCollection(collection).doc(id).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  // ─── Update ───────────────────────────────

  Future<void> update(
      Map<String, dynamic> data, String collection, String id) async {
    await userCollection(collection).doc(id).set(data, SetOptions(merge: true));
  }

  // ─── Delete ───────────────────────────────

  Future<void> delete(String collection, String id) async {
    await userCollection(collection).doc(id).delete();
  }

  // ─── Real-Time Listeners ──────────────────

  /// Listens to entire collection — returns cancellable subscription.
  Stream<List<Map<String, dynamic>>> listen(String collection) {
    return userCollection(collection).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Listens to a single document.
  Stream<Map<String, dynamic>?> listenToDocument(
      String collection, String id) {
    return userCollection(collection).doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    });
  }

  // ─── Settings Helper ──────────────────────

  Future<void> setPreferences(Map<String, dynamic> data) async {
    await userDocument('settings', 'preferences')
        .set(data, SetOptions(merge: true));
  }
}
