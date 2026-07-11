import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product_model.dart';
import 'product_repo.dart';

class ProductRepoImpl implements ProductRepo {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('products');

  @override
  Future<void> addProduct(ProductModel model) async {
    try {
      // --- ADD THIS CHECK ---
      // Query to check if any product with this name exists (case-sensitive)
      final existing = await _collection.where('name', isEqualTo: model.name).get();
      if (existing.docs.isNotEmpty) {
        throw Exception('A product with the name "${model.name}" already exists.');
      }
      // ----------------------

      final ref = _collection.doc();
      final newModel = model.copyWith(id: ref.id);
      await ref.set(newModel.toMap());
    } catch (e) {
      // Re-throw the exception so the ViewModel catches it and shows the toast/snack
      throw Exception(e.toString().replaceAll("Exception: ", ""));
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
  Future<void> deleteAllProducts() async {
    try {
      final snapshot = await _collection.get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear database: $e');
    }
  }

  @override
  Future<void> batchInsertProducts(List<ProductModel> products) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var product in products) {
        // Fallback to auto-generated document ID if model lacks an initialization ID
        final docRef = product.id != null && product.id!.isNotEmpty
            ? _collection.doc(product.id)
            : _collection.doc();

        final initializedProduct = product.id != null && product.id!.isNotEmpty
            ? product
            : product.copyWith(id: docRef.id);

        batch.set(docRef, initializedProduct.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to execute batch restore operation: $e');
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