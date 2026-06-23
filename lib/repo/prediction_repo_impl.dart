import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/prediction_model.dart';
import '../model/product_model.dart';
import '../model/sale_model.dart';
import '../services/ai_prediction_service.dart';
import '../services/firebase_services.dart';
import 'prediction_repo.dart';

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
    final ref = _collection.doc(prediction.id);
    await ref.set(prediction.toMap());
  }

  @override
  Future<void> savePredictions(List<PredictionModel> predictions) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var prediction in predictions) {
      final ref = _collection.doc(prediction.id ??
          '${prediction.productId}_${DateTime.now().millisecondsSinceEpoch}');
      batch.set(ref, prediction.toMap());
    }
    await batch.commit();
  }

  @override
  Future<List<PredictionModel>> getAllPredictions() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => PredictionModel.fromMap(doc.data() as Map<String, dynamic>)
      ..id = doc.id)
        .toList();
  }

  @override
  Future<PredictionModel?> getPredictionForProduct(String productId) async {
    final snapshot = await _collection
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return PredictionModel.fromMap(doc.data() as Map<String, dynamic>)
      ..id = doc.id;
  }

  @override
  Future<void> updatePrediction(String productId, int newQuantity) async {
    final snapshot = await _collection
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'predictedQuantity': newQuantity,
      });
    }
  }

  @override
  Future<void> deletePrediction(String productId) async {
    final snapshot = await _collection
        .where('productId', isEqualTo: productId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<Map<String, double>> getPredictionAccuracy() async {
    final predictions = await getAllPredictions();
    Map<String, double> accuracy = {};

    for (var pred in predictions) {
      if (pred.actualQuantity != null) {
        accuracy[pred.productId] = _aiService.calculateAccuracy(
          pred,
          pred.actualQuantity!,
        );
      }
    }
    return accuracy;
  }

  @override
  Future<void> retrainPredictions(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}