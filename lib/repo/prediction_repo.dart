import '../model/prediction_model.dart';
import '../model/product_model.dart';
import '../model/sale_model.dart';

abstract class PredictionRepo {
  // Generate predictions
  Future<List<PredictionModel>> generatePredictions(
      List<ProductModel> products,
      List<SaleModel> sales,
      int weeklyOffDay,
      );

  Future<PredictionModel> generateProductPrediction(
      String productId,
      List<SaleModel> sales,
      int weeklyOffDay,
      );

  // Save predictions
  Future<void> savePrediction(PredictionModel prediction);
  Future<void> savePredictions(List<PredictionModel> predictions);

  // Get predictions
  Future<List<PredictionModel>> getAllPredictions();
  Future<PredictionModel?> getPredictionForProduct(String productId);

  // Update/Delete
  Future<void> updatePrediction(String productId, int newQuantity);
  Future<void> deletePrediction(String productId);

  // Analytics
  Future<Map<String, double>> getPredictionAccuracy();
  Future<void> retrainPredictions(String userId);
}