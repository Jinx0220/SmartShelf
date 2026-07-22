import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartshelf/model/sale_model.dart';
import 'package:smartshelf/repo/sale_repo_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SaleRepoImpl repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = SaleRepoImpl(firestore: firestore);
  });

  group('SaleRepoImpl Tests', () {
    test('addSale saves sale to firestore', () async {
      final sale = SaleModel(
        id: 'sale_1',
        productId: 'prod_100',
        productName: 'Rice',
        unitPrice: 120,
        quantity: 2,
        totalPrice: 240,
        timestamp: DateTime.now(),
      );

      await repo.addSale(sale);

      final doc = await firestore.collection('sales').doc('sale_1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()?['productId'], 'prod_100');
      expect(doc.data()?['productName'], 'Rice');
    });

    test('getAllSales returns sales sorted by timestamp descending', () async {
      final now = DateTime.now();

      await firestore.collection('sales').doc('sale_old').set({
        'id': 'sale_old',
        'productId': 'prod_1',
        'productName': 'Rice',
        'unitPrice': 100,
        'quantity': 1,
        'totalPrice': 100,
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      });

      await firestore.collection('sales').doc('sale_new').set({
        'id': 'sale_new',
        'productId': 'prod_2',
        'productName': 'Soap',
        'unitPrice': 100,
        'quantity': 2,
        'totalPrice': 200,
        'timestamp': Timestamp.fromDate(now),
      });

      final sales = await repo.getAllSales();

      expect(sales.length, 2);
      expect(sales.first.id, 'sale_new');
      expect(sales.last.id, 'sale_old');
    });

    test('updateSale updates existing sale document', () async {
      await firestore.collection('sales').doc('sale_1').set({
        'id': 'sale_1',
        'productId': 'prod_100',
        'productName': 'Rice',
        'unitPrice': 100,
        'quantity': 1,
        'totalPrice': 100,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });

      final updatedSale = SaleModel(
        id: 'sale_1',
        productId: 'prod_100',
        productName: 'Rice',
        unitPrice: 100,
        quantity: 5,
        totalPrice: 500,
        timestamp: DateTime.now(),
      );

      await repo.updateSale(updatedSale);

      final doc = await firestore.collection('sales').doc('sale_1').get();
      expect(doc.data()?['quantity'], 5);
      expect(doc.data()?['totalPrice'], 500);
    });

    test('deleteSale removes document from firestore', () async {
      await firestore.collection('sales').doc('sale_1').set({
        'id': 'sale_1',
        'productId': 'prod_100',
        'productName': 'Rice',
        'unitPrice': 100,
        'quantity': 1,
        'totalPrice': 100,
      });

      await repo.deleteSale('sale_1');

      final sales = await repo.getAllSales();
      expect(sales.isEmpty, isTrue);
    });

    test('getSalesForProduct filters sales by productId', () async {
      final now = DateTime.now();

      await firestore.collection('sales').add({
        'id': 'sale_1',
        'productId': 'rice_id',
        'productName': 'Rice',
        'unitPrice': 100,
        'quantity': 2,
        'totalPrice': 200,
        'timestamp': Timestamp.fromDate(now),
      });

      await firestore.collection('sales').add({
        'id': 'sale_2',
        'productId': 'soap_id',
        'productName': 'Soap',
        'unitPrice': 50,
        'quantity': 1,
        'totalPrice': 50,
        'timestamp': Timestamp.fromDate(now),
      });

      final riceSales = await repo.getSalesForProduct('rice_id');

      expect(riceSales.length, 1);
      expect(riceSales.first.productId, 'rice_id');
    });

    test('getTodaySales calculates total for today only', () async {
      final now = DateTime.now();
      final todayTime = DateTime(now.year, now.month, now.day, 10, 0);
      final yesterdayTime = todayTime.subtract(const Duration(days: 1));

      // Today's sale
      await firestore.collection('sales').add({
        'id': 'sale_today',
        'productId': 'prod_1',
        'productName': 'Rice',
        'unitPrice': 150,
        'quantity': 1,
        'totalPrice': 150,
        'timestamp': Timestamp.fromDate(todayTime),
      });

      // Yesterday's sale
      await firestore.collection('sales').add({
        'id': 'sale_yesterday',
        'productId': 'prod_1',
        'productName': 'Rice',
        'unitPrice': 300,
        'quantity': 1,
        'totalPrice': 300,
        'timestamp': Timestamp.fromDate(yesterdayTime),
      });

      final total = await repo.getTodaySales();

      expect(total, 150);
    });

    test('getWeeklySales calculates total for past 7 days', () async {
      final now = DateTime.now();
      final fiveDaysAgo = now.subtract(const Duration(days: 5));
      final tenDaysAgo = now.subtract(const Duration(days: 10));

      await firestore.collection('sales').add({
        'id': 'sale_recent',
        'productId': 'prod_1',
        'productName': 'Rice',
        'unitPrice': 200,
        'quantity': 1,
        'totalPrice': 200,
        'timestamp': Timestamp.fromDate(fiveDaysAgo),
      });

      await firestore.collection('sales').add({
        'id': 'sale_old',
        'productId': 'prod_1',
        'productName': 'Rice',
        'unitPrice': 500,
        'quantity': 1,
        'totalPrice': 500,
        'timestamp': Timestamp.fromDate(tenDaysAgo),
      });

      final total = await repo.getWeeklySales();

      expect(total, 200);
    });

    test('getMonthlySales calculates total from 1st of current month', () async {
      final now = DateTime.now();
      final currentMonthDate = DateTime(now.year, now.month, 2);

      await firestore.collection('sales').add({
        'id': 'sale_this_month',
        'productId': 'prod_1',
        'productName': 'Rice',
        'unitPrice': 400,
        'quantity': 1,
        'totalPrice': 400,
        'timestamp': Timestamp.fromDate(currentMonthDate),
      });

      final total = await repo.getMonthlySales();

      expect(total, 400);
    });

    test('getTopProducts ranks products by total quantity sold descending', () async {
      final now = DateTime.now();

      await firestore.collection('sales').add({
        'id': '1',
        'productId': 'prod_A',
        'productName': 'Rice',
        'unitPrice': 10,
        'quantity': 10,
        'totalPrice': 100,
        'timestamp': Timestamp.fromDate(now),
      });

      await firestore.collection('sales').add({
        'id': '2',
        'productId': 'prod_B',
        'productName': 'Soap',
        'unitPrice': 10,
        'quantity': 25,
        'totalPrice': 250,
        'timestamp': Timestamp.fromDate(now),
      });

      final topProducts = await repo.getTopProducts(limit: 2);

      expect(topProducts.keys.first, 'prod_B');
      expect(topProducts['prod_B'], 25);
    });

    test('getBottomProducts ranks products by total quantity sold ascending', () async {
      final now = DateTime.now();

      await firestore.collection('sales').add({
        'id': '1',
        'productId': 'prod_A',
        'productName': 'Rice',
        'unitPrice': 10,
        'quantity': 10,
        'totalPrice': 100,
        'timestamp': Timestamp.fromDate(now),
      });

      await firestore.collection('sales').add({
        'id': '2',
        'productId': 'prod_B',
        'productName': 'Soap',
        'unitPrice': 10,
        'quantity': 25,
        'totalPrice': 250,
        'timestamp': Timestamp.fromDate(now),
      });

      final bottomProducts = await repo.getBottomProducts(limit: 2);

      expect(bottomProducts.keys.first, 'prod_A');
      expect(bottomProducts['prod_A'], 10);
    });
  });
}