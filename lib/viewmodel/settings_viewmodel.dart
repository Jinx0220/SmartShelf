import 'package:flutter/material.dart';
import '../repo/settings_repo.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepo _settingsRepo;

  SettingsViewModel({required SettingsRepo settingsRepo})
      : _settingsRepo = settingsRepo;

  bool _loading = false;
  String? _error;
  String _currency = 'NPR';
  String _language = 'English';
  int _weeklyOffDay = 0;

  // Getters
  bool get loading => _loading;
  String? get error => _error;
  String get currency => _currency;
  String get language => _language;
  int get weeklyOffDay => _weeklyOffDay;

  // Setters
  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Load Settings
  Future<void> loadSettings() async {
    setLoading(true);
    setError(null);
    try {
      _currency = await _settingsRepo.getCurrency();
      _language = await _settingsRepo.getLanguage();
      _weeklyOffDay = await _settingsRepo.getWeeklyOffDay();
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Save Currency
  Future<void> saveCurrency(String currency) async {
    setLoading(true);
    setError(null);
    try {
      await _settingsRepo.saveCurrency(currency);
      _currency = currency;
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Save Language
  Future<void> saveLanguage(String language) async {
    setLoading(true);
    setError(null);
    try {
      await _settingsRepo.saveLanguage(language);
      _language = language;
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Save Weekly Off Day
  Future<void> saveWeeklyOffDay(int day) async {
    setLoading(true);
    setError(null);
    try {
      await _settingsRepo.saveWeeklyOffDay(day);
      _weeklyOffDay = day;
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Delete All Data
  Future<void> deleteAllData() async {
    setLoading(true);
    setError(null);
    try {
      await _settingsRepo.deleteAllData();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Clear Error
  void clearError() {
    setError(null);
  }
}