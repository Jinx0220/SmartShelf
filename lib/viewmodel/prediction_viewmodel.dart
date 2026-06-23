import 'package:flutter/material.dart';
import '../model/prediction_model.dart';
import '../model/product_model.dart';
import '../model/sale_model.dart';
import '../repo/prediction_repo.dart';

class PredictionViewModel extends ChangeNotifier {
  final PredictionRepo _predictionRepo;

  PredictionViewModel({required PredictionRepo predictionRepo})
      : _predictionRepo = predictionRepo;

  bool _loading = false;
  String? _error;
  List<PredictionModel>? _predictions;
  PredictionModel? _currentPrediction;
  Map<String, double>? _accuracy;

  bool get loading => _loading;
  String? get error => _error;
  List<PredictionModel>? get predictions => _predictions;
  PredictionModel? get currentPrediction => _currentPrediction;
  Map<String, double>? get accuracy => _accuracy;

  setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  setError(String? value) {
    _error = value;
    notifyListeners();
  }

  setPredictions(List<PredictionModel>? value) {
    _predictions = value;
    notifyListeners();
  }

  Future<bool> generatePredictions(
      List<ProductModel> products,
      List<SaleModel> sales,
      int weeklyOffDay,
      ) async {
    setLoading(true);
    setError(null);
    try {
      final predictions = await _predictionRepo.generatePredictions(
        products,
        sales,
        weeklyOffDay,
      );
      setPredictions(predictions);
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> getAllPredictions() async {
    setLoading(true);
    setError(null);
    try {
      _predictions = await _predictionRepo.getAllPredictions();
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> getPredictionForProduct(String productId) async {
    setLoading(true);
    setError(null);
    try {
      _currentPrediction = await _predictionRepo.getPredictionForProduct(productId);
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updatePrediction(String productId, int newQuantity) async {
    setLoading(true);
    setError(null);
    try {
      await _predictionRepo.updatePrediction(productId, newQuantity);
      await getAllPredictions();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> getPredictionAccuracy() async {
    setLoading(true);
    setError(null);
    try {
      _accuracy = await _predictionRepo.getPredictionAccuracy();
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> retrainPredictions(String userId) async {
    setLoading(true);
    setError(null);
    try {
      await _predictionRepo.retrainPredictions(userId);
      await getAllPredictions();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}