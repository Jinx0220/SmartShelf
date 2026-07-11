import '../model/user_model.dart';

abstract class AuthRepo {
  // ==========================
  // AUTHENTICATION
  // ==========================

  Future<bool> registerWithEmail(
      String email,
      String password,
      );

  Future<bool> loginWithEmail(
      String email,
      String password,
      );

  Future<void> logout();

  // ==========================
  // EMAIL VERIFICATION
  // ==========================

  Future<void> sendEmailVerification();
  Future<void> deleteAccount();

  // Place this inside your abstract class AuthRepo { ... }
  Future<void> sendPasswordResetEmail(String email);

  Future<void> reloadUser();

  bool isEmailVerified();

  String? getCurrentUserId();

  // ==========================
  // SESSION
  // ==========================

  Future<bool> checkLoginStatus();

  Future<bool> saveLoginState(bool isLoggedIn);

  // ==========================
  // USER DATA
  // ==========================

  Future<void> saveUserData(UserModel user);

  Future<UserModel?> getUserProfile(String uid);

  Future<void> updateProfile(UserModel user);

  // ==========================
  // PROFILE IMAGE
  // ==========================

  Future<void> updateProfileImage(String imagePath);

  // ==========================
  // PREFERENCES
  // ==========================

  Future<void> savePreference(String key, dynamic value);

  Future<dynamic> getPreference(String key);
}