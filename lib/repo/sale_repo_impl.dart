import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/sale_model.dart';
import 'sale_repo.dart';

class SaleRepoImpl implements SaleRepo {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('sales');

  @override
  Future<void> addSale(SaleModel sale) async {
    try {
      final ref = _collection.doc(sale.id);
      await ref.set(sale.toMap());
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
      await _collection.doc(sale.id).update(sale.toMap());
    } catch (e) {
      throw Exception('Failed to update sale: $e');
    }
  }

  @override
  Future<List<SaleModel>> getAllSales() async {
    try {
      final snapshot = await _collection
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SaleModel.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> batchInsertSales(List<SaleModel> sales) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var sale in sales) {
        final docRef = sale.id.isNotEmpty
            ? _collection.doc(sale.id)
            : _collection.doc();

        final initializedSale = sale.id.isNotEmpty
            ? sale
            : sale.copyWith(id: docRef.id);

        batch.set(docRef, initializedSale.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to execute batch restore operation for sales: $e');
    }
  }

  @override
  Future<List<SaleModel>> getSalesForProduct(String productId) async {
    try {
      final snapshot = await _collection
          .where('productId', isEqualTo: productId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SaleModel.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<int> getTodaySales() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final snapshot = await _collection
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('timestamp', isLessThan: Timestamp.fromDate(tomorrow))
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // FIXED: Safe conversion from num to int prevents silent casting crashes
        total += (data['totalPrice'] as num?)?.toInt() ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> getWeeklySales() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));

      final snapshot = await _collection
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // FIXED: Safe conversion from num to int prevents silent casting crashes
        total += (data['totalPrice'] as num?)?.toInt() ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> getMonthlySales() async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await _collection
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // FIXED: Safe conversion from num to int prevents silent casting crashes
        total += (data['totalPrice'] as num?)?.toInt() ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<Map<String, int>> getTopProducts({int limit = 5}) async {
    try {
      final sales = await getAllSales();
      Map<String, int> productSales = {};

      for (var sale in sales) {
        productSales[sale.productId] =
            (productSales[sale.productId] ?? 0) + sale.quantity;
      }

      final sorted = productSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sorted.take(limit));
    } catch (e) {
      return {};
    }
  }

  @override
  Future<Map<String, int>> getBottomProducts({int limit = 5}) async {
    try {
      final sales = await getAllSales();
      Map<String, int> productSales = {};

      for (var sale in sales) {
        productSales[sale.productId] =
            (productSales[sale.productId] ?? 0) + sale.quantity;
      }

      final sorted = productSales.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      return Map.fromEntries(sorted.take(limit));
    } catch (e) {
      return {};
    }
  }
}