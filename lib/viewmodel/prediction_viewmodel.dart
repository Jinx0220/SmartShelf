// File: lib/viewmodel/prediction_viewmodel.dart
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

  // 🟢 FIXED: generatePredictions with improved velocity-based calculations
  Future<void> generatePredictions(List<dynamic> products, List<dynamic> sales, int fallbackDays) async {
    _loading = true;
    notifyListeners();

    try {
      List<PredictionModel> updatedPredictions = [];
      final DateTime now = DateTime.now();
      final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // Calculate days to consider (use fallbackDays or actual days available)
      final int daysToConsider = fallbackDays > 0 ? fallbackDays : 30;

      for (var product in products) {
        String pId = '';
        String pName = '';
        int currentStock = 0;
        int threshold = 0;

        try {
          pId = product.id?.toString() ?? '';
          pName = product.name?.toString() ?? '';
          currentStock = (product.stock as num?)?.toInt() ?? 0;
          threshold = (product.threshold as num?)?.toInt() ?? 5;
        } catch (_) {
          if (product is Map) {
            pId = product['id']?.toString() ?? '';
            pName = product['name']?.toString() ?? '';
            currentStock = (product['stock'] as num?)?.toInt() ?? 0;
            threshold = (product['threshold'] as num?)?.toInt() ?? 5;
          }
        }

        if (pName.isEmpty) continue;

        // Get sales for this product (last 30 days by default)
        final productSales = sales.where((s) =>
        s.productName.toLowerCase() == pName.toLowerCase() &&
            s.timestamp.isAfter(now.subtract(Duration(days: daysToConsider)))
        ).toList();

        // Calculate daily velocity
        double dailyVelocity = 0;
        double totalSold = 0;
        Map<String, dynamic> weeklyAverages = {};

        // Group sales by day of week
        for (var sale in productSales) {
          totalSold += sale.quantity;
          String dayKey = sale.timestamp.weekday.toString();
          weeklyAverages[dayKey] = (weeklyAverages[dayKey] ?? 0.0) + sale.quantity;
        }

        // Calculate daily velocity (average sales per day)
        if (productSales.isNotEmpty) {
          // Calculate average sales per day
          final int daysWithData = productSales.length;
          // Find the date range of the sales
          final sortedSales = List.from(productSales)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          final firstDate = sortedSales.first.timestamp;
          final lastDate = sortedSales.last.timestamp;
          final int dateRangeDays = lastDate.difference(firstDate).inDays + 1;

          // Use the actual date range or at least the number of days with data
          final int effectiveDays = dateRangeDays > 0 ? dateRangeDays : daysWithData;
          dailyVelocity = totalSold / effectiveDays;
        }

        // Calculate predicted quantity based on velocity and threshold
        int predictedQty = 0;
        String confidence = "Insufficient";
        String explanation = "";

        if (productSales.isNotEmpty && dailyVelocity > 0) {
          // Higher confidence with more data points
          if (productSales.length >= 7) {
            confidence = "High";
          } else if (productSales.length >= 3) {
            confidence = "Medium";
          } else {
            confidence = "Low";
          }

          // 🟢 Improved prediction formula: (Daily Velocity × 7 days) + buffer
          // This predicts the demand for the next 7 days
          final int basePrediction = (dailyVelocity * 7).ceil();

          // Add a small buffer (10-20% of threshold) for safety
          final int buffer = (threshold * 0.2).ceil();
          predictedQty = basePrediction + buffer;

          // Ensure minimum prediction
          if (predictedQty < 1) predictedQty = 1;

          // If current stock is very low, suggest at least enough to reach threshold
          if (currentStock < threshold) {
            final int neededToReachThreshold = threshold - currentStock;
            if (predictedQty < neededToReachThreshold) {
              predictedQty = neededToReachThreshold + 2; // Add small buffer
            }
          }

          explanation = "Based on daily velocity of ${dailyVelocity.toStringAsFixed(2)} units/day over ${productSales.length} sales records.";

        } else {
          // Insufficient data - use fallback
          confidence = "Insufficient";
          predictedQty = threshold > 0 ? threshold : 5;
          explanation = "Insufficient sales data. Using default threshold of $predictedQty units.";
        }

        // Ensure prediction is at least the threshold if stock is low
        if (currentStock < threshold && predictedQty < (threshold * 0.5).ceil()) {
          predictedQty = (threshold * 0.5).ceil();
        }

        // Cap prediction at reasonable levels (max 100 units per week)
        if (predictedQty > 100) {
          predictedQty = 100;
        }

        // Add the prediction
        updatedPredictions.add(PredictionModel(
          productId: pId,
          productName: pName,
          predictedQuantity: predictedQty,
          confidenceLevel: confidence,
          generatedDate: now,
          forWeekStarting: startOfWeek,
          explanationData: {
            'weeklyAverages': weeklyAverages.isEmpty ? {"1": totalSold} : weeklyAverages,
            'message': explanation,
            'dailyVelocity': dailyVelocity,
            'totalSales': totalSold,
            'salesCount': productSales.length,
            'currentStock': currentStock,
            'threshold': threshold,
          },
        ));
      }

      _predictions = updatedPredictions;
      debugPrint("✅ Generated ${updatedPredictions.length} predictions");

    } catch (e) {
      debugPrint("❌ Prediction processing error: $e");
      setError(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 🟢 NEW: Get safety threshold recommendations
  List<Map<String, dynamic>> getSafetyThresholdRecommendations() {
    if (_predictions == null || _predictions!.isEmpty) return [];

    final List<Map<String, dynamic>> recommendations = [];

    for (var prediction in _predictions!) {
      // Extract velocity from explanation data
      double dailyVelocity = 0;
      try {
        dailyVelocity = (prediction.explanationData?['dailyVelocity'] ?? 0).toDouble();
      } catch (_) {
        dailyVelocity = 0;
      }

      // Calculate recommended threshold: (dailyVelocity * 3) + 2 (3-day buffer + safety margin)
      final int recommendedThreshold = dailyVelocity > 0
          ? (dailyVelocity * 3 + 2).ceil()
          : prediction.predictedQuantity > 0
          ? (prediction.predictedQuantity / 3).ceil()
          : 5;

      recommendations.add({
        'productName': prediction.productName,
        'productId': prediction.productId,
        'currentThreshold': 0, // This would need to be passed from products
        'recommendedThreshold': recommendedThreshold,
        'dailyVelocity': dailyVelocity,
        'currentPrediction': prediction.predictedQuantity,
        'confidence': prediction.confidenceLevel,
      });
    }

    return recommendations;
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