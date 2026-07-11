import 'package:flutter/material.dart';
import '../model/prediction_model.dart';
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

  void setLoading(bool value) {
    if (_loading != value) {
      _loading = value;
      notifyListeners();
    }
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void setPredictions(List<PredictionModel>? value) {
    _predictions = value;
    notifyListeners();
  }

  Future<void> generatePredictions(List<dynamic> products, List<dynamic> sales, int fallbackDays) async {
    _loading = true;
    notifyListeners();

    try {
      List<PredictionModel> updatedPredictions = [];
      final DateTime now = DateTime.now();
      final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      for (var product in products) {
        String pId = '';
        String pName = '';
        try {
          pId = product.id?.toString() ?? '';
          pName = product.name?.toString() ?? '';
        } catch (_) {
          if (product is Map) {
            pId = product['id']?.toString() ?? '';
            pName = product['name']?.toString() ?? '';
          }
        }

        if (pName.isEmpty) continue;

        final productSales = sales.where((s) => s.productName.toLowerCase() == pName.toLowerCase()).toList();

        double totalSold = 0;
        Map<String, dynamic> weeklyAverages = {};

        for (var sale in productSales) {
          totalSold += sale.quantity;
          // FIXED: Changed sale.date to sale.timestamp to match the schema properties
          String dayKey = sale.timestamp.weekday.toString();
          weeklyAverages[dayKey] = (weeklyAverages[dayKey] ?? 0.0) + sale.quantity;
        }

        int predictedQty = 0;
        String confidence = "Insufficient";

        if (productSales.isNotEmpty) {
          if (productSales.length >= 7) {
            confidence = "High";
            predictedQty = (totalSold / 4).ceil();
          } else {
            confidence = "Low";
            predictedQty = totalSold.ceil();
          }
        }

        if (predictedQty <= 0) {
          predictedQty = 5;
        }

        updatedPredictions.add(PredictionModel(
          productId: pId,
          productName: pName,
          predictedQuantity: predictedQty,
          confidenceLevel: confidence,
          generatedDate: now,
          forWeekStarting: startOfWeek,
          explanationData: {
            'weeklyAverages': weeklyAverages.isEmpty ? {"1": totalSold} : weeklyAverages,
            'message': 'Calculated from available early baseline store logs.'
          },
        ));
      }

      _predictions = updatedPredictions;
    } catch (e) {
      debugPrint("Prediction processing error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> getAllPredictions() async {
    setLoading(true);
    setError(null);
    try {
      _predictions = await _predictionRepo.getAllPredictions();
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

      if (_predictions != null) {
        final index = _predictions!.indexWhere((p) => p.productId == productId);
        if (index != -1) {
          _predictions![index] = _predictions![index].copyWith(predictedQuantity: newQuantity);
        }
      }

      if (_currentPrediction != null && _currentPrediction!.productId == productId) {
        _currentPrediction = _currentPrediction!.copyWith(predictedQuantity: newQuantity);
      }

      final freshPredictions = await _predictionRepo.getAllPredictions();
      _predictions = freshPredictions;
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
      _predictions = await _predictionRepo.getAllPredictions();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void clearError() {
    setError(null);
  }
}