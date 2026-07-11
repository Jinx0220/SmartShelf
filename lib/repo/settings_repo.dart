abstract class SettingsRepo {
  Future<void> saveCurrency(String currency);
  Future<String> getCurrency();

  Future<void> saveLanguage(String language);
  Future<String> getLanguage();

  Future<void> saveWeeklyOffDay(int day);
  Future<int> getWeeklyOffDay();

  Future<void> backupData();
  Future<void> restoreData();
  Future<void> deleteAllData();
}