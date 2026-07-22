import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartshelf/model/product_model.dart';
import 'package:smartshelf/repo/product_repo_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProductRepoImpl repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = ProductRepoImpl(firestore: firestore);
  });

  group('Product Repository Tests', () {
    test('Add Product', () async {
      final product = ProductModel(
        name: 'Rice',
        category: 'Food',
        stock: 20,
        threshold: 5,
        price: 120,
      );

      await repo.addProduct(product);

      final list = await repo.getAllProduct();

      expect(list.length, 1);
      expect(list.first.name, 'Rice');
    });

    test('Duplicate Product Throws Exception', () async {
      final product = ProductModel(
        name: 'Rice',
        category: 'Food',
        stock: 20,
        threshold: 5,
        price: 120,
      );

      await repo.addProduct(product);

      expect(
            () async => await repo.addProduct(product),
        throwsException,
      );
    });

    test('Get Product By ID', () async {
      final doc = firestore.collection('products').doc();

      final product = ProductModel(
        id: doc.id,
        name: 'Soap',
        category: 'Daily',
        stock: 10,
        threshold: 2,
        price: 80,
      );

      await doc.set(product.toMap());

      final result = await repo.getProductById(doc.id);

      expect(result, isNotNull);
      expect(result!.name, 'Soap');
    });

    test('Update Product', () async {
      final doc = firestore.collection('products').doc();

      final product = ProductModel(
        id: doc.id,
        name: 'Soap',
        category: 'Daily',
        stock: 10,
        threshold: 2,
        price: 80,
      );

      await doc.set(product.toMap());

      final updated = product.copyWith(
        stock: 50,
      );

      await repo.updateProduct(updated);

      final result = await repo.getProductById(doc.id);

      expect(result!.stock, 50);
    });

    test('Delete Product', () async {
      final doc = firestore.collection('products').doc();

      final product = ProductModel(
        id: doc.id,
        name: 'Soap',
        category: 'Daily',
        stock: 10,
        threshold: 2,
        price: 80,
      );

      await doc.set(product.toMap());

      await repo.deleteProduct(doc.id);

      final result = await repo.getAllProduct();

      expect(result.isEmpty, true);
    });

    test('Search Product', () async {
      await firestore.collection('products').add({
        'id': '1',
        'name': 'Rice',
        'category': 'Food',
        'stock': 20,
        'threshold': 5,
        'price': 100,
      });

      await firestore.collection('products').add({
        'id': '2',
        'name': 'Soap',
        'category': 'Daily',
        'stock': 5,
        'threshold': 2,
        'price': 50,
      });

      final result = await repo.searchProduct('Ri');

      expect(result.length, 1);
      expect(result.first.name, 'Rice');
    });

    test('Get Low Stock Products', () async {
      await firestore.collection('products').add({
        'id': '1',
        'name': 'Rice',
        'category': 'Food',
        'stock': 2,
        'threshold': 5,
        'price': 100,
      });

      await firestore.collection('products').add({
        'id': '2',
        'name': 'Soap',
        'category': 'Daily',
        'stock': 20,
        'threshold': 5,
        'price': 50,
      });

      final result = await repo.getLowStockProducts();

      expect(result.length, 1);
      expect(result.first.name, 'Rice');
    });
  });
}