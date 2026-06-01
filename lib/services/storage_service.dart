import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  static Future<void> init() async {
    _instance._prefs = await SharedPreferences.getInstance();
  }

  // Profile getters/setters
  static Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    await _instance._prefs.setString('profile_name', name);
    await _instance._prefs.setString('profile_email', email);
    await _instance._prefs.setString('profile_phone', phone);
    await _instance._prefs.setString('profile_address', address);
  }

  static String getProfileName() {
    return _instance._prefs.getString('profile_name') ?? 'Hajun';
  }

  static String getProfileEmail() {
    return _instance._prefs.getString('profile_email') ?? 'Hajun@smartshelf.com';
  }

  static String getProfilePhone() {
    return _instance._prefs.getString('profile_phone') ?? '+977 9800000000';
  }

  static String getProfileAddress() {
    return _instance._prefs.getString('profile_address') ?? 'Lalitpur, Nepal';
  }

  // Store settings getters/setters
  static Future<void> saveStoreSettings({
    required String storeName,
    required String ownerName,
    required String phone,
    required String email,
    required String address,
    required String gst,
  }) async {
    await _instance._prefs.setString('store_name', storeName);
    await _instance._prefs.setString('store_owner', ownerName);
    await _instance._prefs.setString('store_phone', phone);
    await _instance._prefs.setString('store_email', email);
    await _instance._prefs.setString('store_address', address);
    await _instance._prefs.setString('store_gst', gst);
  }

  static String getStoreName() {
    return _instance._prefs.getString('store_name') ?? 'Everest Kirana Store';
  }

  static String getStoreOwner() {
    return _instance._prefs.getString('store_owner') ?? 'Hajun';
  }

  static String getStorePhone() {
    return _instance._prefs.getString('store_phone') ?? '+977 9800000000';
  }

  static String getStoreEmail() {
    return _instance._prefs.getString('store_email') ?? 'Hajun@smartshelf.com';
  }

  static String getStoreAddress() {
    return _instance._prefs.getString('store_address') ?? 'Lalitpur, Nepal';
  }

  static String getStoreGst() {
    return _instance._prefs.getString('store_gst') ?? '465001';
  }
}