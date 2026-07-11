import 'package:flutter/material.dart';

import '../repo/settings_repo.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepo _settingsRepo;

  SettingsViewModel(this._settingsRepo);

  bool _loading = false;
  String? _error;

  String _currency = 'NPR';
  String _language = 'English';
  int _weeklyOffDay = 0;

  bool get loading => _loading;
  String? get error => _error;

  String get currency => _currency;
  String get language => _language;
  int get weeklyOffDay => _weeklyOffDay;

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<bool> saveCurrency(String currency) async {
    setLoading(true);

    try {
      await _settingsRepo.saveCurrency(currency);
      _currency = currency;
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> getCurrency() async {
    _currency = await _settingsRepo.getCurrency();
    notifyListeners();
  }

  Future<bool> saveLanguage(String language) async {
    setLoading(true);

    try {
      await _settingsRepo.saveLanguage(language);
      _language = language;
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> getLanguage() async {
    _language = await _settingsRepo.getLanguage();
    notifyListeners();
  }

  Future<bool> saveWeeklyOffDay(int day) async {
    setLoading(true);

    try {
      await _settingsRepo.saveWeeklyOffDay(day);
      _weeklyOffDay = day;
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> getWeeklyOffDay() async {
    _weeklyOffDay = await _settingsRepo.getWeeklyOffDay();
    notifyListeners();
  }

  Future<void> backupData() async {
    await _settingsRepo.backupData();
  }

  Future<void> restoreData() async {
    await _settingsRepo.restoreData();
  }

  Future<void> deleteAllData() async {
    await _settingsRepo.deleteAllData();
  }
}