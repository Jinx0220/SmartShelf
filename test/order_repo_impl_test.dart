import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartshelf/model/order_model.dart';
import 'package:smartshelf/repo/order_repo_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late OrderRepoImpl repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = OrderRepoImpl(firestore: firestore);
  });

  group('OrderRepoImpl Tests', () {
    test('saveOrder creates document and updates order.id if missing', () async {
      final order = OrderModel(
        items: [
          OrderItemModel(
            productId: 'prod_rice',
            productName: 'Rice 10kg',
            currentStock: 2,
            threshold: 5,
            suggestedQuantity: 15,
            finalQuantity: 20,
          ),
        ],
        generatedDate: DateTime.now(),
        isPlaced: false,
      );

      await repo.saveOrder(order);

      // Verify order ID was dynamically populated by repo
      expect(order.id, isNotNull);
      expect(order.id!.isNotEmpty, isTrue);

      // Verify Firestore persisted the document
      final doc = await firestore.collection('orders').doc(order.id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['isPlaced'], isFalse);
    });

    test('getAllOrders returns orders ordered by generatedDate descending', () async {
      final now = DateTime.now();
      final olderDate = now.subtract(const Duration(days: 2));

      final olderOrder = OrderModel(
        id: 'order_old',
        items: [],
        generatedDate: olderDate,
        isPlaced: true,
      );

      final newerOrder = OrderModel(
        id: 'order_new',
        items: [],
        generatedDate: now,
        isPlaced: false,
      );

      await repo.saveOrder(olderOrder);
      await repo.saveOrder(newerOrder);

      final result = await repo.getAllOrders();

      expect(result.length, 2);
      expect(result.first.id, 'order_new');
      expect(result.last.id, 'order_old');
    });

    test('getOrderById returns matching order model or null if absent', () async {
      final order = OrderModel(
        id: 'order_101',
        items: [],
        generatedDate: DateTime.now(),
        isPlaced: false,
      );

      await repo.saveOrder(order);

      final found = await repo.getOrderById('order_101');
      final notFound = await repo.getOrderById('non_existent_id');

      expect(found, isNotNull);
      expect(found!.id, 'order_101');
      expect(notFound, isNull);
    });

    test('completeAndRestockOrder atomically increments product stock and deletes order', () async {
      // 1. Seed a product with current stock of 10
      await firestore.collection('products').doc('prod_rice').set({
        'name': 'Rice',
        'stock': 10,
      });

      // 2. Prepare an order restocking 15 units of Rice
      final order = OrderModel(
        id: 'order_to_restock',
        items: [
          OrderItemModel(
            productId: 'prod_rice',
            productName: 'Rice',
            currentStock: 10,
            threshold: 5,
            suggestedQuantity: 15,
            finalQuantity: 15,
          ),
        ],
        generatedDate: DateTime.now(),
        isPlaced: true,
      );

      await repo.saveOrder(order);

      // 3. Execute atomic restock transaction
      await repo.completeAndRestockOrder(order);

      // Verify product stock was atomically incremented (10 + 15 = 25)
      final productDoc = await firestore.collection('products').doc('prod_rice').get();
      expect(productDoc.data()?['stock'], 25);

      // Verify the order document was removed from Firestore
      final orderDoc = await firestore.collection('orders').doc('order_to_restock').get();
      expect(orderDoc.exists, isFalse);
    });

    test('markOrderPlaced sets isPlaced to true and records placedDate', () async {
      final order = OrderModel(
        id: 'order_pending',
        items: [],
        generatedDate: DateTime.now(),
        isPlaced: false,
      );

      await repo.saveOrder(order);
      await repo.markOrderPlaced('order_pending');

      final updatedDoc = await firestore.collection('orders').doc('order_pending').get();
      expect(updatedDoc.data()?['isPlaced'], isTrue);
      expect(updatedDoc.data()?['placedDate'], isNotNull);
    });

    test('deleteOrder removes document from firestore', () async {
      final order = OrderModel(
        id: 'order_delete_me',
        items: [],
        generatedDate: DateTime.now(),
        isPlaced: false,
      );

      await repo.saveOrder(order);
      await repo.deleteOrder('order_delete_me');

      final found = await repo.getOrderById('order_delete_me');
      expect(found, isNull);
    });

    test('exportOrderToCSV formats items into RFC-compliant CSV text', () async {
      final order = OrderModel(
        id: 'csv_order',
        items: [
          OrderItemModel(
            productId: 'p1',
            productName: 'Soap',
            currentStock: 2,
            threshold: 5,
            suggestedQuantity: 10,
            finalQuantity: 12,
          ),
        ],
        generatedDate: DateTime.now(),
        isPlaced: false,
      );

      final csv = await repo.exportOrderToCSV(order);

      expect(csv, contains('Product Name,Current Stock,Threshold,Suggested Quantity,Final Quantity'));
      expect(csv, contains('"Soap",2,5,10,12'));
    });

    test('generateOrderText constructs human-readable WhatsApp message string', () async {
      final order = OrderModel(
        id: 'text_order',
        items: [
          OrderItemModel(
            productId: 'p1',
            productName: 'Milk 1L',
            currentStock: 1,
            threshold: 10,
            suggestedQuantity: 20,
            finalQuantity: 25,
          ),
        ],
        generatedDate: DateTime.now(),
        isPlaced: false,
      );

      final message = await repo.generateOrderText(order);

      expect(message, contains('SmartShelf Suggested Order Requirements'));
      expect(message, contains('• Milk 1L — Qty: 25 units (Current Stock: 1)'));
    });
  });
}