import 'package:flutter/material.dart';
import '../model/sale_model.dart';
import '../repo/sale_repo_impl.dart';
import '../repo/sale_repo.dart';

class SaleViewModel extends ChangeNotifier {
  final SaleRepo _saleRepo = SaleRepoImpl();

  bool _loading = false;
  String? _error;
  List<SaleModel>? _sales;
  int _todaySales = 0;
  int _weeklySales = 0;
  int _monthlySales = 0;
  Map<String, int>? _topProducts;
  Map<String, int>? _bottomProducts;

  bool get loading => _loading;
  String? get error => _error;
  List<SaleModel>? get sales => _sales;
  int get todaySales => _todaySales;
  int get weeklySales => _weeklySales;
  int get monthlySales => _monthlySales;
  Map<String, int>? get topProducts => _topProducts;
  Map<String, int>? get bottomProducts => _bottomProducts;

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sale Operations
  Future<bool> addSale(SaleModel sale) async {
    setLoading(true);
    setError(null);
    try {
      await _saleRepo.addSale(sale);
      await getAllSales(); // Refresh the list
      await refreshSalesData(); // Refresh all sales metrics
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteSale(String id) async {
    setLoading(true);
    setError(null);
    try {
      await _saleRepo.deleteSale(id);
      await getAllSales(); // Refresh the list
      await refreshSalesData(); // Refresh all sales metrics
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateSale(SaleModel sale) async {
    setLoading(true);
    setError(null);
    try {
      await _saleRepo.updateSale(sale);
      await getAllSales(); // Refresh the list
      await refreshSalesData(); // Refresh all sales metrics
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getAllSales() async {
    setLoading(true);
    setError(null);
    try {
      _sales = await _saleRepo.getAllSales();
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getSalesForProduct(String productId) async {
    setLoading(true);
    setError(null);
    try {
      _sales = await _saleRepo.getSalesForProduct(productId);
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getTodaySales() async {
    setLoading(true);
    setError(null);
    try {
      _todaySales = await _saleRepo.getTodaySales();
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getWeeklySales() async {
    setLoading(true);
    setError(null);
    try {
      _weeklySales = await _saleRepo.getWeeklySales();
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getMonthlySales() async {
    setLoading(true);
    setError(null);
    try {
      _monthlySales = await _saleRepo.getMonthlySales();
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getTopProducts({int limit = 5}) async {
    setLoading(true);
    setError(null);
    try {
      _topProducts = await _saleRepo.getTopProducts(limit: limit);
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getBottomProducts({int limit = 5}) async {
    setLoading(true);
    setError(null);
    try {
      _bottomProducts = await _saleRepo.getBottomProducts(limit: limit);
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Refresh all sales data at once
  Future<void> refreshSalesData() async {
    await Future.wait([
      getTodaySales(),
      getWeeklySales(),
      getMonthlySales(),
      getTopProducts(),
      getBottomProducts(),
    ]);
  }

  // Helper methods
  void clearData() {
    _sales = null;
    _todaySales = 0;
    _weeklySales = 0;
    _monthlySales = 0;
    _topProducts = null;
    _bottomProducts = null;
    notifyListeners();
  }

  // Utility getters
  int get totalSalesCount => _sales?.length ?? 0;
  int get totalRevenue => _sales?.fold<int>(0, (sum, sale) => sum + sale.totalPrice) ?? 0;

  double get averageSaleValue {
    if (_sales == null || _sales!.isEmpty) return 0.0;
    return totalRevenue / _sales!.length;
  }
}