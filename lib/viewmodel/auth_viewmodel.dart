import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/user_model.dart';
import '../repo/auth_repo.dart';
import '../repo/auth_repo_impl.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepo _authRepo;

  AuthViewModel({required AuthRepo authRepo})
      : _authRepo = authRepo {
    _initializeAuth();
  }

  bool _loading = false;
  String? _error;
  UserModel? _user;
  bool _loggedIn = false;

  bool get loading => _loading;
  String? get error => _error;
  UserModel? get user => _user;
  bool get loggedIn => _loggedIn;
  bool get isLoading => _loading;
  bool get isAuthenticated => _loggedIn;

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
  // INITIALIZATION
  // =====================================================

  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _authRepo.checkLoginStatus();
      if (isLoggedIn) {
        await loadCurrentUser();
      }
    } catch (e) {
      debugPrint("Init Error: $e");
    } finally {
      _setLoading(false);
    }
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
      final success = await _authRepo.registerWithEmail(user.email!, password);

      if (!success) {
        String errorMsg = "Registration failed. Please check your details.";
        try {
          final repo = _authRepo as AuthRepoImpl;
          if (repo.lastError != null) {
            errorMsg = repo.lastError!;
          }
        } catch (_) {}
        _setError(errorMsg);
        return false;
      }

      await _authRepo.saveUserData(user);
      await _authRepo.sendEmailVerification();
      _setUser(user);
      return true;
    } catch (e) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAccountPermanently() async {
    _setLoading(true);
    _setError(null);
    try {
      await _authRepo.deleteAccount();
      _setUser(null);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =====================================================
  // LOGIN - 🟢 FIXED
  // =====================================================

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // 🟢 Call login - THIS WILL THROW AN EXCEPTION ON FAILURE
      final success = await _authRepo.loginWithEmail(email, password);

      // If we get here, login succeeded
      if (success) {
        // Check if email is verified
        final verified = await isEmailVerified();
        if (!verified) {
          _setError("Please verify your email before logging in.");
          await _authRepo.logout();
          return false;
        }

        // Load user profile
        final uid = _authRepo.getCurrentUserId();
        if (uid != null) {
          final profile = await _authRepo.getUserProfile(uid);
          _setUser(profile);
        }

        await _authRepo.saveLoginState(true);
        return true;
      } else {
        // This shouldn't happen if the repo throws exceptions
        _setError("Login failed. Please try again.");
        return false;
      }
    } catch (e) {
      // 🟢 THIS IS WHERE ERRORS GO - Firebase throws exceptions
      final errorMessage = e.toString().replaceFirst("Exception: ", "");

      // 🟢 Map common Firebase errors to user-friendly messages
      String userFriendlyMessage = errorMessage;

      if (errorMessage.contains("wrong-password") ||
          errorMessage.contains("invalid-credential") ||
          errorMessage.contains("Incorrect email or password")) {
        userFriendlyMessage = "Incorrect password. Please try again.";
      } else if (errorMessage.contains("user-not-found") ||
          errorMessage.contains("No account found")) {
        userFriendlyMessage = "No account found with this email address.";
      } else if (errorMessage.contains("invalid-email")) {
        userFriendlyMessage = "Invalid email format. Please enter a valid email.";
      } else if (errorMessage.contains("user-disabled")) {
        userFriendlyMessage = "This account has been disabled. Please contact support.";
      } else if (errorMessage.contains("too-many-requests")) {
        userFriendlyMessage = "Too many failed attempts. Please try again later.";
      } else if (errorMessage.contains("network-request-failed") ||
          errorMessage.contains("Network error")) {
        userFriendlyMessage = "Network error. Please check your internet connection.";
      } else if (errorMessage.contains("Please verify your email")) {
        userFriendlyMessage = "Please verify your email before logging in. Check your inbox.";
      }

      _setError(userFriendlyMessage);
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
  // PASSWORD RESET
  // =====================================================

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authRepo.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst("Exception: ", ""));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =====================================================
  // PROFILE
  // =====================================================

  Future<void> loadCurrentUser() async {
    final uid = _authRepo.getCurrentUserId();
    if (uid == null) return;
    final profile = await _authRepo.getUserProfile(uid);
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

  Future<void> savePreference(String key, dynamic value) async {
    await _authRepo.savePreference(key, value);
  }

  Future<dynamic> getPreference(String key) async {
    return await _authRepo.getPreference(key);
  }

  // =====================================================
  // RE-AUTHENTICATE
  // =====================================================

  Future<bool> reauthenticateUser(String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final email = user.email;
      if (email == null || email.isEmpty) {
        final userModel = await _authRepo.getUserProfile('current');
        if (userModel?.email == null) {
          _setError("No email found for re-authentication");
          return false;
        }
      }

      final credential = EmailAuthProvider.credential(
        email: email ?? user.email ?? '',
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? "Re-authentication failed");
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
}