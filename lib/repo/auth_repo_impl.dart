import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model.dart';
import 'auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _users => _firestore.collection('users');

  // =====================================================
  // REGISTER
  // =====================================================

  @override
  Future<bool> registerWithEmail(
      String email,
      String password,
      ) async {
    try {
      final credential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return false;
      }

      await credential.user!.sendEmailVerification();

      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "email-already-in-use":
          throw Exception("Email already exists.");
        case "invalid-email":
          throw Exception("Invalid email.");
        case "weak-password":
          throw Exception("Password is too weak.");
        default:
          throw Exception(e.message ?? "Registration failed.");
      }
    }
  }

  // =====================================================
  // LOGIN
  // =====================================================

  @override
  Future<bool> loginWithEmail(
      String email,
      String password,
      ) async {
    try {
      final credential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.reload();

      if (!(credential.user?.emailVerified ?? false)) {
        await _auth.signOut();
        throw Exception(
          "Please verify your email before logging in.",
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", true);

      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "user-not-found":
          throw Exception("No account found.");
        case "wrong-password":
        case "invalid-credential":
          throw Exception("Incorrect email or password.");
        case "invalid-email":
          throw Exception("Invalid email.");
        default:
          throw Exception(e.message ?? "Login failed.");
      }
    }
  }

  // =====================================================
  // EMAIL VERIFICATION
  // =====================================================

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;

    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  @override
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // If your variable name is different, change '_firebaseAuth' to match your instance name
    await _auth.sendPasswordResetEmail(email: email);
  }

  // =====================================================
  // SESSION
  // =====================================================

  @override
  Future<void> logout() async {
    await _auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isLoggedIn", false);
  }

  @override
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final logged =
        prefs.getBool("isLoggedIn") ?? false;

    return logged &&
        _auth.currentUser != null &&
        _auth.currentUser!.emailVerified;
  }

  @override
  Future<bool> saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool("isLoggedIn", isLoggedIn);
  }

  // =====================================================
  // USER DATA
  // =====================================================

  @override
  Future<void> saveUserData(UserModel user) async {
    final uid = getCurrentUserId();

    if (uid == null) {
      throw Exception("User not logged in.");
    }

    final updated = user.copyWith(
      id: uid,
      lastLogin: DateTime.now(),
    );

    await _users.doc(uid).set(updated.toMap());
  }

  @override
  Future<UserModel?> getUserProfile(
      String uid,
      ) async {
    try {
      final doc =
      await _users.doc(uid).get();

      if (!doc.exists) return null;

      return UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateProfile(
      UserModel user,
      ) async {
    await _users
        .doc(user.id)
        .update(user.toMap());
  }

  // =====================================================
  // PROFILE IMAGE
  // =====================================================

  @override
  Future<void> updateProfileImage(
      String imagePath,
      ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final uid = getCurrentUserId();
      final currentUser = _auth.currentUser;

      // 1. Purge remote Cloud Firestore document link references
      if (uid != null) {
        await _users.doc(uid).delete();
      }

      // 2. Kill credential access tokens on Firebase Auth servers
      if (currentUser != null) {
        await currentUser.delete();
      }

      // 3. Clear local session tokens inside SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception("Security block: This request requires a fresh login sequence before termination processing.");
      }
      throw Exception(e.message ?? "Profile lifecycle decommissioning failed.");
    } catch (e) {
      throw Exception("De-registration tracking runtime fault: $e");
    }
  }

  // =====================================================
  // PREFERENCES
  // =====================================================

  @override
  Future<void> savePreference(
      String key,
      dynamic value,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else {
      await prefs.setString(key, value.toString());
    }
  }

  @override
  Future<dynamic> getPreference(
      String key,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.get(key);
  }
}