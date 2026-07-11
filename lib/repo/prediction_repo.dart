import '../model/prediction_model.dart';
import '../model/product_model.dart';
import '../model/sale_model.dart';

abstract class PredictionRepo {
  // Generate Core Batch / Singular Machine Learning Projections
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

  // Persistence Operations
  Future<void> savePrediction(PredictionModel prediction);
  Future<void> savePredictions(List<PredictionModel> predictions);

  // Read Retrieval Queries
  Future<List<PredictionModel>> getAllPredictions();
  Future<PredictionModel?> getPredictionForProduct(String productId);

  // Mutation Contracts
  Future<void> updatePrediction(String productId, int newQuantity);
  Future<void> deletePrediction(String productId);

  // Algorithmic Backtesting & Training Pipeline Contracts
  Future<Map<String, double>> getPredictionAccuracy();
  Future<void> retrainPredictions(String userId);
}