// File: lib/repo/order_repo_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/order_model.dart';
import '../model/product_model.dart';
import '../model/prediction_model.dart';
import 'order_repo.dart';

class OrderRepoImpl implements OrderRepo {
  final FirebaseFirestore _firestore;

  OrderRepoImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Reference pointing directly to your Firestore collection
  CollectionReference get _collection => _firestore.collection('orders');

  @override
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final snapshot = await _collection.orderBy('generatedDate', descending: true).get();
      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>, documentId: doc.id);
      }).toList();
    } catch (e) {
      throw Exception("Failed to fetch historical orders from Cloud Firestore: $e");
    }
  }

  @override
  Future<void> completeAndRestockOrder(OrderModel order) async {
    try {
      final batch = _firestore.batch();

      // 1. Loop through each item in the order and increment the product's inventory
      for (var item in order.items) {
        if (item.productId.isNotEmpty) {
          final productRef = _firestore.collection('products').doc(item.productId);

          // FieldValue.increment is atomic and safe from multi-user race conditions
          batch.update(productRef, {
            'stock': FieldValue.increment(item.finalQuantity),
          });
        }
      }

      // 2. Delete the order document so it immediately vanishes from active history lists
      final orderRef = _collection.doc(order.id);
      batch.delete(orderRef);

      // Commit all changes simultaneously to Firebase
      await batch.commit();
    } catch (e) {
      throw Exception("Failed to execute atomic restock transaction: $e");
    }
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      return OrderModel.fromMap(doc.data() as Map<String, dynamic>, documentId: doc.id);
    } catch (e) {
      throw Exception("Failed to get order $id: $e");
    }
  }

  @override
  Future<void> saveOrder(OrderModel order) async {
    try {
      // Fallback safeguard to guarantee a valid document key identifier exists
      final docId = (order.id != null && order.id!.isNotEmpty)
          ? order.id!
          : _collection.doc().id;

      order.id = docId;

      // set with merge handles updates or new insertions cleanly
      await _collection.doc(docId).set(order.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception("Firestore database write transaction rejected: $e");
    }
  }

  @override
  Future<void> markOrderPlaced(String id) async {
    try {
      await _collection.doc(id).update({
        'isPlaced': true,
        'placedDate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception("Failed to update placement status in Firestore: $e");
    }
  }

  @override
  Future<void> deleteOrder(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception("Failed to delete Firestore document: $e");
    }
  }

  @override
  Future<String> exportOrderToCSV(OrderModel order) async {
    final buffer = StringBuffer();
    buffer.writeln("Product Name,Current Stock,Threshold,Suggested Quantity,Final Quantity");
    for (var item in order.items) {
      buffer.writeln('"${item.productName}",${item.currentStock},${item.threshold},${item.suggestedQuantity},${item.finalQuantity}');
    }
    return buffer.toString();
  }

  @override
  Future<String> generateOrderText(OrderModel order) async {
    final buffer = StringBuffer();
    buffer.writeln("📦 SmartShelf Suggested Order Requirements");
    buffer.writeln("Generated: ${order.generatedDate.toLocal()}");
    buffer.writeln("=========================================");
    for (var item in order.items) {
      buffer.writeln("• ${item.productName} — Qty: ${item.finalQuantity} units (Current Stock: ${item.currentStock})");
    }
    return buffer.toString();
  }

  @override
  Future<OrderModel> generateSuggestedOrder(
      List<ProductModel> products,
      List<PredictionModel> predictions,
      ) async {
    // Note: The UI calculation logic is already processed directly by your ViewModel.
    // This override satisfies your repository contract safely.
    return OrderModel(
      items: [],
      generatedDate: DateTime.now(),
      isPlaced: false,
    );
  }
}