// File: lib/viewmodel/sale_viewmodel.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../model/product_model.dart';
import '../model/sale_model.dart';
import '../repo/product_repo.dart';
import '../repo/sale_repo.dart';
import '../utils/colors.dart';

class SaleViewModel extends ChangeNotifier {
  final SaleRepo _saleRepo;
  final ProductRepo _productRepo;

  SaleViewModel({required SaleRepo saleRepo, required ProductRepo productRepo})
      : _saleRepo = saleRepo, _productRepo = productRepo;

  bool _loading = false;
  String? _error;
  List<SaleModel>? _sales;
  List<SaleModel>? _productSales;
  int _todaySales = 0;
  int _weeklySales = 0;
  int _monthlySales = 0;
  Map<String, int>? _topProducts;
  Map<String, int>? _bottomProducts;

  // --- ADVANCED TRANSACTION FILTERING STATE (US-25) ---
  DateTimeRange? _selectedDateRange;

  bool get loading => _loading;
  String? get error => _error;
  List<SaleModel>? get sales => _sales;
  List<SaleModel>? get productSales => _productSales;
  int get todaySales => _todaySales;
  int get weeklySales => _weeklySales;
  int get monthlySales => _monthlySales;
  Map<String, int>? get topProducts => _topProducts;
  Map<String, int>? get bottomProducts => _bottomProducts;

  // Getters for Advanced Transaction Filtering (US-25)
  DateTimeRange? get selectedDateRange => _selectedDateRange;

  /// Returns filtered sales if a date range is selected, otherwise returns all sales.
  List<SaleModel> get filteredSales {
    if (_sales == null) return [];
    if (_selectedDateRange == null) return _sales!;

    return _sales!.where((sale) {
      final DateTime saleDate = _parseTimestamp(sale.timestamp);
      // Normalized boundary comparison to match dates inclusively
      final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
      final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
      return saleDate.isAfter(start) && saleDate.isBefore(end);
    }).toList();
  }

  // --- GAMIFICATION GETTERS (Item 5) ---

  /// Calculates the consecutive days streak for active sales logs.
  int get currentDailyStreak {
    if (_sales == null || _sales!.isEmpty) return 0;

    // Map sales down to pure normalized distinct YYYY-MM-DD integers
    final sortedDates = _sales!
        .map((sale) {
      final dt = _parseTimestamp(sale.timestamp);
      return DateTime(dt.year, dt.month, dt.day);
    })
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort newest to oldest

    if (sortedDates.isEmpty) return 0;

    final today = DateTime.now();
    final DateTime normalizedToday = DateTime(today.year, today.month, today.day);
    final DateTime normalizedYesterday = normalizedToday.subtract(const Duration(days: 1));

    // If there's no sale today or yesterday, the current streak has broken/reset to 0.
    if (sortedDates.first != normalizedToday && sortedDates.first != normalizedYesterday) {
      return 0;
    }

    int consecutiveStreak = 1;
    for (int i = 0; i < sortedDates.length - 1; i++) {
      final difference = sortedDates[i].difference(sortedDates[i + 1]).inDays;
      if (difference == 1) {
        consecutiveStreak++;
      } else if (difference > 1) {
        break; // Streak chain snapped
      }
    }
    return consecutiveStreak;
  }

  /// Evaluates and assigns badges dynamically based on cumulative volume scale milestones.
  String get businessMilestoneBadge {
    final count = totalInvoiceCount;
    if (count >= 100) return "👑 Diamond Elite Merchant";
    if (count >= 50) return "⭐ Platinum Superstar Retailer";
    if (count >= 25) return "🥇 Gold Master Merchant";
    if (count >= 10) return "🥈 Silver Rising Retailer";
    if (count >= 1) return "🥉 Bronze Active Shop Starter";
    return "🌱 Fresh Business Onboarding";
  }

  int get totalRevenue {
    if (_sales == null || _sales!.isEmpty) return 0;
    return _sales!.fold(0, (sum, sale) => sum + sale.totalPrice);
  }

  int get totalItemsSold {
    if (_sales == null || _sales!.isEmpty) return 0;
    return _sales!.fold(0, (sum, sale) => sum + sale.quantity);
  }

  int get totalInvoiceCount => _sales?.length ?? 0;

