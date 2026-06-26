import 'package:flutter/material.dart';
import '../model/product_model.dart';
import '../repo/product_repo_impl.dart';
import '../repo/product_repo.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductRepo _productRepo = ProductRepoImpl();

  bool _loading = false;
  String? _error;
  ProductModel? _product;
  List<ProductModel>? _allProducts;
  List<ProductModel>? _categoryProducts;
  List<ProductModel>? _searchProducts;
  List<ProductModel>? _lowStockProducts;

  bool get loading => _loading;
  String? get error => _error;
  ProductModel? get product => _product;
  List<ProductModel>? get allProducts => _allProducts;
  List<ProductModel>? get categoryProducts => _categoryProducts;
  List<ProductModel>? get searchProducts => _searchProducts;
  List<ProductModel>? get lowStockProducts => _lowStockProducts;

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

  // Product CRUD Operations
  Future<bool> addProduct(ProductModel model) async {
    setLoading(true);
    setError(null);
    try {
      await _productRepo.addProduct(model);
      await getAllProduct(); // Refresh the list
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteProduct(String id) async {
    setLoading(true);
    setError(null);
    try {
      await _productRepo.deleteProduct(id);
      await getAllProduct(); // Refresh the list
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateProduct(ProductModel model) async {
    setLoading(true);
    setError(null);
    try {
      await _productRepo.updateProduct(model);
      await getAllProduct(); // Refresh the list
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getProductById(String id) async {
    setLoading(true);
    setError(null);
    try {
      _product = await _productRepo.getProductById(id);
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getAllProduct() async {
    setLoading(true);
    setError(null);
    try {
      _allProducts = await _productRepo.getAllProduct();
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getProductByCategory(String category) async {
    setLoading(true);
    setError(null);
    try {
      _categoryProducts = await _productRepo.getProductByCategory(category);
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> searchProduct(String name) async {
    setLoading(true);
    setError(null);
    try {
      _searchProducts = await _productRepo.searchProduct(name);
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getLowStockProducts() async {
    setLoading(true);
    setError(null);
    try {
      _lowStockProducts = await _productRepo.getLowStockProducts();
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> getCriticalStockProducts() async {
    setLoading(true);
    setError(null);
    try {
      _criticalStockProducts = await _productRepo.getCriticalStockProducts();
      notifyListeners();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Additional getters for critical stock
  List<ProductModel>? _criticalStockProducts;
  List<ProductModel>? get criticalStockProducts => _criticalStockProducts;

  // Helper methods
  void clearData() {
    _product = null;
    _allProducts = null;
    _categoryProducts = null;
    _searchProducts = null;
    _lowStockProducts = null;
    _criticalStockProducts = null;
    notifyListeners();
  }

  // Utility getters
  int get totalProducts => _allProducts?.length ?? 0;
  int get lowStockCount => _lowStockProducts?.length ?? 0;
  int get criticalStockCount => _criticalStockProducts?.length ?? 0;
}