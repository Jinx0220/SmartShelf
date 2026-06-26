import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product_model.dart';
import 'product_repo.dart';

class ProductRepoImpl implements ProductRepo {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('products');

  @override
  Future<void> addProduct(ProductModel model) async {
    try {
      final docRef = _collection.doc();
      final data = model.toMap();
      data['id'] = docRef.id;
      await docRef.set(data);
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
        throw Exception('Product ID is required for update');
      }
      final data = model.toMap();
      data['updatedAt'] = Timestamp.now();
      await _collection.doc(model.id).update(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Product not found');
      }
      final data = doc.data() as Map<String, dynamic>;
      return ProductModel.fromMap(data, id: doc.id);
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  @override
  Future<List<ProductModel>> getAllProduct() async {
    try {
      final querySnapshot = await _collection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromMap(data, id: doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProductByCategory(String category) async {
    try {
      final querySnapshot = await _collection
          .where('category', isEqualTo: category)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromMap(data, id: doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  @override
  Future<List<ProductModel>> searchProduct(String name) async {
    try {
      // Firebase doesn't support full-text search natively
      // This is a simple implementation using startsWith
      final querySnapshot = await _collection
          .orderBy('name')
          .startAt([name])
          .endAt(['$name\uf8ff'])
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromMap(data, id: doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getLowStockProducts() async {
    try {
      // Get all products and filter in memory for better accuracy
      final allProducts = await getAllProduct();
      return allProducts.where((product) => product.isLowStock).toList();
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  @override
  Future<List<ProductModel>> getCriticalStockProducts() async {
    try {
      // Products with stock at or below 10% of threshold
      final allProducts = await getAllProduct();
      return allProducts.where((product) {
        final criticalThreshold = (product.threshold * 0.1).ceil();
        return product.stock <= criticalThreshold && product.stock > 0;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get critical stock products: $e');
    }
  }
}