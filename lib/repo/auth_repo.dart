import '../model/user_model.dart';

abstract class AuthRepo {
  Future<void> registerWithPhone(String phone);

  Future<bool> verifyOTP(
      String verificationId,
      String otp,
      );

  Future<void> saveUserData(UserModel user);

  Future<bool> loginWithPhone(
      String phone,
      String password,
      );

  Future<void> logout();

  Future<bool> checkLoginStatus();

  Future<void> sendPasswordResetOTP(String phone);

  Future<bool> resetPassword(
      String phone,
      String newPassword,
      );

  Future<void> updateProfile(UserModel user);

  Future<UserModel> getUserProfile(String uid);

  Future<void> updateProfileImage(String imagePath);

  Future<void> savePreference(
      String key,
      dynamic value,
      );

  Future<dynamic> getPreference(String key);
}