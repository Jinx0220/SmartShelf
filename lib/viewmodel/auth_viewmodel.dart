import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/user_model.dart';
import '../repo/auth_repo.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepo _authRepo;

  AuthViewModel({required AuthRepo authRepo})
      : _authRepo = authRepo;

  bool _loading = false;
  String? _error;
  UserModel? _user;
  bool _loggedIn = false;

  bool get loading => _loading;
  String? get error => _error;
  UserModel? get user => _user;
  bool get loggedIn => _loggedIn;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _setUser(UserModel? value) {
    _user = value;
    _loggedIn = value != null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // =====================================================
  // REGISTER
  // =====================================================

  Future<bool> register({
    required UserModel user,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _authRepo.registerWithEmail(
        user.email!,
        password,
      );

      if (!success) {
        _setError("Registration failed.");
        return false;
      }

      await _authRepo.saveUserData(user);

      await _authRepo.sendEmailVerification();

      _setUser(user);

      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =====================================================
  // LOGIN
  // =====================================================

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _authRepo.loginWithEmail(
        email,
        password,
      );

      if (!success) {
        _setError("Login failed.");
        return false;
      }

      final uid = _authRepo.getCurrentUserId();

      if (uid != null) {
        final profile =
        await _authRepo.getUserProfile(uid);

        _setUser(profile);
      }

      await _authRepo.saveLoginState(true);

      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =====================================================
  // EMAIL VERIFICATION
  // =====================================================

  Future<bool> checkEmailVerified() async {
    await _authRepo.reloadUser();
    return _authRepo.isEmailVerified();
  }

  Future<void> resendVerificationEmail() async {
    await _authRepo.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    await user.reload();

    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  // =====================================================
  // PROFILE
  // =====================================================

  Future<void> loadCurrentUser() async {
    final uid = _authRepo.getCurrentUserId();

    if (uid == null) return;

    final profile =
    await _authRepo.getUserProfile(uid);

    _setUser(profile);
  }

  Future<bool> updateProfile(UserModel updatedUser) async {
    _setLoading(true);

    try {
      await _authRepo.updateProfile(updatedUser);

      _setUser(updatedUser);

      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =====================================================
  // SESSION
  // =====================================================

  Future<bool> checkLoginStatus() async {
    return await _authRepo.checkLoginStatus();
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authRepo.logout();

      await _authRepo.saveLoginState(false);

      _setUser(null);
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      _setLoading(false);
    }
  }

  // =====================================================
  // PREFERENCES
  // =====================================================

  Future<void> savePreference(
      String key,
      dynamic value,
      ) async {
    await _authRepo.savePreference(key, value);
  }

  Future<dynamic> getPreference(String key) async {
    return await _authRepo.getPreference(key);
  }
}