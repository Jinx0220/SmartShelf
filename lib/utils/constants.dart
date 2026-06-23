class AppConstants {
  static const String appName = 'SmartShelf';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String salesCollection = 'sales';
  static const String predictionsCollection = 'predictions';
  static const String ordersCollection = 'orders';
  static const String settingsCollection = 'settings';

  // SharedPreferences Keys
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyPhone = 'phone';
  static const String keyPassword = 'password';
  static const String keyFullName = 'fullName';
  static const String keyEmail = 'email';
  static const String keyStoreName = 'store_name';
  static const String keyStoreAddress = 'store_address';
  static const String keyCurrency = 'currency';
  static const String keyLanguage = 'language';
  static const String keyWeeklyOffDay = 'weeklyOffDay';
  static const String keyProducts = 'products';
  static const String keySales = 'sales';
  static const String keyManualPredictions = 'manual_predictions';

  // OTP
  static const String demoOTP = '123456';
  static const int otpLength = 6;
  static const int otpTimerSeconds = 60;
}