  List<SaleModel> get pastTwoMonthsSales {
    if (_sales == null || _sales!.isEmpty) return [];
    final cutOffDate = DateTime.now().subtract(const Duration(days: 60));

    return _sales!.where((sale) {
      final DateTime saleDate = _parseTimestamp(sale.timestamp);
      return saleDate.isAfter(cutOffDate);
    }).toList()
      ..sort((a, b) => (b as dynamic).timestamp.toString().compareTo((a as dynamic).timestamp.toString()));
  }

  // --- FILTER MODIFICATION ROUTINES (US-25) ---

  /// Applies a specified date range to filter transaction listings.
  void setDateRangeFilter(DateTimeRange? range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  /// Clears active search parameters to bring transaction layouts back to baseline defaults.
  void clearDateRangeFilter() {
    _selectedDateRange = null;
    notifyListeners();
  }

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

  Future<void> clearAllSalesBatch() async {
    setLoading(true);
    try {
      if (_sales != null) {
        for (var sale in _sales!) {
          await _saleRepo.deleteSale(sale.id);
        }
      }
      _sales = [];
      await refreshDashboard();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> addMockSaleRecord({
    required double totalPrice,
    required DateTime timestamp,
    required String productName,
  }) async {
    try {
      // 🟢 Try to find existing product by name
      final products = await _productRepo.getAllProduct();
      ProductModel? existingProduct;
      try {
        existingProduct = products.firstWhere(
              (p) => p.name.toLowerCase() == productName.toLowerCase(),
        );
      } catch (_) {
        // Create a stub product with the NAME
        existingProduct = ProductModel(
          id: 'stub_${productName.replaceAll(' ', '_').toLowerCase()}',
          name: productName, // ✅ Store the NAME
          price: 100.0,
          stock: 50,
          threshold: 5,
          category: 'Mock',
        );
      }

      final SaleModel sale = SaleModel(
        id: 'mock_${timestamp.millisecondsSinceEpoch}',
        productId: existingProduct.id ?? 'unknown',
        productName: existingProduct.name, // ✅ Use the NAME
        quantity: 1,
        unitPrice: totalPrice.toInt(),
        totalPrice: totalPrice.toInt(),
        timestamp: timestamp,
        notes: 'Mock sales data for testing',
      );

      await _saleRepo.addSale(sale);
    } catch (e) {
      debugPrint('Error adding mock sale: $e');
    }
  }

  Future<bool> addSale(SaleModel sale) async {
    setError(null);

    bool localUpdated = false;
    if (_sales != null) {
      _sales!.insert(0, sale);
      localUpdated = true;
    }

    if (localUpdated) {
      notifyListeners();
    } else {
      setLoading(true);
    }

    try {
      await _saleRepo.addSale(sale);
      _sales = await _saleRepo.getAllSales();
      await refreshDashboard();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 🟢 Helper 1: Fix a single sale's product name
  Future<void> fixSaleProductName(String saleId, String correctProductName) async {
    try {
      // Get all sales
      final sales = await _saleRepo.getAllSales();

      // Find the sale by ID
      final sale = sales.firstWhere(
            (s) => s.id == saleId,
        orElse: () => throw Exception('Sale not found: $saleId'),
      );

      debugPrint("📝 Fixing sale: ${sale.productName} → $correctProductName");

      // Create updated sale with correct product name
      final updatedSale = SaleModel(
        id: sale.id,
        productId: sale.productId,
        productName: correctProductName, // ✅ Correct name
        quantity: sale.quantity,
        unitPrice: sale.unitPrice,
        totalPrice: sale.totalPrice,
        timestamp: sale.timestamp,
        notes: sale.notes,
      );

      // Update the sale in repository
      await _saleRepo.updateSale(updatedSale);

      // Refresh local list
      if (_sales != null) {
        final index = _sales!.indexWhere((s) => s.id == saleId);
        if (index != -1) {
          _sales![index] = updatedSale;
          notifyListeners();
        }
      }

      debugPrint("✅ Fixed sale: $saleId → $correctProductName");

    } catch (e) {
      debugPrint("❌ Error fixing sale product name: $e");
      rethrow;
    }
  }

  // 🟢 Helper 3: Check if a sale has incorrect product name
  bool isSaleProductNameIncorrect(SaleModel sale, List<ProductModel> products) {
    // Find the product by ID
    final product = products.firstWhere(
          (p) => p.id == sale.productId,
      orElse: () => ProductModel(
        id: sale.productId,
        name: sale.productName,
        price: sale.unitPrice.toDouble(),
        stock: 0,
        threshold: 0,
        category: '',
      ),
    );

    // Check if the product name looks like an ID
    final bool isIdLike = sale.productName.length > 15 &&
        !sale.productName.contains(' ') &&
        (sale.productName.contains('J7s') ||
            sale.productName.contains('Hqu') ||
            sale.productName.contains('G6t') ||
            sale.productName.contains('EvW') ||
            sale.productName.startsWith('prod_'));

    return isIdLike && product.name != sale.productName;
  }

  Future<dynamic> deleteSale(String id) async {
    setError(null);
    setLoading(true);

    try {
      SaleModel? sale;
      try {
        sale = _sales?.firstWhere((s) => s.id == id);
      } catch (_) {
        final allSalesTemp = await _saleRepo.getAllSales();
        sale = allSalesTemp.firstWhere((s) => s.id == id);
      }

      if (sale != null) {
        final product = await _productRepo.getProductById(sale.productId);

        if (product != null) {
          final updatedProduct = product.copyWith(
            stock: product.stock + sale.quantity,
          );
          await _productRepo.updateProduct(updatedProduct);
        }

        await _saleRepo.deleteSale(id);
        _sales?.removeWhere((s) => s.id == id);
        await refreshDashboard();

        return product;
      }
      return null;
    } on Exception catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> restoreSalesFromJson(List<dynamic> jsonList) async {
    _loading = true;
    notifyListeners();
    try {
      final restoredList = jsonList.map((e) => SaleModel.fromMap(e as Map<String, dynamic>)).toList();
      await _saleRepo.batchInsertSales(restoredList);
      _sales = restoredList;
      await refreshDashboard();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addHistoricalSaleWithProfile({
    required String productName,
    required int quantity,
    required DateTime date,
    required double fallbackPrice,
    required String category,
  }) async {
    try {
      // 🟢 Get all products to find matching name
      final products = await _productRepo.getAllProduct();

      // 🟢 Try to find existing product by name (case insensitive)
      ProductModel existingProduct;
      try {
        existingProduct = products.firstWhere(
              (p) => p.name.toLowerCase().trim() == productName.toLowerCase().trim(),
        );
      } catch (_) {
        // Product not found - create stub with the NAME
        existingProduct = ProductModel(
          id: 'stub_${productName.replaceAll(' ', '_').toLowerCase()}',
          name: productName, // ✅ Store the NAME
          price: fallbackPrice,
          stock: 0,
          threshold: 5,
          category: category,
        );
      }

      // 🟢 ALWAYS use the product NAME for display
      final SaleModel sale = SaleModel(
        id: 'csv_${DateTime.now().millisecondsSinceEpoch}_${existingProduct.id?.substring(0, 5) ?? 'unknown'}',
        productId: existingProduct.id ?? 'unknown',
        productName: existingProduct.name, // ✅ Use the NAME
        quantity: quantity,
        unitPrice: fallbackPrice.toInt(),
        totalPrice: (fallbackPrice * quantity).toInt(),
        timestamp: date,
        notes: 'Imported from CSV${existingProduct.id?.startsWith('stub_') == true ? ' (New Product)' : ''}',
      );

      await _saleRepo.addSale(sale);

      debugPrint("✅ Added historical sale: ${existingProduct.name} x$quantity @ ₹${fallbackPrice}");

    } catch (e) {
      debugPrint('❌ Error adding historical sale: $e');
      rethrow;
    }
  }

  void clearLocalCacheData() {
    _sales = []; // 🟢 Changes state from "Loading/Null" to "Explicitly Empty"
    notifyListeners();
  }

  Future<void> importDemoSalesCSV() async {
    setLoading(true);
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final String csvString = await file.readAsString();
        final List<String> lines = csvString.split('\n');
        int importedCount = 0;

        for (var i = 1; i < lines.length; i++) {
          final String line = lines[i].trim();
          if (line.isEmpty) continue;

          final List<String> row = line.split(',');
          if (row.length < 3) continue;

          try {
            DateTime saleDate;
            try {
              saleDate = DateTime.parse(row[0].trim());
            } catch (_) {
              saleDate = DateTime.now();
            }

            String parsedItemName = row[1].trim();
            double totalRowPrice = double.parse(row[row.length - 1].replaceAll(RegExp(r'[^\d.]'), '').trim());

            await addMockSaleRecord(
              totalPrice: totalRowPrice,
              timestamp: saleDate,
              productName: parsedItemName,
            );
            importedCount++;
          } catch (rowError) {
            debugPrint("Skipping malformed CSV row index $i: $rowError");
            continue;
          }
        }

        _sales = await _saleRepo.getAllSales();
        await refreshDashboard();

        Fluttertoast.showToast(
          msg: "Successfully imported $importedCount sales records!",
          backgroundColor: AppColor.success,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Import Error: Verify file text formatting standards.",
        backgroundColor: AppColor.error,
        textColor: Colors.white,
      );
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateSale(String id, int newQuantity) async {
    setError(null);

    if (_sales != null) {
      final index = _sales!.indexWhere((s) => s.id == id);
      if (index != -1) {
        final currentSale = _sales![index];
        _sales![index] = currentSale.copyWith(
          quantity: newQuantity,
          totalPrice: currentSale.unitPrice * newQuantity,
        );
        notifyListeners();
      }
    }

    try {
      final targetSales = _sales ?? await _saleRepo.getAllSales();
      final sale = targetSales.firstWhere((s) => s.id == id);
      final updatedSale = sale.copyWith(
        quantity: newQuantity,
        totalPrice: sale.unitPrice * newQuantity,
      );

      await _saleRepo.updateSale(updatedSale);
      _sales = await _saleRepo.getAllSales();
      await refreshDashboard();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

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

  // 🟢 FIXED: getTopProducts - Now uses product names instead of IDs
  Future<void> getTopProducts({int limit = 5}) async {
    setLoading(true);
    setError(null);
    try {
      // Get all sales and products
      final sales = await _saleRepo.getAllSales();
      final products = await _productRepo.getAllProduct();

      // Create a map of product ID to name
      final productNameMap = <String, String>{};
      for (var product in products) {
        productNameMap[product.id ?? ''] = product.name;
      }

      // Count sales by product name
      final Map<String, int> productCounts = {};
      for (var sale in sales) {
        // Use product name from map, or fallback to sale.productName
        final String productName = productNameMap[sale.productId] ?? sale.productName;

        // Skip "Unknown" or empty names
        if (productName.isEmpty || productName == 'Unknown' || productName == 'NOT_FOUND') continue;

        productCounts[productName] = (productCounts[productName] ?? 0) + sale.quantity;
      }

      // Sort and get top products
      final sorted = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _topProducts = Map.fromEntries(sorted.take(limit));
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // 🟢 FIXED: getBottomProducts - Now uses product names instead of IDs
  Future<void> getBottomProducts({int limit = 5}) async {
    setLoading(true);
    setError(null);
    try {
      // Get all sales and products
      final sales = await _saleRepo.getAllSales();
      final products = await _productRepo.getAllProduct();

      // Create a map of product ID to name
      final productNameMap = <String, String>{};
      for (var product in products) {
        productNameMap[product.id ?? ''] = product.name;
      }

      // Count sales by product name
      final Map<String, int> productCounts = {};
      for (var sale in sales) {
        // Use product name from map, or fallback to sale.productName
        final String productName = productNameMap[sale.productId] ?? sale.productName;

        // Skip "Unknown" or empty names
        if (productName.isEmpty || productName == 'Unknown' || productName == 'NOT_FOUND') continue;

        productCounts[productName] = (productCounts[productName] ?? 0) + sale.quantity;
      }

      // Sort and get bottom products (lowest quantity first)
      final sorted = productCounts.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      _bottomProducts = Map.fromEntries(sorted.take(limit));
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

  Future<void> refreshDashboard() async {
    try {
      await Future.wait([
        _saleRepo.getTodaySales().then((val) => _todaySales = val),
        _saleRepo.getWeeklySales().then((val) => _weeklySales = val),
        _saleRepo.getMonthlySales().then((val) => _monthlySales = val),
        getTopProducts(),
        getBottomProducts(),
        _saleRepo.getAllSales().then((val) => _sales = val),
      ]);
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    }
  }

  /// Internal timestamp standardizer supporting flexible source models
  DateTime _parseTimestamp(dynamic ts) {
    if (ts is DateTime) return ts;
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.parse(ts.toString());
  }
}