import 'package:flutter/material.dart';
import '../model/sale_model.dart';
import '../repo/sale_repo.dart';

class SaleViewModel extends ChangeNotifier {
  final SaleRepo _saleRepo;

  SaleViewModel({required SaleRepo saleRepo}) : _saleRepo = saleRepo;

  bool _loading = false;
  String? _error;
  List<SaleModel>? _sales;
  List<SaleModel>? _productSales;
  int _todaySales = 0;
  int _weeklySales = 0;
  int _monthlySales = 0;
  Map<String, int>? _topProducts;
  Map<String, int>? _bottomProducts;

  // Getters
  bool get loading => _loading;
  String? get error => _error;
  List<SaleModel>? get sales => _sales;
  List<SaleModel>? get productSales => _productSales;
  int get todaySales => _todaySales;
  int get weeklySales => _weeklySales;
  int get monthlySales => _monthlySales;
  Map<String, int>? get topProducts => _topProducts;
  Map<String, int>? get bottomProducts => _bottomProducts;

  // Setters
  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Add Sale
  Future<bool> addSale(SaleModel sale) async {
    setLoading(true);
    setError(null);
    try {
      await _saleRepo.addSale(sale);
      await getAllSales();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Delete Sale
  Future<bool> deleteSale(String id) async {
    setLoading(true);
    setError(null);
    try {
      await _saleRepo.deleteSale(id);
      await getAllSales();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Update Sale
  Future<bool> updateSale(String id, int newQuantity) async {
    setLoading(true);
    setError(null);
    try {
      final sales = await _saleRepo.getAllSales();
      final sale = sales.firstWhere((s) => s.id == id);
      final updatedSale = sale.copyWith(
        quantity: newQuantity,
        totalPrice: sale.unitPrice * newQuantity,
      );
      await _saleRepo.updateSale(updatedSale);
      await getAllSales();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Get All Sales
  Future<void> getAllSales() async {
    setLoading(true);
    setError(null);
    try {
      _sales = await _saleRepo.getAllSales();
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Get Sales For Product
  Future<void> getSalesForProduct(String productId) async {
    setLoading(true);
    setError(null);
    try {
      _productSales = await _saleRepo.getSalesForProduct(productId);
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Get Today Sales
  Future<void> getTodaySales() async {
    setLoading(true);
    setError(null);
    try {
      _todaySales = await _saleRepo.getTodaySales();
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Get Weekly Sales
  Future<void> getWeeklySales() async {
    setLoading(true);
    setError(null);
    try {
      _weeklySales = await _saleRepo.getWeeklySales();
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Get Monthly Sales
  Future<void> getMonthlySales() async {
    setLoading(true);
    setError(null);
    try {
      _monthlySales = await _saleRepo.getMonthlySales();
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Get Top Products
  Future<void> getTopProducts({int limit = 5}) async {
    setLoading(true);
    setError(null);
    try {
      _topProducts = await _saleRepo.getTopProducts(limit: limit);
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Get Bottom Products
  Future<void> getBottomProducts({int limit = 5}) async {
    setLoading(true);
    setError(null);
    try {
      _bottomProducts = await _saleRepo.getBottomProducts(limit: limit);
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Clear Error
  void clearError() {
    setError(null);
  }

  // Refresh Dashboard
  Future<void> refreshDashboard() async {
    await Future.wait([
      getTodaySales(),
      getWeeklySales(),
      getMonthlySales(),
      getTopProducts(),
      getBottomProducts(),
      getAllSales(),
    ]);
  }
}