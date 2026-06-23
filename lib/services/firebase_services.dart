import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../firebase_options.dart';

class FirebaseServices {
  static final FirebaseServices _instance = FirebaseServices._internal();
  factory FirebaseServices() => _instance;
  FirebaseServices._internal();

  late FirebaseApp _app;
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  late FirebaseStorage _storage;

  // Getters
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;
  FirebaseStorage get storage => _storage;
  FirebaseApp get app => _app;

  // Initialize Firebase
  Future<void> initialize() async {
    _app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _storage = FirebaseStorage.instance;
  }

  // Firestore Helpers
  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(id).set(data);
  }

  Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    final doc = await _firestore.collection(collection).doc(id).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> deleteDocument(String collection, String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Future<void> updateDocument(String collection, String id, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(id).update(data);
  }

  // Real-time listeners
  Stream<List<T>> listenToCollection<T>(
      String collection,
      T Function(Map<String, dynamic>) fromJson,
      ) {
    return _firestore.collection(collection).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return fromJson(data);
      }).toList(),
    );
  }

  // Storage Helpers
  Future<String> uploadImage(String filePath, String folder) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('$folder/$fileName');
    final file = File(filePath);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Image might already be deleted
    }
  }

  Future<String?> getImageUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // Connection check
  Future<bool> checkConnection() async {
    try {
      await _firestore.collection('_test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }
}