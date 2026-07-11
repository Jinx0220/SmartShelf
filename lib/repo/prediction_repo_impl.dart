import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/prediction_model.dart';
import '../model/product_model.dart';
import '../model/sale_model.dart';
import '../services/ai_prediction_service.dart';
import '../services/firebase_services.dart';
import 'prediction_repo.dart';
import 'sale_repo_impl.dart';
import 'settings_repo_impl.dart';
import 'product_repo_impl.dart';

class PredictionRepoImpl implements PredictionRepo {
  final CollectionReference _collection =
  FirebaseServices().firestore.collection('predictions');
  final AIPredictionService _aiService = AIPredictionService();

  @override
  Future<List<PredictionModel>> generatePredictions(
      List<ProductModel> products,
      List<SaleModel> sales,
      int weeklyOffDay,
      ) async {
    return _aiService.generateAllPredictions(products, sales, weeklyOffDay);
  }

  @override
  Future<PredictionModel> generateProductPrediction(
      String productId,
      List<SaleModel> sales,
      int weeklyOffDay,
      ) async {
    final productName = sales.isNotEmpty ? sales.first.productName : 'Unknown';
    return _aiService.generateProductPrediction(
      productId,
      productName,
      sales,
      weeklyOffDay,
    );
  }

  @override
  Future<void> savePrediction(PredictionModel prediction) async {
    // FIXED: Guard against null IDs causing Firestore crashes by using an auto-generated path pointer
    final ref = prediction.id == null || prediction.id!.isEmpty
        ? _collection.doc()
        : _collection.doc(prediction.id);
    await ref.set(prediction.toMap());
  }

  @override
  Future<void> savePredictions(List<PredictionModel> predictions) async {
    final batch = FirebaseServices().firestore.batch();
    for (var prediction in predictions) {
      final ref = _collection.doc(prediction.id ??
          '${prediction.productId}_${DateTime.now().millisecondsSinceEpoch}');
      batch.set(ref, prediction.toMap());
    }
    await batch.commit();
  }

  @override
  Future<List<PredictionModel>> getAllPredictions() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PredictionModel.fromMap(data)..id = doc.id;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<PredictionModel?> getPredictionForProduct(String productId) async {
    try {
      final snapshot = await _collection
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return PredictionModel.fromMap(data)..id = doc.id;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updatePrediction(String productId, int newQuantity) async {
    try {
      final snapshot = await _collection
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'predictedQuantity': newQuantity,
        });
      }
    } catch (e) {
      throw Exception('Failed to update prediction: $e');
    }
  }

  @override
  Future<void> deletePrediction(String productId) async {
    try {
      final snapshot = await _collection
          .where('productId', isEqualTo: productId)
          .get();

      // FIXED: Batch the structural inventory mutations to minimize multi-trip network thrashing
      final batch = FirebaseServices().firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete prediction: $e');
    }
  }

  @override
  Future<Map<String, double>> getPredictionAccuracy() async {
    try {
      final predictions = await getAllPredictions();
      final Map<String, double> accuracy = {};

      for (var prediction in predictions) {
        if (prediction.actualQuantity != null) {
          accuracy[prediction.productId] = _aiService.calculateAccuracy(
            prediction,
            prediction.actualQuantity!,
          );
        }
      }
      return accuracy;
    } catch (e) {
      return {};
    }
  }

  @override
  Future<void> retrainPredictions(String userId) async {
    try {
      final productRepo = ProductRepoImpl();
      final saleRepo = SaleRepoImpl();

      final List<ProductModel> products = await productRepo.getAllProduct();
      final List<SaleModel> sales = await saleRepo.getAllSales();

      final settingsRepo = SettingsRepoImpl();
      final int weeklyOffDay = await settingsRepo.getWeeklyOffDay();

      final List<PredictionModel> predictions = _aiService.generateAllPredictions(
        products,
        sales,
        weeklyOffDay,
      );

      // Fetch outdated tracking profiles targeted for replacement
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .get();

      // FIXED: Refactored individual await deletions to run in a fast, single atomic write batch
      final batch = FirebaseServices().firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Save new predictions in a secondary performance-optimized batch sequence
      await savePredictions(predictions);
    } catch (e) {
      throw Exception('Failed to retrain predictions: $e');
    }
  }

  // US-38: Auto-retrain nightly scheduled routine
  Future<void> autoRetrainNightly() async {
    try {
      await retrainPredictions('current_user_id');
    } catch (e) {
      // Log structural analytics failure logs gracefully
    }
  }
}