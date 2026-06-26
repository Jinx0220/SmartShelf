import '../model/sale_model.dart';

abstract class SaleRepo {
  Future<void> addSale(SaleModel sale);
  Future<void> deleteSale(String id);
  Future<void> updateSale(SaleModel sale);
  Future<List<SaleModel>> getAllSales();
  Future<List<SaleModel>> getSalesForProduct(String productId);
  Future<int> getTodaySales();
  Future<int> getWeeklySales();
  Future<int> getMonthlySales();
  Future<Map<String, int>> getTopProducts({int limit = 5});
  Future<Map<String, int>> getBottomProducts({int limit = 5});
}