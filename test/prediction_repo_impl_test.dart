import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartshelf/model/prediction_model.dart';
import 'package:smartshelf/repo/prediction_repo_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late PredictionRepoImpl repo;
  final now = DateTime.now();

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = PredictionRepoImpl(firestore: firestore);
  });

  // Helper function to build dummy PredictionModel instances
  PredictionModel buildPrediction({
    String? id,
    required String productId,
    required String productName,
    required int predictedQuantity,
  }) {
    return PredictionModel(
      id: id,
      productId: productId,
      productName: productName,
      predictedQuantity: predictedQuantity,
      confidenceLevel: 'High', // Changed from 0.85 (double) to 'High' (String)
      explanationData: const {},
      forWeekStarting: now,
      generatedDate: now,
    );
  }

  group('PredictionRepoImpl Tests', () {
    test('savePrediction stores prediction doc in Firestore', () async {
      final prediction = buildPrediction(
        id: 'prediction_1',
        productId: 'prod_100',
        productName: 'Rice 10kg',
        predictedQuantity: 45,
      );

      await repo.savePrediction(prediction);

      final doc = await firestore.collection('predictions').doc('prediction_1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['productId'], 'prod_100');
      expect(doc.data()?['predictedQuantity'], 45);
    });

    test('savePredictions batch stores multiple predictions', () async {
      final predictions = [
        buildPrediction(
          id: 'prediction_1',
          productId: 'prod_1',
          productName: 'Soap',
          predictedQuantity: 10,
        ),
        buildPrediction(
          id: 'prediction_2',
          productId: 'prod_2',
          productName: 'Milk',
          predictedQuantity: 20,
        ),
      ];

      await repo.savePredictions(predictions);

      final snapshot = await firestore.collection('predictions').get();
      expect(snapshot.docs.length, 2);
    });

    test('getAllPredictions fetches all stored prediction documents', () async {
      final p1 = buildPrediction(
        id: 'prediction_1',
        productId: 'prod_1',
        productName: 'Rice',
        predictedQuantity: 30,
      );
      final p2 = buildPrediction(
        id: 'prediction_2',
        productId: 'prod_2',
        productName: 'Oil',
        predictedQuantity: 15,
      );

      await firestore.collection('predictions').doc('prediction_1').set(p1.toMap());
      await firestore.collection('predictions').doc('prediction_2').set(p2.toMap());

      final results = await repo.getAllPredictions();

      expect(results.length, 2);
      expect(results.any((p) => p.productId == 'prod_1'), isTrue);
      expect(results.any((p) => p.productId == 'prod_2'), isTrue);
    });

    test('getPredictionForProduct returns prediction matching productId', () async {
      final p1 = buildPrediction(
        id: 'prediction_1',
        productId: 'target_prod',
        productName: 'Flour',
        predictedQuantity: 50,
      );

      await firestore.collection('predictions').doc('prediction_1').set(p1.toMap());

      final result = await repo.getPredictionForProduct('target_prod');

      expect(result, isNotNull);
      expect(result?.productId, 'target_prod');
      expect(result?.predictedQuantity, 50);
    });

    test('updatePrediction modifies predictedQuantity for matching product', () async {
      final p1 = buildPrediction(
        id: 'prediction_1',
        productId: 'prod_update',
        productName: 'Sugar',
        predictedQuantity: 10,
      );

      await firestore.collection('predictions').doc('prediction_1').set(p1.toMap());

      await repo.updatePrediction('prod_update', 35);

      final doc = await firestore.collection('predictions').doc('prediction_1').get();
      expect(doc.data()?['predictedQuantity'], 35);
    });

    test('deletePrediction removes all prediction docs matching productId', () async {
      final p1 = buildPrediction(
        id: 'prediction_1',
        productId: 'prod_delete',
        productName: 'Tea',
        predictedQuantity: 5,
      );

      await firestore.collection('predictions').doc('prediction_1').set(p1.toMap());

      await repo.deletePrediction('prod_delete');

      final result = await repo.getPredictionForProduct('prod_delete');
      expect(result, isNull);
    });
  });
}