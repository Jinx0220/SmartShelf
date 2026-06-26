import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model.dart';
import '../services/firebase_services.dart';
import 'auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _collection =
  FirebaseServices().firestore.collection('users');

  @override
  Future<void> registerWithPhone(String phone) async {
    // OTP handled in UI layer
  }

  @override
  Future<bool> verifyOTP(
      String verificationId,
      String otp,
      ) async {
    try {
      PhoneAuthCredential credential =
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveUserData(UserModel user) async {
    await _collection.doc(user.id).set(user.toMap());
  }

  @override
  Future<bool> loginWithPhone(
      String phone,
      String password,
      ) async {
    return _auth.currentUser != null;
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<bool> checkLoginStatus() async {
    return _auth.currentUser != null;
  }

  @override
  Future<void> sendPasswordResetOTP(String phone) async {}

  @override
  Future<bool> resetPassword(
      String phone,
      String newPassword,
      ) async {
    return true;
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    await _collection.doc(user.id).update(user.toMap());
  }

  @override
  Future<UserModel> getUserProfile(String uid) async {
    final doc = await _collection.doc(uid).get();

    return UserModel.fromMap(
      doc.data() as Map<String, dynamic>,
    )..id = doc.id;
  }

  @override
  Future<void> updateProfileImage(String imagePath) async {}

  @override
  Future<void> savePreference(
      String key,
      dynamic value,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  @override
  Future<dynamic> getPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key);
  }
}