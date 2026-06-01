import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _criticalStockProducts = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<Product> get criticalStockProducts => _criticalStockProducts;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock products data
    _products = [
      Product(
        id: '1',
        name: 'Basmati Rice',
        stock: 5,
        threshold: 10,
        price: 300,
        category: 'Grocery',
        createdAt: DateTime.now(),
      ),
      Product(
        id: '2',
        name: 'MOMO Chutney',
        stock: 8,
        threshold: 5,
        price: 130,
        category: 'Snacks',
        createdAt: DateTime.now(),
      ),
      Product(
        id: '3',
        name: 'Cooking Oil',
        stock: 2,
        threshold: 8,
        price: 180,
        category: 'Grocery',
        createdAt: DateTime.now(),
      ),
      Product(
        id: '4',
        name: 'Milk 1L',
        stock: 0,
        threshold: 10,
        price: 90,
        category: 'Dairy',
        createdAt: DateTime.now(),
      ),
      Product(
        id: '5',
        name: 'Wheat Flour',
        stock: 2,
        threshold: 10,
        price: 60,
        category: 'Grocery',
        createdAt: DateTime.now(),
      ),
      Product(
        id: '6',
        name: 'Tea Leaves',
        stock: 1,
        threshold: 8,
        price: 120,
        category: 'Beverages',
        createdAt: DateTime.now(),
      ),
      Product(
        id: '7',
        name: 'Salt',
        stock: 22,
        threshold: 5,
        price: 20,
        category: 'Grocery',
        createdAt: DateTime.now(),
      ),
      Product(
        id: '8',
        name: 'Sugar',
        stock: 18,
        threshold: 5,
        price: 85,
        category: 'Grocery',
        createdAt: DateTime.now(),
      ),
    ];

    _criticalStockProducts = _products
        .where((p) => p.stock <= p.threshold)
        .take(5)
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    _products.add(product);
    _updateCriticalStock();
    notifyListeners();
  }

  Future<void> updateProduct(Product updatedProduct) async {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      _updateCriticalStock();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    _updateCriticalStock();
    notifyListeners();
  }

  void _updateCriticalStock() {
    _criticalStockProducts = _products
        .where((p) => p.stock <= p.threshold)
        .take(5)
        .toList();
  }
}