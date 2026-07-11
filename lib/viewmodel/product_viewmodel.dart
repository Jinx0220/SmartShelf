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

  void setLoading(bool value) {
    if (_loading != value) {
      _loading = value;
      notifyListeners();
    }
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<bool> addProduct(ProductModel product) async {
    setError(null);

    if (_allProducts == null) {
      setLoading(true);
      try {
        _allProducts = await _productRepo.getAllProduct();
      } catch (e) {
        setError("Failed to verify catalog uniqueness: ${e.toString()}");
        setLoading(false);
        return false;
      }
    }

    final isDuplicate = _allProducts?.any((existingProduct) =>
    existingProduct.name.trim().toLowerCase() == product.name.trim().toLowerCase()
    ) ?? false;

    if (isDuplicate) {
      setError("A product with the name '${product.name}' already exists.");
      setLoading(false);
      return false;
    }

    setLoading(true);
    try {
      await _productRepo.addProduct(product);
      _allProducts = await _productRepo.getAllProduct();
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

      _allProducts?.removeWhere((p) => p.id == id);
      _categoryProducts?.removeWhere((p) => p.id == id);
      _searchProducts?.removeWhere((p) => p.id == id);
      _lowStockProducts?.removeWhere((p) => p.id == id);

      notifyListeners();
      _allProducts = await _productRepo.getAllProduct();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateProduct(ProductModel model) async {
    setError(null);

    if (_allProducts == null) {
      setLoading(true);
      try {
        _allProducts = await _productRepo.getAllProduct();
      } catch (e) {
        setError("Failed to verify update uniqueness.");
        setLoading(false);
        return false;
      }
    }

    final isDuplicateName = _allProducts?.any((existingProduct) =>
    existingProduct.id != model.id &&
        existingProduct.name.trim().toLowerCase() == model.name.trim().toLowerCase()
    ) ?? false;

    if (isDuplicateName) {
      setError("Cannot update: A different product with the name '${model.name}' already exists.");
      return false;
    }

    bool localUpdated = false;

    void updateInList(List<ProductModel>? list) {
      if (list == null) return;
      final index = list.indexWhere((p) => p.id == model.id);
      if (index != -1) {
        list[index] = model;
        localUpdated = true;
      }
    }

    updateInList(_allProducts);
    updateInList(_categoryProducts);
    updateInList(_searchProducts);

    if (_lowStockProducts != null) {
      final index = _lowStockProducts!.indexWhere((p) => p.id == model.id);
      if (index != -1) {
        if (model.stock <= model.threshold) {
          _lowStockProducts![index] = model;
        } else {
          _lowStockProducts!.removeAt(index);
        }
        localUpdated = true;
      } else if (model.stock <= model.threshold) {
        _lowStockProducts!.add(model);
        localUpdated = true;
      }
    }

    if (localUpdated) {
      notifyListeners();
    } else {
      setLoading(true);
    }

    try {
      await _productRepo.updateProduct(model);
      _allProducts = await _productRepo.getAllProduct();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

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

  void clearLocalCacheData() {
    _allProducts = []; // 🟢 Prevents any Null Check operator crashes in your UI lists
    notifyListeners();
  }

  Future<void> getAllProduct() async {
    setLoading(true);
    setError(null);
    try {
      _allProducts = await _productRepo.getAllProduct();
      // REMOVED: notifyListeners() from here because setLoading(false) handles it below
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

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

  Future<void> clearAllProductsBatch() async {
    _loading = true;
    notifyListeners();
    try {
      await _productRepo.deleteAllProducts();
      _allProducts = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> restoreProductsFromJson(List<dynamic> jsonList) async {
    _loading = true;
    notifyListeners();
    try {
      final restoredList = jsonList.map((e) => ProductModel.fromMap(e as Map<String, dynamic>)).toList();
      await _productRepo.batchInsertProducts(restoredList);
      _allProducts = restoredList;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // NEW: Process raw spreadsheet fields and batch insert demo rows into Firestore
  Future<bool> importProductsFromCsv(List<List<dynamic>> csvRows) async {
    setLoading(true);
    setError(null);
    try {
      if (csvRows.isEmpty) {
        setError("The selected CSV file contains no data rows.");
        return false;
      }

      // Check if row 0 contains text labels (headers like 'name', 'price') and skip it if true
      int startIndex = 0;
      if (csvRows.first.isNotEmpty &&
          csvRows.first.first.toString().toLowerCase().contains('name')) {
        startIndex = 1;
      }

      List<ProductModel> productsToInsert = [];
      for (int i = startIndex; i < csvRows.length; i++) {
        final row = csvRows[i];
        // Skip empty lines or trailing structural anomalies
        if (row.isEmpty || row[0].toString().trim().isEmpty) continue;

        // Formulate a sequential, non-colliding identity string
        String generatedId = "demo_${DateTime.now().millisecondsSinceEpoch}_$i";
        final product = ProductModel.fromCsvRow(row, generatedId);
        productsToInsert.add(product);
      }

      if (productsToInsert.isEmpty) {
        setError("No valid products could be extracted from the CSV file structure.");
        return false;
      }

      // Perform a transactional or structural batch upload
      await _productRepo.batchInsertProducts(productsToInsert);

      // Pull fresh data from cloud repository to synchronize client state cache completely
      _allProducts = await _productRepo.getAllProduct();

      if (_lowStockProducts != null) {
        await getLowStockProducts();
      }

      notifyListeners();
      return true;
    } catch (e, stacktrace) {
      print("🚨 CRITICAL CSV IMPORT ERROR: $e");
      print(stacktrace);
      setError("CSV Bulk Import Error: ${e.toString()}");
      return false;
    }
  }

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

  void clearError() {
    setError(null);
  }

  void syncProductStockInMemory(ProductModel updatedProduct) {
    if (_allProducts != null) {
      final index = _allProducts!.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        _allProducts![index] = updatedProduct;
      }
    }

    if (_categoryProducts != null) {
      final index = _categoryProducts!.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        _categoryProducts![index] = updatedProduct;
      }
    }

    if (_searchProducts != null) {
      final index = _searchProducts!.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        _searchProducts![index] = updatedProduct;
      }
    }

    if (_lowStockProducts != null) {
      final index = _lowStockProducts!.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        if (updatedProduct.stock <= updatedProduct.threshold) {
          _lowStockProducts![index] = updatedProduct;
        } else {
          _lowStockProducts!.removeAt(index);
        }
      } else if (updatedProduct.stock <= updatedProduct.threshold) {
        _lowStockProducts!.add(updatedProduct);
      }
    }

    notifyListeners();
  }
}