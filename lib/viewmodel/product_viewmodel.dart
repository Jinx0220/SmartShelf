import 'package:flutter/material.dart';
import '../model/product_model.dart';
import '../repo/product_repo.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductRepo _productRepo;

  ProductViewModel({required ProductRepo productRepo})
      : _productRepo = productRepo;

  bool _loading = false;
  String? _error;
  ProductModel? _product;
  List<ProductModel>? _allProducts;
  List<ProductModel>? _categoryProducts;
  List<ProductModel>? _searchProducts;
  List<ProductModel>? _lowStockProducts;

  // Getters
  bool get loading => _loading;
  String? get error => _error;
  ProductModel? get product => _product;
  List<ProductModel>? get allProducts => _allProducts;
  List<ProductModel>? get categoryProducts => _categoryProducts;
  List<ProductModel>? get searchProducts => _searchProducts;
  List<ProductModel>? get lowStockProducts => _lowStockProducts;

  // Setters
  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Add Product
  Future<bool> addProduct(ProductModel model) async {
    setLoading(true);
    setError(null);
    try {
      await _productRepo.addProduct(model);
      await getAllProduct();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Delete Product
  Future<bool> deleteProduct(String id) async {
    setLoading(true);
    setError(null);
    try {
      await _productRepo.deleteProduct(id);
      await getAllProduct();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Update Product
  Future<bool> updateProduct(ProductModel model) async {
    setLoading(true);
    setError(null);
    try {
      await _productRepo.updateProduct(model);
      await getAllProduct();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Get Product By ID
  Future<void> getProductById(String id) async {
    setLoading(true);
    setError(null);
    try {
      _product = await _productRepo.getProductById(id);
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Get All Products
  Future<void> getAllProduct() async {
    setLoading(true);
    setError(null);
    try {
      _allProducts = await _productRepo.getAllProduct();
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Get Products By Category
  Future<void> getProductByCategory(String category) async {
    setLoading(true);
    setError(null);
    try {
      _categoryProducts = await _productRepo.getProductByCategory(category);
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Search Products
  Future<void> searchProduct(String name) async {
    setLoading(true);
    setError(null);
    try {
      _searchProducts = await _productRepo.searchProduct(name);
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Get Low Stock Products
  Future<void> getLowStockProducts() async {
    setLoading(true);
    setError(null);
    try {
      _lowStockProducts = await _productRepo.getLowStockProducts();
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
}