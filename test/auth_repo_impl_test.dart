import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartshelf/model/user_model.dart';
import 'package:smartshelf/repo/auth_repo_impl.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late AuthRepoImpl repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = MockFirebaseAuth();
    firestore = FakeFirebaseFirestore();
    repo = AuthRepoImpl(auth: auth, firestore: firestore);
  });

  group('AuthRepoImpl Tests', () {
    test('registerWithEmail succeeds and clears error state', () async {
      final result = await repo.registerWithEmail('user@smartshelf.com', 'Password123!');

      expect(result, isTrue);
      expect(repo.lastError, isNull);
      expect(auth.currentUser?.email, 'user@smartshelf.com');
    });

    test('loginWithEmail fails when user email is not verified', () async {
      final mockUser = MockUser(
        email: 'unverified@smartshelf.com',
        isEmailVerified: false,
      );
      auth = MockFirebaseAuth(mockUser: mockUser);
      repo = AuthRepoImpl(auth: auth, firestore: firestore);

      final result = await repo.loginWithEmail('unverified@smartshelf.com', 'Password123!');

      expect(result, isFalse);
      expect(repo.lastError, contains('verify your email'));
    });

    test('loginWithEmail succeeds and saves login state when email is verified', () async {
      final mockUser = MockUser(
        email: 'verified@smartshelf.com',
        isEmailVerified: true,
      );
      auth = MockFirebaseAuth(mockUser: mockUser);
      repo = AuthRepoImpl(auth: auth, firestore: firestore);

      final result = await repo.loginWithEmail('verified@smartshelf.com', 'Password123!');

      expect(result, isTrue);
      expect(repo.lastError, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isLoggedIn'), isTrue);
    });

    test('saveUserData stores user profile under current auth uid in Firestore', () async {
      final mockUser = MockUser(
        uid: 'user_uid_123',
        email: 'owner@smartshelf.com',
        isEmailVerified: true,
      );
      auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      repo = AuthRepoImpl(auth: auth, firestore: firestore);

      final userModel = UserModel(
        email: 'owner@smartshelf.com',
      );

      await repo.saveUserData(userModel);

      final doc = await firestore.collection('users').doc('user_uid_123').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['email'], 'owner@smartshelf.com');
      expect(doc.data()?['id'], 'user_uid_123');
    });

    test('getUserProfile fetches user document from firestore', () async {
      await firestore.collection('users').doc('user_123').set({
        'id': 'user_123',
        'email': 'user@smartshelf.com',
      });

      final user = await repo.getUserProfile('user_123');

      expect(user, isNotNull);
      expect(user!.email, 'user@smartshelf.com');
      expect(user.id, 'user_123');
    });

    test('updateProfile modifies existing user document', () async {
      await firestore.collection('users').doc('user_123').set({
        'id': 'user_123',
        'email': 'user@smartshelf.com',
      });

      final userModel = UserModel(
        id: 'user_123',
        email: 'user.updated@smartshelf.com',
      );

      await repo.updateProfile(userModel);

      final doc = await firestore.collection('users').doc('user_123').get();
      expect(doc.data()?['email'], 'user.updated@smartshelf.com');
    });

    test('logout clears auth user session and updates local preferences', () async {
      final mockUser = MockUser(uid: 'user_123', isEmailVerified: true);
      auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      repo = AuthRepoImpl(auth: auth, firestore: firestore);

      await repo.saveLoginState(true);
      await repo.logout();

      expect(auth.currentUser, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isLoggedIn'), isFalse);
    });

    test('deleteAccount removes firestore profile doc and updates login preference', () async {
      final mockUser = MockUser(
        uid: 'user_to_delete',
        email: 'delete@smartshelf.com',
      );
      auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      repo = AuthRepoImpl(auth: auth, firestore: firestore);

      await firestore.collection('users').doc('user_to_delete').set({
        'email': 'delete@smartshelf.com',
      });

      await repo.deleteAccount();

      // 1. Verify Firestore document was deleted
      final doc = await firestore.collection('users').doc('user_to_delete').get();
      expect(doc.exists, isFalse);

      // 2. Verify local login session state was cleared
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isLoggedIn'), isFalse);
    });

    test('savePreference and getPreference persist primitive values in SharedPreferences', () async {
      await repo.savePreference('theme_mode', 'dark');
      await repo.savePreference('notifications_enabled', true);
      await repo.savePreference('low_stock_threshold', 10);

      final theme = await repo.getPreference('theme_mode');
      final notifications = await repo.getPreference('notifications_enabled');
      final threshold = await repo.getPreference('low_stock_threshold');

      expect(theme, 'dark');
      expect(notifications, isTrue);
      expect(threshold, 10);
    });
  });
}