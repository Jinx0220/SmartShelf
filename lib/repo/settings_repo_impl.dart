import 'package:shared_preferences/shared_preferences.dart';
import 'settings_repo.dart';

class SettingsRepoImpl implements SettingsRepo {
  @override
  Future<void> saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
  }

  @override
  Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currency') ?? 'NPR';
  }

  @override
  Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  @override
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language') ?? 'English';
  }

  @override
  Future<void> saveWeeklyOffDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weeklyOffDay', day);
  }

  @override
  Future<int> getWeeklyOffDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('weeklyOffDay') ?? 0;
  }

  @override
  Future<void> backupData() async {
    // TODO: Implement backup to cloud
    throw UnimplementedError();
  }

  @override
  Future<void> restoreData() async {
    // TODO: Implement restore from cloud
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('products');
    await prefs.remove('sales');
    await prefs.remove('manual_predictions');
  }
}