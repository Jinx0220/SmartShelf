import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/sale_model.dart';
import 'sale_repo.dart';

class SaleRepoImpl implements SaleRepo {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('sales');

  @override
  Future<void> addSale(SaleModel sale) async {
    try {
      final docRef = _collection.doc();
      final data = sale.toMap();
      data['id'] = docRef.id;
      await docRef.set(data);
    } catch (e) {
      throw Exception('Failed to add sale: $e');
    }
  }

  @override
  Future<void> deleteSale(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete sale: $e');
    }
  }

  @override
  Future<void> updateSale(SaleModel sale) async {
    try {
      if (sale.id == null) {
        throw Exception('Sale ID is required for update');
      }
      await _collection.doc(sale.id).update(sale.toMap());
    } catch (e) {
      throw Exception('Failed to update sale: $e');
    }
  }

  @override
  Future<List<SaleModel>> getAllSales() async {
    try {
      final querySnapshot = await _collection
          .orderBy('timestamp', descending: true)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SaleModel.fromMap(data, id: doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all sales: $e');
    }
  }

  @override
  Future<List<SaleModel>> getSalesForProduct(String productId) async {
    try {
      final querySnapshot = await _collection
          .where('productId', isEqualTo: productId)
          .orderBy('timestamp', descending: true)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SaleModel.fromMap(data, id: doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get sales for product: $e');
    }
  }

  @override
  Future<int> getTodaySales() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _collection
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .get();

      return querySnapshot.docs.fold<int>(
        0,
            (sum, doc) => sum + (doc.data() as Map<String, dynamic>)['totalPrice'] as int,
      );
    } catch (e) {
      throw Exception('Failed to get today sales: $e');
    }
  }

  @override
  Future<int> getWeeklySales() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      final querySnapshot = await _collection
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .get();

      return querySnapshot.docs.fold<int>(
        0,
            (sum, doc) => sum + (doc.data() as Map<String, dynamic>)['totalPrice'] as int,
      );
    } catch (e) {
      throw Exception('Failed to get weekly sales: $e');
    }
  }

  @override
  Future<int> getMonthlySales() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final querySnapshot = await _collection
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      return querySnapshot.docs.fold<int>(
        0,
            (sum, doc) => sum + (doc.data() as Map<String, dynamic>)['totalPrice'] as int,
      );
    } catch (e) {
      throw Exception('Failed to get monthly sales: $e');
    }
  }

  @override
  Future<Map<String, int>> getTopProducts({int limit = 5}) async {
    try {
      final allSales = await getAllSales();
      final productSales = <String, int>{};

      for (var sale in allSales) {
        productSales[sale.productId] =
            (productSales[sale.productId] ?? 0) + sale.quantity;
      }

      final sortedEntries = productSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries.take(limit));
    } catch (e) {
      throw Exception('Failed to get top products: $e');
    }
  }

  @override
  Future<Map<String, int>> getBottomProducts({int limit = 5}) async {
    try {
      final allSales = await getAllSales();
      final productSales = <String, int>{};

      for (var sale in allSales) {
        productSales[sale.productId] =
            (productSales[sale.productId] ?? 0) + sale.quantity;
      }

      final sortedEntries = productSales.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      return Map.fromEntries(sortedEntries.take(limit));
    } catch (e) {
      throw Exception('Failed to get bottom products: $e');
    }
  }
}