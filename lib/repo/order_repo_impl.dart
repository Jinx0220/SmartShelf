import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/order_model.dart';
import '../model/product_model.dart';
import '../model/prediction_model.dart';
import '../services/firebase_services.dart';
import 'order_repo.dart';

class OrderRepoImpl implements OrderRepo {
  final CollectionReference _collection =
  FirebaseServices().firestore.collection('orders');

  @override
  Future<OrderModel> generateSuggestedOrder(
      List<ProductModel> products,
      List<PredictionModel> predictions,
      ) async {
    List<OrderItemModel> items = [];

    for (var product in products) {
      final prediction = predictions.firstWhere(
            (p) => p.productId == product.id,
        orElse: () => PredictionModel(
          productId: product.id!,
          productName: product.name!,
          predictedQuantity: 0,
          confidenceLevel: 'Insufficient',
          generatedDate: DateTime.now(),
          forWeekStarting: DateTime.now(),
          explanationData: {},
        ),
      );

      final stockDeficit = (product.threshold ?? 0) - (product.stock ?? 0);
      final suggestedQty = stockDeficit + prediction.predictedQuantity;

      if (suggestedQty > 0) {
        items.add(OrderItemModel(
          productId: product.id!,
          productName: product.name!,
          suggestedQuantity: suggestedQty,
          finalQuantity: suggestedQty,
          currentStock: product.stock ?? 0,
          threshold: product.threshold ?? 0,
        ));
      }
    }

    items.sort((a, b) => b.suggestedQuantity.compareTo(a.suggestedQuantity));

    return OrderModel(
      items: items,
      generatedDate: DateTime.now(),
      isPlaced: false,
    );
  }

  @override
  Future<List<OrderModel>> getAllOrders() async {
    final snapshot = await _collection
        .orderBy('generatedDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>)
      ..id = doc.id)
        .toList();
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.data() as Map<String, dynamic>)
      ..id = doc.id;
  }

  @override
  Future<void> saveOrder(OrderModel order) async {
    final ref = _collection.doc(order.id);
    await ref.set(order.toMap());
  }

  @override
  Future<void> markOrderPlaced(String id) async {
    await _collection.doc(id).update({
      'isPlaced': true,
      'placedDate': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteOrder(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<String> exportOrderToCSV(OrderModel order) async {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('Product Name,Current Stock,Threshold,Prediction,Suggested Quantity');

    for (var item in order.items) {
      buffer.writeln(
        '${item.productName},${item.currentStock},${item.threshold},'
            '${item.suggestedQuantity},${item.finalQuantity}',
      );
    }

    return buffer.toString();
  }

  @override
  Future<String> generateOrderText(OrderModel order) async {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('*SmartShelf Order List*');
    buffer.writeln('Generated: ${order.generatedDate}');
    buffer.writeln('');

    for (var item in order.items) {
      buffer.writeln('${item.productName}: ${item.finalQuantity} units');
    }

    buffer.writeln('');
    buffer.writeln('Total Items: ${order.totalItems}');
    buffer.writeln('Total Quantity: ${order.totalQuantity}');

    return buffer.toString();
  }
}