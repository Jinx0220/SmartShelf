import 'package:flutter/material.dart';
import '../model/product_model.dart';
import '../model/sale_model.dart';
import '../model/user_model.dart';
import '../repo/product_repo.dart';
import '../repo/sale_repo.dart';
import '../repo/auth_repo.dart';

class DashboardViewModel extends ChangeNotifier {
  final ProductRepo _productRepo;
  final SaleRepo _saleRepo;
  final AuthRepo _authRepo;

  DashboardViewModel({
    required ProductRepo productRepo,
    required SaleRepo saleRepo,
    required AuthRepo authRepo,
  }) : _productRepo = productRepo,
        _saleRepo = saleRepo,
        _authRepo = authRepo;

  bool _loading = false;
  String? _error;
  List<ProductModel> _products = [];
  List<SaleModel> _sales = [];
  UserModel? _user;
  int _todaySales = 0;
  int _weeklySales = 0;
  int _lowStockCount = 0;
  int _totalProducts = 0;
  List<ProductModel> _criticalProducts = [];
  Map<String, int> _topProducts = {};
  String _greeting = 'Good morning';

  // Getters
  bool get loading => _loading;
  String? get error => _error;
  List<ProductModel> get products => _products;
  List<SaleModel> get sales => _sales;
  UserModel? get user => _user;
  int get todaySales => _todaySales;
  int get weeklySales => _weeklySales;
  int get lowStockCount => _lowStockCount;
  int get totalProducts => _totalProducts;
  List<ProductModel> get criticalProducts => _criticalProducts;
  Map<String, int> get topProducts => _topProducts;
  String get greeting => _greeting;

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // 🔴 FIXED: Clear all cached data before reloading
  void _clearCachedData() {
    _todaySales = 0;
    _weeklySales = 0;
    _lowStockCount = 0;
    _totalProducts = 0;
    _criticalProducts = [];
    _topProducts = {};
    _products = [];
    _sales = [];
    _user = null;
    notifyListeners();
  }

  // 🔴 FIXED: Load dashboard data with proper cache clearing
  Future<void> loadDashboardData() async {
    setLoading(true);
    setError(null);
    try {
      debugPrint("📊 [DASHBOARD DEBUG] Starting loadDashboardData...");

      // 🔴 FIX 1: Clear all cached data first
      _clearCachedData();

      // 1. Parallel execution to pull clean snapshots from the cloud
      await Future.wait([
        _loadProducts(),
        _loadSales(),
        _loadUser(),
      ]);

      debugPrint("📊 [DASHBOARD DEBUG] Raw Products Loaded Count: ${_products.length}");
      debugPrint("📊 [DASHBOARD DEBUG] Raw Sales Loaded Count: ${_sales.length}");

      // 2. Force calculations after data is loaded
      _calculateGreeting();
      _calculateTodaySales();
      _calculateWeeklySales();
      _calculateLowStockCount();
      _calculateCriticalProducts();
      _calculateTotalProducts();

      // 3. Calculate top products (async - handled separately)
      await _calculateTopProducts();

      debugPrint("📊 [DASHBOARD DEBUG] Calculated Today Sales: $_todaySales NPR");
      debugPrint("📊 [DASHBOARD DEBUG] Calculated Weekly Sales: $_weeklySales NPR");
      debugPrint("📊 [DASHBOARD DEBUG] Low Stock Count: $_lowStockCount");

      notifyListeners();
    } on Exception catch (e) {
      debugPrint("💥 [DASHBOARD DEBUG] Exception: $e");
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // 🔴 FIXED: Force reset dashboard to zero (for deletion scenarios)
  Future<void> resetDashboardData() async {
    debugPrint("🔄 [DASHBOARD] Resetting all dashboard data to zero...");

    // Clear local cache
    _clearCachedData();

    // Also clear repositories if needed
    try {
      // If you have delete methods in repos, call them here
      // await _productRepo.deleteAllProducts();
      // await _saleRepo.deleteAllSales();
    } catch (e) {
      debugPrint("Error clearing repository data: $e");
    }

    notifyListeners();
    debugPrint("✅ [DASHBOARD] Dashboard reset complete");
  }

  // 🔴 FIXED: Force refresh after data deletion
  Future<void> refreshAfterDeletion() async {
    debugPrint("🔄 [DASHBOARD] Refreshing after data deletion...");

    // Reset to zero first
    _todaySales = 0;
    _weeklySales = 0;
    _lowStockCount = 0;
    _totalProducts = 0;
    _criticalProducts = [];
    _topProducts = {};
    notifyListeners();

    // Then reload actual data from sources
    await loadDashboardData();
    debugPrint("✅ [DASHBOARD] Refresh after deletion complete");
  }

  // Load products
  Future<void> _loadProducts() async {
    try {
      final result = await _productRepo.getAllProduct();
      _products = result ?? [];
      debugPrint("📦 [DASHBOARD] Products loaded: ${_products.length}");
    } catch (e) {
      debugPrint("❌ [DASHBOARD] Error loading products: $e");
      _products = [];
    }
  }

  // Load sales
  Future<void> _loadSales() async {
    try {
      final result = await _saleRepo.getAllSales();
      _sales = result ?? [];
      debugPrint("📊 [DASHBOARD] Sales loaded: ${_sales.length}");
    } catch (e) {
      debugPrint("❌ [DASHBOARD] Error loading sales: $e");
      _sales = [];
    }
  }

  // Load user
  Future<void> _loadUser() async {
    try {
      _user = await _authRepo.getUserProfile('current');
      debugPrint("👤 [DASHBOARD] User loaded: ${_user?.storeName ?? 'None'}");
    } catch (e) {
      debugPrint("❌ [DASHBOARD] Error loading user: $e");
      _user = null;
    }
  }

  // Calculate greeting
  void _calculateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
    }
  }

