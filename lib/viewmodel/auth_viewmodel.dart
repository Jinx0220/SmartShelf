import 'package:flutter/material.dart';

import '../model/user_model.dart';
import '../repo/auth_repo.dart';
import '../repo/auth_repo_impl.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepo _authRepo = AuthRepoImpl();

  bool _loading = false;
  String? _error;
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  bool get loading => _loading;
  String? get error => _error;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<bool> registerWithPhone(String phone) async {
    setLoading(true);
    setError(null);

    try {
      await _authRepo.registerWithPhone(phone);
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> verifyOTP(
      String verificationId,
      String otp,
      ) async {
    setLoading(true);
    setError(null);

    try {
      bool result =
      await _authRepo.verifyOTP(verificationId, otp);

      _isLoggedIn = result;
      notifyListeners();

      return result;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> saveUserData(UserModel user) async {
    setLoading(true);
    setError(null);

    try {
      await _authRepo.saveUserData(user);
      _currentUser = user;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> loginWithPhone(
      String phone,
      String password,
      ) async {
    setLoading(true);
    setError(null);

    try {
      bool result =
      await _authRepo.loginWithPhone(phone, password);

      _isLoggedIn = result;
      notifyListeners();

      return result;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> logout() async {
    setLoading(true);
    setError(null);

    try {
      await _authRepo.logout();

      _isLoggedIn = false;
      _currentUser = null;

      notifyListeners();

      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> checkLoginStatus() async {
    setLoading(true);
    setError(null);

    try {
      _isLoggedIn =
      await _authRepo.checkLoginStatus();

      notifyListeners();

      return _isLoggedIn;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> sendPasswordResetOTP(
      String phone,
      ) async {
    setLoading(true);
    setError(null);

    try {
      await _authRepo.sendPasswordResetOTP(phone);
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> resetPassword(
      String phone,
      String newPassword,
      ) async {
    setLoading(true);
    setError(null);

    try {
      return await _authRepo.resetPassword(
        phone,
        newPassword,
      );
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateProfile(
      UserModel user,
      ) async {
    setLoading(true);
    setError(null);

    try {
      await _authRepo.updateProfile(user);

      _currentUser = user;
      notifyListeners();

      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<UserModel?> getUserProfile(
      String uid,
      ) async {
    setLoading(true);
    setError(null);

    try {
      _currentUser =
      await _authRepo.getUserProfile(uid);

      notifyListeners();

      return _currentUser;
    } on Exception catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateProfileImage(
      String imagePath,
      ) async {
    setLoading(true);
    setError(null);

    try {
      await _authRepo.updateProfileImage(imagePath);
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> savePreference(
      String key,
      dynamic value,
      ) async {
    setLoading(true);
    setError(null);

    try {
      await _authRepo.savePreference(
        key,
        value,
      );
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<dynamic> getPreference(
      String key,
      ) async {
    setLoading(true);
    setError(null);

    try {
      return await _authRepo.getPreference(key);
    } on Exception catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }
}