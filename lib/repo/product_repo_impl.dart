import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product_model.dart';
import 'product_repo.dart';

class ProductRepoImpl implements ProductRepo {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('products');

  @override
  Future<void> addProduct(ProductModel model) async {
    try {
      final ref = _collection.doc();
      final newModel = model.copyWith(id: ref.id);
      await ref.set(newModel.toMap());
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  Future<void> updateProduct(ProductModel model) async {
    try {
      if (model.id == null) {
        throw Exception('Product ID is null');
      }
      await _collection.doc(model.id).update(model.toMap());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return ProductModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ProductModel>> getAllProduct() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getProductByCategory(String category) async {
    try {
      final snapshot = await _collection
          .where('category', isEqualTo: category)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<ProductModel>> searchProduct(String name) async {
    try {
      final snapshot = await _collection
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThan: '$name\uf8ff')
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getLowStockProducts() async {
    try {
      final products = await getAllProduct();
      return products.where((p) => p.isLowStock).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getCriticalStockProducts() async {
    try {
      final products = await getAllProduct();
      return products.where((p) => p.isOutOfStock).toList();
    } catch (e) {
      return [];
    }
  }
}