  // 🔴 FIXED: Calculate today's sales with proper date filtering
  void _calculateTodaySales() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Only count sales from today
    _todaySales = _sales.where((s) {
      final saleDate = s.timestamp;
      return saleDate.isAfter(todayStart) && saleDate.isBefore(todayEnd);
    }).fold(0, (sum, s) => sum + s.totalPrice);
  }

  // 🔴 FIXED: Calculate weekly sales with proper date filtering
  void _calculateWeeklySales() {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final weekAgo = todayEnd.subtract(const Duration(days: 7));

    // Only count sales from the last 7 days
    _weeklySales = _sales
        .where((s) => s.timestamp.isAfter(weekAgo))
        .fold(0, (sum, s) => sum + s.totalPrice);
  }

  // Calculate low stock count
  void _calculateLowStockCount() {
    _lowStockCount = _products.where((p) => p.isLowStock).length;
  }

  // Calculate critical products
  void _calculateCriticalProducts() {
    _criticalProducts = _products
        .where((p) => p.isLowStock)
        .toList()
      ..sort((a, b) => (a.stock ?? 0).compareTo(b.stock ?? 0));
  }

  // 🔴 FIXED: Calculate top products with proper error handling
  Future<void> _calculateTopProducts() async {
    try {
      final result = await _saleRepo.getTopProducts(limit: 5);
      _topProducts = result ?? {};
      debugPrint("🏆 [DASHBOARD] Top products: ${_topProducts.length}");
    } catch (e) {
      debugPrint("❌ [DASHBOARD] Error calculating top products: $e");
      _topProducts = {};
    }
    // Don't notify here - will be notified in loadDashboardData
  }

  // Calculate total products
  void _calculateTotalProducts() {
    _totalProducts = _products.length;
  }

  // Refresh dashboard Hook
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  // Get total sales (all time)
  int getTotalSales() {
    return _sales.fold(0, (sum, sale) => sum + sale.totalPrice);
  }

  // Get sales count (total)
  int getTotalSalesCount() {
    return _sales.length;
  }

  // Get total products count
  int getTotalProductsCount() {
    return _products.length;
  }

  // Get out of stock count
  int getOutOfStockCount() {
    return _products.where((p) => p.isOutOfStock).length;
  }

  // Get formatted date for display
  String getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // Get store name
  String getStoreName() {
    return _user?.storeName ?? 'My Store';
  }

  // Get user name
  String getUserName() {
    return _user?.fullName ?? 'User';
  }

  // Check if dashboard is ready
  bool isDashboardReady() {
    return !_loading;
  }

  // Get percentage change
  double getPercentageChange(int current, int previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous * 100);
  }

  // Get today's date range
  String getTodayDateRange() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  // Get week range
  String getWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}';
  }

  // Top products list with names
  List<DashboardTopProduct> getTopProductsList() {
    final productMap = <String, String>{};
    for (var product in _products) {
      if (product.id != null) {
        productMap[product.id!] = product.name;
      }
    }

    final List<DashboardTopProduct> result = [];
    int rank = 1;
    for (var entry in _topProducts.entries) {
      result.add(DashboardTopProduct(
        name: productMap[entry.key] ?? 'Unknown',
        quantity: entry.value,
        rank: rank,
      ));
      rank++;
    }
    return result;
  }

  // Critical products with details
  List<DashboardCriticalProduct> getCriticalProductsList() {
    return _criticalProducts.map((product) {
      return DashboardCriticalProduct(
        name: product.name,
        stock: product.stock,
        threshold: product.threshold,
        productId: product.id ?? '',
      );
    }).toList();
  }
}

// Structural helper classes for widget injection
class DashboardTopProduct {
  final String name;
  final int quantity;
  final int rank;
  DashboardTopProduct({
    required this.name,
    required this.quantity,
    required this.rank,
  });
}

class DashboardCriticalProduct {
  final String name;
  final int stock;
  final int threshold;
  final String productId;
  DashboardCriticalProduct({
    required this.name,
    required this.stock,
    required this.threshold,
    required this.productId,
  });
}