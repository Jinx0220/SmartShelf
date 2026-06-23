import 'dart:math';
import '../model/prediction_model.dart';
import '../model/sale_model.dart';
import '../model/product_model.dart';

class AIPredictionService {
  // Calculate moving average of last N weeks
  double calculateMovingAverage(List<int> data, {int period = 4}) {
    if (data.isEmpty) return 0;
    final takeCount = min(period, data.length);
    final recentData = data.reversed.take(takeCount).toList();
    return recentData.reduce((a, b) => a + b) / recentData.length;
  }

  // Group sales by weekday and calculate averages
  Map<int, double> calculateWeekdayAverages(List<SaleModel> sales) {
    Map<int, List<int>> salesByWeekday = {};

    for (var sale in sales) {
      int weekday = sale.timestamp.weekday;
      salesByWeekday[weekday] ??= [];
      salesByWeekday[weekday]!.add(sale.quantity);
    }

    Map<int, double> avgByWeekday = {};
    for (var entry in salesByWeekday.entries) {
      if (entry.value.length >= 4) {
        avgByWeekday[entry.key] =
            entry.value.take(4).reduce((a, b) => a + b) / 4;
      } else if (entry.value.isNotEmpty) {
        avgByWeekday[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }
    return avgByWeekday;
  }

  // Calculate confidence level based on data availability
  String calculateConfidence(List<SaleModel> sales, {int weeklyOffDay = 0}) {
    if (sales.length < 7) return 'Insufficient';
    if (sales.length >= 28) return 'High';
    if (sales.length >= 14) return 'Medium';
    return 'Low';
  }

  // Generate explanation for prediction
  Map<String, dynamic> generateExplanation(
      PredictionModel prediction,
      List<SaleModel> sales,
      ) {
    if (sales.isEmpty) {
      return {
        'message': 'No sales data available for this product.',
      };
    }

    final sortedSales = sales.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final last4Weeks = sortedSales.reversed.take(4).toList();
    final weeklyAverages = calculateWeekdayAverages(sales);

    return {
      'totalSales': sales.length,
      'last4WeeksSales': last4Weeks.map((s) => s.quantity).toList(),
      'weeklyAverages': weeklyAverages,
      'predictedQuantity': prediction.predictedQuantity,
      'confidenceLevel': prediction.confidenceLevel,
      'dataPoints': sales.length,
    };
  }

  // Generate prediction for a single product
  PredictionModel generateProductPrediction(
      String productId,
      String productName,
      List<SaleModel> sales,
      int weeklyOffDay,
      ) {
    final confidence = calculateConfidence(sales, weeklyOffDay: weeklyOffDay);

    int predictedQuantity = 0;
    Map<String, dynamic> explanationData = {};

    if (confidence != 'Insufficient') {
      final avgByWeekday = calculateWeekdayAverages(sales);

      double totalPrediction = 0;
      for (int day = 1; day <= 7; day++) {
        if (day != weeklyOffDay) {
          totalPrediction += avgByWeekday[day] ?? 0;
        }
      }
      predictedQuantity = totalPrediction.round();
      explanationData = {
        'weeklyAverages': avgByWeekday,
        'method': 'Moving Average (last 4 weeks)',
        'weeklyOffDay': weeklyOffDay,
      };
    } else {
      explanationData = {
        'message': 'Insufficient data (need 7+ days of sales history)',
        'salesDays': sales.length,
      };
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return PredictionModel(
      productId: productId,
      productName: productName,
      predictedQuantity: predictedQuantity > 0 ? predictedQuantity : 0,
      confidenceLevel: confidence,
      generatedDate: now,
      forWeekStarting: weekStart,
      explanationData: explanationData,
    );
  }

  // Generate predictions for all products
  List<PredictionModel> generateAllPredictions(
      List<ProductModel> products,
      List<SaleModel> sales,
      int weeklyOffDay,
      ) {
    List<PredictionModel> predictions = [];

    for (var product in products) {
      final productSales = sales
          .where((s) => s.productId == product.id)
          .toList();

      final prediction = generateProductPrediction(
        product.id!,
        product.name!,
        productSales,
        weeklyOffDay,
      );
      predictions.add(prediction);
    }

    return predictions;
  }

  // Calculate prediction accuracy
  double calculateAccuracy(PredictionModel prediction, int actualSales) {
    if (prediction.predictedQuantity == 0) return 0;
    final diff = (prediction.predictedQuantity - actualSales).abs();
    return max(0, 100 - (diff / prediction.predictedQuantity * 100));
  }

  // Get confidence badge text
  String getConfidenceText(String confidence) {
    switch (confidence) {
      case 'High': return 'High Confidence';
      case 'Medium': return 'Medium Confidence';
      case 'Low': return 'Low Confidence';
      default: return 'Insufficient Data';
    }
  }
}